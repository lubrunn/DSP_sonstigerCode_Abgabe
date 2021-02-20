import os
os.chdir(r"C:\Users\lukas\OneDrive - UT Cloud\Data\twitter")
import json
import pandas as pd


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


#%%
source = "raw"
dest = "raw_feather"
folders = [k for k in os.listdir(source) if "Comp" in k or "Filter" in k]

company_folders = [k for k in folders if "Comp" in k]
nofilter_folders = [k for k in folders if "Filter" in k]


folder = nofilter_folders[0]
file = files[0]
folder = company_folders[0]
subfolder = subfolders[0]

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