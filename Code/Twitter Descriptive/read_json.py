# vpc or local?
vpc = False
#%% set path were all the data is
if vpc == True:
    working_dir = "/home/lukasbrunner/share/onedrive_new/Data/Twitter"
else:
    working_dir = r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter"
    
import os
os.chdir(working_dir)
import json
import pandas as pd
import re
import numpy as np
from datetime import datetime
import swifter
#import pyarrow
import time

import demoji
#demoji.download_codes()


#%%
df = pd.read_csv("")
 tweets = []
for folder in company_folders:
    file = f"{subfolder}_{date}_{folder.split('_')[1]}.json"
    path = os.path.join(source,folder,f"{subfolder}_{folder.split('_')[1]}", file)
    for line in open(raw/En_NoFilter/En_NoFilter/En_NoFilter-2018-11-30.json, 'r',encoding="utf8"):
        tweets.append(json.loads(line,parse_int=str))

# convert to df
df = pd.DataFrame(tweets)
#%%
        
def df_cleaner(df, lang_controller = False):        
    # drop duplicate tweets
    df = df.drop_duplicates(subset=["id"], keep='first')
    
    if lang_controller == True:
        # only keep tweets with correct language
        df = df[df["language"] == lang.lower()]
    else:
        df = df[df["language"].isin(["en", "de"])]
    # split coordinates column into lat/long
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
    # control for tweet df with size 0
    if len(df) > 0:
        df["tweet_length"] = length_checker(df["tweet"])
    
        
    
    
    
    # drop any missing tweets
    df = df.dropna(subset=["tweet"])
    return df


#%% cleaning functions
def remove_light(text):
        reference_pattern = re.compile(r"\@\w+|\@\w+\'|\@\w+\’|<.*?>|https?://\S+|www\.\S+|\d+\.|\d+|\#|\&amp|RT")
        return reference_pattern.sub(r'', text)


#%% get folder names
source = "raw"
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
subfolder = subfolders[43]

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
    files_en = os.listdir(os.path.join(source, "Companies_en", f"{subfolder}_en"))
    

    # get the dates available in both datasets
    dates_de = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files_de]
    dates_en = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files_en]
    dates_both_source = list(set(dates_de) & set(dates_en))
    dates_all_source = list(set(dates_de + dates_en))
    
    
    # now check which dates already exist at dest
    files_dest = os.listdir(os.path.join(dest, "Companies", subfolder))
    files_dest_cleaned =  os.listdir(os.path.join(dest_cleaned, "Companies", subfolder))
    
    # inner join
    files_dest_both = list(set(files_dest) & set(files_dest_cleaned))
    
    # extract dates
    dates_exist = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files_dest_both]
    
    
    # find all missing dates, in case on folder has more files than redo them again because quicker than accounting for it
    # and setting up separate loop
    dates_missing = list(set(dates_all_source) - set(dates_exist))
    
    # find dates missing that exist in both sources
    dates_both_missing = [k for k in dates_missing if k in dates_both_source]
    
    if dates_both_missing == []:
        print("No files missing that exist in german and english folders")
    else:
        print(f"Moving on to files that only exist in both folders for {subfolder}")

    
    # now for each date available in both got thru both folders and concat files, then clean and save them
    for date in dates_both_missing:
        print(f"Working on {subfolder}, {date}")
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
        
        # check if df still contains entries
        if len(df) > 0:
        
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
    
    # find missing dates for german only
    dates_de_only_missing = [k for k in dates_de_only if k not in dates_exist]
    
    if dates_de_only_missing == []:
        print("No files missing that exist in german folders only")
    else:
        print(f"Moving on to files that only exist in the german folder for {subfolder}")

    
    # only clean german files
    for date in dates_de_only_missing:
        print(f"Working on {subfolder}, {date}")
        tweets = []
        file = f"{subfolder}_{date}_de.json"
        path = os.path.join(source,"Companies_de",f"{subfolder}_de", file)
        for line in open(path, 'r',encoding="utf8"):
            tweets.append(json.loads(line,parse_int=str))
            
         # convert to df
        df = pd.DataFrame(tweets)
        
        # clean df
        df = df_cleaner(df)
        
        # check if df still cotninas rows
        if len(df) > 0:        
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
    
    # find missing
    dates_en_only_missing = [k for k in dates_en_only if k not in dates_exist]

    if dates_en_only_missing == []:
        print("No files missing that exist in english folders only")
    else:
        print(f"Moving on to files that only exist in the english folder for {subfolder}")
    # only clean german files
    for date in dates_en_only_missing:
        print(f"Working on {subfolder}, {date}")
        tweets = []
        file = f"{subfolder}_{date}_en.json"
        path = os.path.join(source,"Companies_en",f"{subfolder}_en", file)
        for line in open(path, 'r',encoding="utf8"):
            tweets.append(json.loads(line,parse_int=str))
            
         # convert to df
        df = pd.DataFrame(tweets)
        
        # clean df
        df = df_cleaner(df)
        
        if len(df) > 0:
        
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




#%% process for nofilter folders
# for each date go into all folders concat the dfs, clean them and store them inside new folder

for lang in lang_folders:
    if lang == "De":
        folders = de_folders
    else:
        folders = en_folders
    
    
    # find dates that are missing, check for one folder in source because we assume all have the same dates avaialble
    files_source = [k for k in os.listdir(os.path.join(source, folders[0])) if ".json" in k]
    # convert to datelist
    dates_source = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files_source]
    
    # check which files already exist
    files_dest = [k for k in os.listdir(os.path.join(dest,folders[0])) if ".csv" in k]
    files_dest_cleaned = [k for k in os.listdir(os.path.join(dest_cleaned,folders[0])) if ".csv" in k]
    
    # inner join list and find last date that exists in both
    files_dest_both = list(set(files_dest) & set(files_dest_cleaned))
    # convert to datelist
    dates_dest = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files_dest_both]
    
    # find files in source but not dest
    dates_missing = list(set(dates_source) - set(dates_dest))
    
   

        
    # go thru all dates
    for date in dates_missing:
        
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
            if filename in os.listdir(os.path.join(source, folder)):
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