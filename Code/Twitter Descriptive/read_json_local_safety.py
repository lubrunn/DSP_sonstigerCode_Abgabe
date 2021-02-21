# -*- coding: utf-8 -*-
"""
Created on Sun Feb 21 20:23:39 2021

@author: lukas
"""


import os
os.chdir(r"C:\Users\lukas\OneDrive - UT Cloud\Data\twitter")
import json
import pandas as pd
import re
import numpy as np
from datetime import datetime
import swifter
#import pyarrow

import demoji
#demoji.download_codes()

#%%
        
def df_cleaner(df, lang_controller = False):        
    # drop duplicate tweets
    df = df.drop_duplicates(subset=["id"], keep='first')
    
    if lang_controller == True:
        # only keep tweets with correct language
        df = df[df["language"] == lang.lower()]
    else:
        df = df[df["language"].isin(["en", "de"])]
    # split coordingates column into lat/long
    if ~sum(df["place"] == "") == len(df):
        coord = df["place"].apply(pd.Series)["coordinates"].swifter.progress_bar(False).apply(pd.Series)
        coord.rename(columns = {0:"lat", 1:"long"},
             inplace = True)
        df = pd.concat([df, coord], axis = 1)
    
    else:
        df["lat"] = df["long"] = None
        df.drop("place", axis = 1, inplace = True)
                
            
    # only select needed columns
    df = df[["id", "tweet", "created_at", "user_id", 
             "username", "hashtags", "lat", "long", 
             "language", "replies_count", "retweets_count", 
             "likes_count"]]
    
    df.reset_index(inplace = True, drop = True)
    
    # remove links and handles
    df["tweet"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: remove_light(tweet))
    # strip extra whitespace
    df["tweet"] = df["tweet"].str.strip()
    df["tweet"] = df["tweet"].replace('\s+', ' ', regex=True)
    
    
    # compute length of tweets
    length_checker = np.vectorize(len)
    # get length of each tweet
    df["tweet_length"] = length_checker(df["tweet"])
    
    # convert tweet_length to object
    df["tweet_length"] = df["tweet_length"]
    
    # drop any missing tweets
    df = df.dropna(subset=["tweet"])
    return df


#%% cleaning functions
def remove_light(text):
        reference_pattern = re.compile(r"\@\w+|\@\w+\'|\@\w+\’|<.*?>|https?://\S+|www\.\S+|\d+\.|\d+|\#|\&amp|RT")
        return reference_pattern.sub(r'', text)


#%% get folder names
source = "raw_test"
dest = "raw_csv"
dest_cleaned = "pre_cleaned"
folders_all = [k for k in os.listdir(source) if "Comp" in k or "Filter" in k]

company_folders = ["Companies_en", "Companies_de"]
nofilter_folders = [k for k in folders_all if "Filter" in k]

# get all company folders without en/de
subfolders = [k.split("_")[0] for k in  os.listdir(os.path.join(source, "Companies_en"))]




#%% testing
folder = nofilter_folders[0]
file = files[0]
folder = company_folders[0]
subfolder = subfolders[0]

#%%

# list all subfolders

for subfolder in subfolders:
    print(f"Working on {subfolder}")
    new_dest = os.path.join(dest,"Companies", subfolder)
    new_dest_cleaned = os.path.join(dest_cleaned,"Companies", subfolder)
    
    # create folder in new destination if it does not already exist
    if not os.path.exists(new_dest):
        os.mkdir(os.path.join(new_dest))
    if not os.path.exists(new_dest_cleaned):
        os.mkdir(os.path.join(new_dest_cleaned))
    
    # now go into each company folder in the source an concat files from same day together
    # for this need to check if files exist in both and control for it
    files_de = os.listdir(os.path.join(source, "Companies_de", f"{subfolder}_de"))
    files_en = os.listdir(os.path.join(source, f"Companies_en", f"{subfolder}_en"))
    

    # get the dates available in both datasets
    dates_de = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files_de]
    dates_en = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files_en]
    dates_both = list(set(dates_de) & set(dates_en))
    
    # now for each date available in both got thru both folders and concat files, then clean and save them
    for date in dates_both:
        # go into englisch folder
        tweets = []
        for folder in company_folders:
            file = f"{subfolder}_{date}_{folder.split('_')[1]}.json"
            path = os.path.join(source,folder,f"{subfolder}_{folder.split('_')[1]}", file)
            for line in open(path, 'r',encoding="utf8"):
                tweets.append(json.loads(line,parse_int=str))
        
        # convert to df
        df = pd.DataFrame(tweets)
        
        # clean df
        df = df_cleaner(df)
        
        # save df
        new_filename_csv = f"{subfolder}_{date}.csv"
        
        # save df
        print("Saving data in both")
        df.to_csv(os.path.join(new_dest ,new_filename_csv),
                  index = False)
        
        
        ###########
        # now replace emojis and save in different destination
        ###########
        df["tweet"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: demoji.replace_with_desc(tweet, 
                                                                                           sep = " "))# replace _ from emojis with " "
        df.tweet = df.tweet.str.replace("_", " ")
        #save df
        df.to_csv(os.path.join(new_dest_cleaned,new_filename_csv),
                  index = False)
    
    
    # now continue for dates not in both
    dates_de_only = list(set(dates_de) - set(dates_en))
    
    
    # only clean german files
    for date in dates_de_only:
        tweets = []
        file = f"{subfolder}_{date}_de.json"
        path = os.path.join(source,"Companies_de",f"{subfolder}_de", file)
        for line in open(path, 'r',encoding="utf8"):
            tweets.append(json.loads(line,parse_int=str))
            
         # convert to df
        df = pd.DataFrame(tweets)
        
        # clean df
        df = df_cleaner(df)
        
        # save df
        new_filename_csv = f"{subfolder}_{date}.csv"
        
        # save df
        print("Saving german data")
        df.to_csv(os.path.join(new_dest ,new_filename_csv),
                  index = False)
        
        ###########
        # now replace emojis and save in different destination
        ###########
        df["tweet"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: demoji.replace_with_desc(tweet, 
                                                                                           sep = " "))# replace _ from emojis with " "
        df.tweet = df.tweet.str.replace("_", " ")
        #save df
        df.to_csv(os.path.join(new_dest_cleaned,new_filename_csv),
                  index = False)
    
    # same for englisch only
     # now continue for dates not in both
    dates_en_only = list(set(dates_en) - set(dates_de))
    
    
    # only clean german files
    for date in dates_en_only:
        tweets = []
        file = f"{subfolder}_{date}_en.json"
        path = os.path.join(source,"Companies_en",f"{subfolder}_en", file)
        for line in open(path, 'r',encoding="utf8"):
            tweets.append(json.loads(line,parse_int=str))
            
         # convert to df
        df = pd.DataFrame(tweets)
        
        # clean df
        df = df_cleaner(df)
        
        # save df
        new_filename_csv = f"{subfolder}_{date}.csv"
        
        # save df
        print("Saving english data")
        df.to_csv(os.path.join(new_dest ,new_filename_csv),
                  index = False)  
    
        ###########
        # now replace emojis and save in different destination
        ###########
        df["tweet"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: demoji.replace_with_desc(tweet, 
                                                                                           sep = " "))# replace _ from emojis with " "
        df.tweet = df.tweet.str.replace("_", " ")
        #save df
        df.to_csv(os.path.join(new_dest_cleaned,new_filename_csv),
                  index = False)
        
    
    
        
            
    
    


    
        
    
            


#%%  process for all NoFilter folders
# for nofilter folders concat all tweets from one day together

# store language folders seperately
en_folders = [k for k in nofilter_folders if "En" in k]
de_folders = [k for k in nofilter_folders if "De" in k]
lang_folders = ["En", "De"]


# first get all dates needed
# for this get files from one folder, have same dates available
files = os.listdir(os.path.join(source, en_folders[0]))
# list of all dates we have data
dates = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files]
         
# convert to dates
dates_list = [datetime.strptime(date, "%Y-%m-%d").date() for date in np.array(dates)]

# find last date
last_update = max(dates_list)
first_update = min(dates_list)


date_list_needed = pd.date_range(start=first_update,end=last_update).strftime('%Y-%m-%d').to_list()

#%% process for nofilter folders
# for each date go into all folders concat the dfs, clean them and store them inside new folder

for lang in lang_folders:
    if lang == "De":
        folders = de_folders
    else:
        folders = en_folders
    
        
    # go thru all dates
    for date in date_list_needed:
        
        # set up list
        tweets = []
        #go into each folder folders an concat tweets to df
        for folder in folders:
            print(f"Working in {date} {folder}")
            # create filename from fodler name together wit date
            filename = f"{folder}_{date}.json"
            # create path
            path1 = os.path.join(source, folder, filename)
            
            # load json files
            for line in open(path1, 'r',encoding="utf8"):
                tweets.append(json.loads(line,parse_int=str))
        
        # convert to df
        df = pd.DataFrame(tweets)
        
        # clean dataframe
        print("Cleaning df")
        df = df_cleaner(df, lang_controller = True)
        
        
        
        new_filename = f"{lang}_NoFilter_{date}.feather"
        new_filename_csv = f"{lang}_NoFilter_{date}.csv"
        
        # save df
        print("Saving data")
        df.to_csv(os.path.join(dest, f"{lang}_NoFilter",new_filename_csv),
                  index = False)
        
        
        # now replace emojis and save in different destination
        df["tweet"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: demoji.replace_with_desc(tweet, 
                                                                                           sep = " "))
        
        # replace _ from emojis with " "
        df.tweet = df.tweet.str.replace("_", " ")
        
        #save df
        df.to_csv(os.path.join(dest_cleaned, f"{lang}_NoFilter",new_filename_csv),
                  index = False)