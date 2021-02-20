import os
os.chdir(r"C:\Users\lukas\OneDrive - UT Cloud\Data\twitter")
import json
import pandas as pd
import re
import numpy as np
from datetime import datetime
import swifter   # optimize apply function (similar performance to vectorized ops.)



#%%
# tweets = []
# path = os.path.join("test.json")
# for line in open(path, 'r',encoding="utf8"):
#     tweets.append(json.loads(line,parse_int=str))
    
    
# # with open('data.json', 'w') as outfile:
# #     json.dump(tweets, outfile)

# #%%    
# df = pd.DataFrame(tweets)
# # split place column into two column
# coord = df["place"].apply(pd.Series)["coordinates"].apply(pd.Series)
# coord.rename(columns = {0:"lat", 1:"long"},
#              inplace = True)

# df.drop("place", axis = 1, inplace = True)

# df = pd.concat([df, coord], axis = 1)

# #%%
# df.to_feather("test.feather")


#%% get folder names
source = "raw_test"
dest = "raw_feather"
folders = [k for k in os.listdir(source) if "Comp" in k or "Filter" in k]

company_folders = [k for k in folders if "Comp" in k]
nofilter_folders = [k for k in folders if "Filter" in k]

#%% testing
folder = nofilter_folders[0]
file = files[0]
folder = company_folders[0]
subfolder = subfolders[0]

#%%
for folder in folders:
    if folder in company_folders:
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
                    
                    coord = df["place"].apply(pd.Series)["coordinates"].apply(pd.Series)
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
                
                
                new_filename = f"{file.split('.')[0]}.feather"
                df.to_feather(os.path.join(new_dest,new_filename))
        
    else: 
        
        
        new_dest = os.path.join(dest, folder)
        
        if not os.path.exists(new_dest):
            os.mkdir(os.path.join(new_dest))
        files = os.listdir(os.path.join(source,folder))
        for file in [k for k in files if ".json" in k]:
            
            tweets = []
            path = os.path.join(source,folder, file)
            for line in open(path, 'r',encoding="utf8"):
                tweets.append(json.loads(line,parse_int=str))
            df = pd.DataFrame(tweets)
            
            if ~sum(df["place"] == "") == len(df):
                coord = df["place"].apply(pd.Series)["coordinates"].apply(pd.Series)
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
            
            
            new_filename = f"{file.split('.')[0]}.feather"
            df.to_feather(os.path.join(new_dest,new_filename))
            
            
#%% for nofilter folders concat all tweets from one day together

# store language folders seperately
en_folders = [k for k in nofilter_folders if "En" in k]
de_folders = [k for k in nofilter_folders if "De" in k]


# first get all dates needed
# for this get files from one folder, have same dates available
files = os.listdir(os.path.join(source, en_folders[0]))
# list of all dates we have data
dates = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files]
         
# convert to dates
dates_list = [datetime.strptime(date, "%Y-%m-%d").date() for date in np.array(dates)]

# find last date
last_update = max(dates_list)


date_list_needed = pd.date_range(start="2018-11-30",end=last_update).strftime('%Y-%m-%d').to_list()

#%% testing
date = date_list_needed[10]
folder = en_folders[0]
subfolder = [k for k in en_folders if k != folder][0]



#%% cleaning functions
def remove_light(text):
        reference_pattern = re.compile(r"\@\w+|\@\w+\'|\@\w+\’|<.*?>|https?://\S+|www\.\S+|\d+\.|\d+|\#|\&amp|RT")
        return reference_pattern.sub(r'', text)
    

   

#%%
# for each date go into all folders concat the dfs, clean them and store them inside new folder

for date in date_list_needed:
    # set up list
    tweets = []
    #go into each folder folders an concat tweets to df
    for folder in en_folders:
        filename = f"{folder}_{date}.json"
        path1 = os.path.join(source, folder, filename)
        
        for line in open(path1, 'r',encoding="utf8"):
            tweets.append(json.loads(line,parse_int=str))
    df = pd.DataFrame(tweets)
    
    # drop duplicate tweets
    df = df.drop_duplicates(subset=["id"], keep='first')

    # split coordingates column into lat/long
    if ~sum(df["place"] == "") == len(df):
        coord = df["place"].apply(pd.Series)["coordinates"].apply(pd.Series)
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
    
    df.reset_index(inplace = True)
    
    # remove links and handles
    df["tweet"] = df["tweet"].apply(lambda tweet: remove_light(tweet))
    # strip extra whitespace
    df["tweet"] = df["tweet"].str.strip()
    df["tweet"] = df["tweet"].replace('\s+', ' ', regex=True)
    
    
    # compute length of tweets
    length_checker = np.vectorize(len)
    # get length of each tweet
    df["tweet_length"] = length_checker(df["tweet"])
    
    
    new_filename = f"En_NoFilter_{date}.feather"
    df.to_feather(os.path.join(dest, "En_NoFilter",new_filename))