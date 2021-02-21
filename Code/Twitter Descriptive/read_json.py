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
        
def df_cleaner(df):        
    # drop duplicate tweets
    df = df.drop_duplicates(subset=["id"], keep='first')

    # only keep tweets with correct language
    df = df[df["language"] == lang.lower()]
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
    df["tweet_length"] = df["tweet_length"].astype("object")
    return df

#%% get folder names
source = "raw_test"
dest = "raw_csv"
dest_cleaned = "pre_cleaned"
folders_all = [k for k in os.listdir(source) if "Comp" in k or "Filter" in k]

company_folders = [k for k in folders_all if "Comp" in k]
nofilter_folders = [k for k in folders_all if "Filter" in k]

#%% testing
folder = nofilter_folders[0]
file = files[0]
folder = company_folders[0]
subfolder = subfolders[0]

#%%
for main_folder in folders_all:
    if main_folder in company_folders:
        subfolders = os.listdir(os.path.join(source,folder))
        for subfolder in subfolders:
            new_dest = os.path.join(dest,folder, subfolder)
    
            if not os.path.exists(new_dest):
                os.mkdir(os.path.join(new_dest))
            files = os.listdir(os.path.join(source,folder, subfolder))
            for file in [k for k in files if ".json" in k]:
                
                tweets = []
                path = os.path.join(source,folder,subfolder, file)
                for line in open(path, 'r',encoding="utf8"):
                    tweets.append(json.loads(line,parse_int=str))
                df = pd.DataFrame(tweets)
                
                # fix place column
                # split into two new lat/long columns
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
                
                
                new_filename = f"{file.split('.')[0]}.csv"
                df.to_csv(os.path.join(new_dest,new_filename))    
                
        
            
    
    


    
        
    
            
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

#%% testing
date = date_list_needed[7]
folder = en_folders[5]
subfolder = [k for k in en_folders if k != folder][0]



#%% cleaning functions
def remove_light(text):
        reference_pattern = re.compile(r"\@\w+|\@\w+\'|\@\w+\’|<.*?>|https?://\S+|www\.\S+|\d+\.|\d+|\#|\&amp|RT")
        return reference_pattern.sub(r'', text)

print(remove_light('''Everybody in the UK is flipping out over a video of some 
                   dude picking up a mace, and I cannot for the life of me 
                   understand why.   Is it because you’re playing by 1st ed. 
                   rules and he’s not a cleric? lukas@email.com @donaldtup'''))

   

#%%
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
        df = df_cleaner(df)
        
        
        
        new_filename = f"{lang}_NoFilter_{date}.feather"
        new_filename_csv = f"{lang}_NoFilter_{date}.csv"
        
        # save df
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