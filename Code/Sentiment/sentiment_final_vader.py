import os
import json
import pandas as pd
#from nltk.corpus import stopwords
import re
from nltk.stem import WordNetLemmatizer
import nltk
nltk.download('vader_lexicon')
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer 

os.chdir(r"C:\Users\simon\OneDrive - UT Cloud\Twitter_Data_Simon\NoFilter")

# create empty csv to store sentiment per day
df = pd.DataFrame(list())
df.to_csv("NoFilter_sentiment.csv")

## functions to clean 
def remove_light(text):
    reference_pattern = re.compile(r"\@\w+|\@\w+\'|\@\w+\’|<.*?>|https?://\S+|www\.\S+|\d+\.|\d+|\#|\&amp|RT")
    return reference_pattern.sub(r'', text)
    
def remove_repeats(text):
    rep_pattern = re.compile(r'(.)\1{2,}') 
    return rep_pattern.sub(r'\1\1', text) 
 
## function for sentiment   
sid_obj = SentimentIntensityAnalyzer() 

def get_sentiment(text):
    sentiment = pd.DataFrame([sid_obj.polarity_scores(text)])
    return sentiment["compound"]

# dates     
date_list = pd.date_range(start="2019-08-01",end="2020-03-01")
date_list = date_list.to_series().dt.date
  
     
for date in date_list:
    
    tweets = []
    path =  f"En_NoFilter_{date}.json"
    
    #load json file
    for line in open(path, 'r',encoding="utf8"):
        tweets.append(json.loads(line))
    
    df = pd.DataFrame(tweets)
    df["tweet_clean"] = df["tweet"].copy()
    tweet = df[["date","tweet", "tweet_clean"]]
            
    #cleaning
    tweet["tweet_clean"] = tweet["tweet"].apply(lambda tweet: remove_light(tweet))
    tweet["tweet_clean"] = tweet["tweet_clean"].apply(lambda tweet_clean: remove_repeats(tweet_clean))
    
    #sentiment
    tweet["sentiment"] = tweet["tweet_clean"].apply(lambda tweet_clean: get_sentiment(tweet_clean))
    
    #aggregate of the day
    aggregate_sentiment = tweet["sentiment"].mean()
    
    final = pd.DataFrame([{'date':tweet["date"].iloc[1],'sentiment':aggregate_sentiment}])
    final.to_csv('NoFilter_sentiment.csv',mode='a', header=False, index=False)




#test = pd.read_csv('NoFilter_sentiment.csv',header=None)
