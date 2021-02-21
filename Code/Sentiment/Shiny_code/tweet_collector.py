def tweet_collector(retweet,lan,date_range_input,path_raw,date_list,folder,subfolder):
   
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
        
       for date in date_list:
           
            if "NoFilter" in path_raw:
               # account for different structure of json files within NoFilter folder
               if retweet == 0:
                   path =  f"{path_raw}/{lan}_NoFilter_{date}.json"
               else:
                   path = f'{path_raw}/{lan}_NoFilter_min_retweets_{retweet}_{date}.json'
            else:
                   subfolder_short = subfolder.split("_")[0]
                   path = f'{path_raw}\\{subfolder_short}_{date}_{lan}.json'
                   
        # initilalize tweets list
            tweets = []
            
            try:
                    for line in open(path, 'r',encoding="utf8"):
                        tweets.append(json.loads(line,parse_int=str))      
            except OSError:
                continue
            
            for line in open(path, 'r',encoding="utf8"):
                tweets.append(json.loads(line,parse_int=str))
            
            df = pd.DataFrame(tweets)
            
            if len(df) == 0:
                continue
            
            tweet = df[["id","date","tweet","retweets_count",
                       "likes_count","user_id"]]
            
                    # call the cleaning functions
            tweet["tweet"] = tweet["tweet"].swifter.progress_bar(False).apply(lambda tweet: remove_light(tweet))
            tweet["tweet"] = tweet["tweet"].swifter.progress_bar(False).apply(lambda tweet: remove_repeats(tweet))
            
            # get the length of each tweet for calculation 
            # use vectorize function of numpy 
            length_checker = np.vectorize(len)
            # get length of each tweet
            tweet["tweet_length"] = length_checker(tweet["tweet"])
            
            tweet["sentiment"] = tweet["tweet"].swifter.progress_bar(False).apply(lambda tweet: get_sentiment(tweet))

            tweet = tweet.drop(['tweet'], axis=1)
            
            tweet.to_csv(f"C:\\Users\\simon\\OneDrive - UT Cloud\\Eigene Dateien\\Data\\Twitter\\sentiment\\Shiny_files_companies\\tweets_{subfolder}.csv",mode = "a", 
                         index=False,header= False)
            
            print(date)
            