def sentiment_over_time(retweet,lan,date_range_input,path_raw,long_tweet,filt_retweet,filt_likes):
     
    import re
    import pandas as pd
    import json
    import numpy as np
    import nltk
    nltk.download('vader_lexicon')
    from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
    import swifter   # optimize apply function (similar performance to vectorized ops.)
       
    # remove basic signs, which distort sentiment
    def remove_light(text):
           reference_pattern = re.compile(r"\@\w+|\@\w+\'|\@\w+\’|<.*?>|https?://\S+|www\.\S+|\d+\.|\d+|\#|\&amp|RT")
           return reference_pattern.sub(r'', text)
    
    # remove repeats        
    def remove_repeats(text):
           rep_pattern = re.compile(r'(.)\1{2,}') 
           return rep_pattern.sub(r'\1\1', text) 
         
    # initialize the object to get sentiment   
    sid_obj = SentimentIntensityAnalyzer()
    
    # wrap this object in a function
    # returns the weighted sentiment for the complete tweet    
    def get_sentiment(text):
           sentiment = pd.DataFrame([sid_obj.polarity_scores(text)])
           return sentiment["compound"]
        
    # transform the 'DatetimeIndex' structure to a list for looping     
    date_list = date_range_input.to_series().dt.date
          
    # loop over the dates to grap the json files        
    for date in date_list:
        
        # initilalize tweets list
        tweets = []
        
        # account for different structure of json files
        
        if "NoFilter" in path_raw:
               # account for different structure of json files within NoFilter folder
               if retweet == 0:
                   path =  f"{path_raw}\\{lan}_NoFilter_{date}.json"
               else:
                   path = f'{path_raw}\\{lan}_NoFilter_min_retweets_{retweet}_{date}.json'
        
        # strucutre for the company folder
     #   else:
     #              path = f'{path_raw}\\{subfolder}_{date}_{lan}.json'
                   
        path = f"C:\\Users\\simon\\Desktop\\WS_20_21\\DS_12\\Sentiment\\test\\En_NoFilter_min_retweets_200_2018-11-30.json"
        
        #load json file
        for line in open(path, 'r',encoding="utf8"):
            tweets.append(json.loads(line))
           
        
        # create dataframe from list
        df = pd.DataFrame(tweets)
        
        if len(df) == 0:
            continue
        
        # subset dataframe for columns of interest
        tweet = df[["id","date","tweet","retweets_count",
                       "likes_count"]]
        
        del df
        
        # drop duplicates
        # load list of IDs which have a duplicte
        
        
                   
        # call the cleaning functions
        tweet["tweet"] = tweet["tweet"].swifter.apply(lambda tweet: remove_light(tweet))
        tweet["tweet"] = tweet["tweet"].swifter.apply(lambda tweet_clean: remove_repeats(tweet_clean))
           
           
        # get the length of each tweet for calculation 
        # use vectorize function of numpy 
        length_checker = np.vectorize(len)
        # get length of each tweet
        tweet["tweet_length"] = length_checker(tweet["tweet"])   

        # filter methods
       # filt_retweet = 
        tweet = tweet.loc[tweet.retweets_count > filt_retweet]
        
        tweet = tweet.loc[tweet.likes_count > filt_likes]
        
        if long_tweet = "yes": 
            tweet = tweet.loc[tweet.tweet_length > np.median(tweet.tweet_length)]

        
        # calculate the sentiment for each tweet by calling the function 'get_sentiment()'
        tweet["sentiment"] = tweet["tweet"].swifter.apply(lambda tweet_clean: get_sentiment(tweet_clean))
           
        # weight the sentiments by their number of retweets  
        mean_sentiment_by_retweet = np.ma.average(tweet['sentiment'], 
                                              weights = tweet['retweets_count']) 
        
        # account for tweets with 0 retweets -> just mean
        if mean_sentiment_by_retweet == "nan":
           mean_sentiment_by_retweet =  tweet["sentiment"].mean()
           
        # weight the sentiments by their length
        mean_sentiment_by_length = np.average(tweet['sentiment'], 
                                              weights = tweet['tweet_length'])           
        
        # weight the sentiments by their number of likes  
        mean_sentiment_by_likes = np.ma.average(tweet['sentiment'], 
                                              weights = tweet['likes_count'])
        
        # account for tweets with 0 retweets -> just mean
        if mean_sentiment_by_likes == "nan":
           mean_sentiment_by_likes =  tweet["sentiment"].mean()

        # just mean
        mean_sentiment = tweet["sentiment"].mean()
            
        
        
        
        
        
        
        
        
        # store all vectors in dataframe
        final = pd.DataFrame([{'id':tweet["id"],
                              'date':tweet["date"].iloc[1],
                              'sentiment_mean':mean_sentiment,
                              'sentiment_weight_retweet':mean_sentiment_by_retweet,
                              'sentiment_weight_length':mean_sentiment_by_length,
                              'sentiment_weight_likes':mean_sentiment_by_likes}])
        
        
        
        
        feather.write_feather(df_final, r"C:\Users\simon\Desktop\WS_20_21\DS_12\test_feather.feather") 

        # append one row dataframe to csv to save memory
        final.to_csv(r"C:\Users\simon\Desktop\WS_20_21\DS_12\test.csv",mode = "a", 
                     index=False,header= False)

        
