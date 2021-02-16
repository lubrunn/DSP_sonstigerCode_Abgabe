import os
import re

os.chdir(r"C:\Users\simon\Documents\GitHub\DSP_Sentiment_Covid\Code\Sentiment\Shiny_code")

import pandas as pd
import pyarrow.feather as feather
import numpy as np
from filter_aggregation import filter_aggregation
# path to big file
path_1 = r"C:\Users\simon\Desktop\WS_20_21\DS_12\Sentiment\tweets_en_En_NoFilter.csv"

#load big file
df = pd.read_csv(path_1)

df = df.reset_index()

df = df.rename(columns={"level_0":"id","level_1":"date",
                         "level_2":"retweets_count","level_3":"likes_count","level_4":"tweet_length",
                         "Unnamed: 0":"sentiment"})

#drop duplicates
df = df.drop_duplicates(subset=['id'])

#median tweet length
median_len = np.median(df.tweet_length)

filt_likes = np.arange(0,10).tolist()
long_tweet = list(["yes","no"])


range_list = np.arange(10,30,10).tolist()

for i in range_list:
    filt_retweet = np.arange(i-10,i).tolist()
    for filt_len in long_tweet: 
        for filt_ret in filt_retweet:
            for filt_lik in filt_likes:
                filter_aggregation(df,"En",filt_len,filt_ret,filt_lik,median_len,i)
                

#load in whole csv to store as feather