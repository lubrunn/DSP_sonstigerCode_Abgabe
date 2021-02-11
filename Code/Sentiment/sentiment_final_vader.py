def sentiment_over_time(retweet,lan,date_range_input,path_raw,subfolder):
    
    import pyarrow.feather as feather  
    import numpy as np
    import json
    import pandas as pd
    import re
    import nltk
    nltk.download('vader_lexicon')
    from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer 
        
        
    
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
        else:
                   path = f'{path_raw}\\{subfolder}_{date}_{lan}.json'
                   
         
        #load json file
        for line in open(path, 'r',encoding="utf8"):
            tweets.append(json.loads(line))
           
        # create dataframe from list
        df = pd.DataFrame(tweets)
        
        # drop duplicate tweets
        df = df.drop_duplicates(subset=['id'])
        
        # create copy of the tweet column for comparison
        df["tweet_clean"] = df["tweet"].copy()
        
        # subset dataframe for columns of interest
        tweet = df[["date","tweet", "tweet_clean","replies_count","retweets_count",
                       "likes_count","retweet"]]
           
        # call the cleaning functions
        tweet["tweet_clean"] = tweet["tweet"].apply(lambda tweet: remove_light(tweet))
        tweet["tweet_clean"] = tweet["tweet_clean"].apply(lambda tweet_clean: remove_repeats(tweet_clean))
           
           
        # get the length of each tweet for calculation 
        # use vectorize function of numpy 
        length_checker = np.vectorize(len)
        # get length of each tweet
        tweet["tweet_length"] = length_checker(tweet["tweet_clean"])
           
        print("Calculate sentiment for day", date,"with language",
                 lan,"and retweet count of",retweet)
           
        # calculate the sentiment for each tweet by calling the function 'get_sentiment()'
        tweet["sentiment"] = tweet["tweet_clean"].apply(lambda tweet_clean: get_sentiment(tweet_clean))
           
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
        final = pd.DataFrame([{'language':lan,
                              'retweet_count':retweet,
                              'date':tweet["date"].iloc[1],
                              'company':subfolder,
                              'sentiment_mean':mean_sentiment,
                              'sentiment_weight_retweet':mean_sentiment_by_retweet,
                              'sentiment_weight_length':mean_sentiment_by_length,
                              'sentiment_weight_likes':mean_sentiment_by_likes}])
        

        # append one row dataframe to csv to save memory
        final.to_csv(r"C:\Users\simon\Desktop\WS_20_21\DS_12\test.csv",mode = "a", 
                     index=False,header= False)

        
