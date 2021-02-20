import os
import re

os.chdir(r"C:\Users\simon\Documents\GitHub\DSP_Sentiment_Covid\Code\Sentiment\Shiny_code")

import pandas as pd
from get_date import date_finder
from id_finder import id_finder
from tweet_collector import tweet_collector
import pyarrow.feather as feather
import numpy as np
import json
               
#C:\Users\simon\OneDrive - UT Cloud\Eigene Dateien\Data\Twitter\sentiment\Shiny_files_companies

# path to company and non-specific tweets
path_1 = r"C:\Users\simon\OneDrive - UT Cloud\Eigene Dateien\Data\Twitter\raw"


# all folders 
folders = os.listdir(path_1)

# folders for nofilter scraping
nofilter_folders = [k for k in folders if "NoFilter" in k]
nofilter_folders = [k for k in nofilter_folders if "En" in k]


# loop through the all folders in given path   
for folder in folders:
        
    # differentiate between NoFilter and company folders                
    # the follwing structure is for the NoFilter folers    
    if folder in nofilter_folders:   
            
            # create a list of json files within the selected folder 
            json_files = os.listdir(os.path.join(path_1,folder))
            
            # get date range of json files
            date_range_input = date_finder(json_files)
            date_list = date_range_input.to_series().dt.date
            
            # create path to selected folder
            file = os.path.join(path_1,folder)
            
            # get number of retweets from folder name
            retweets = re.findall(r'\d+', folder)
            retweets = str(retweets).strip("'[]'")
                        
            # account for if Folder has no retweet count in its name    
            if len(retweets) == 0:
                retweets = 0
                        
            # call sentiment function
            id_finder(int(retweets),"En",date_range_input,file,date_list)           
          








# read in the csv file which was created by the sentiment function  
df_final = pd.read_csv(r"C:\Users\simon\Desktop\WS_20_21\DS_12\test.csv")

# reset index
df_final = df_final.reset_index()

# rename columns
df_final = df_final.rename(columns={"level_0":"language","level_1":"retweet_count",
                         "level_2":"date","level_3":"company","level_4":"sentiment_mean",
                         "level_5":"sentiment_weight_retweet","level_6":"sentiment_weight_length",
                         "Unnamed: 0":"sentiment_weight_likes"})

# write the dataframe as complete feather file
# (feather files do not allow to append data)

feather.write_feather(df_final, r"C:\Users\simon\Desktop\WS_20_21\DS_12\test_feather")   

