import os
import re

os.chdir(r"C:\Users\simon\Desktop\WS_20_21\DS_12\Twitter_scrape")

import pandas as pd
from sentiment_final_vader import sentiment_over_time
from get_date import date_finder
import pyarrow.feather as feather

# initialize empty dataframe
df = pd.DataFrame(list())
df.to_csv(r"C:\Users\simon\Desktop\WS_20_21\DS_12\test.csv")

# path to company and non-specific tweets
path_1 = r"C:\Users\simon\Desktop\WS_20_21\DS_12\Sentiment"


# all folders 
folders = os.listdir(path_1)

# folders for comapny scraping
company_folders = [k for k in folders if "Companies" in k]

# folders for nofilter scraping
nofilter_folders = [k for k in folders if "NoFilter" in k]

# loop through the all folders in given path   
for folder in folders:
        
    # differentiate between NoFilter and company folders                
    # the follwing structure is for the NoFilter folers    
    if folder in nofilter_folders:   
            
            # create a list of json files within the selected folder 
            json_files = os.listdir(os.path.join(path_1,folder))
            
            # get date range of json files
            date_range_input = date_finder(json_files)
            
            # create path to selected folder
            file = os.path.join(path_1,folder)
            
            # get number of retweets from folder name
            retweets = re.findall(r'\d+', folder)
            retweets = str(retweets).strip("'[]'")
            
            # get language from folder name
            if "de" in folder:
                lang = "De"
            else:
                lang = "En"
            
            # account for if Folder has no retweet count in its name    
            if len(retweets) == 0:
                retweets = 0
            
            # call sentiment function
            sentiment_over_time(int(retweets),lang,date_range_input,file,folder)           
          
    # sructure for the company folders
    elif folder in company_folders:
         
            # new path leading to all subfolders
            path_new = os.path.join(path_1,folder)
         
            # list all subfolders
            subfolders = os.listdir(path_new)
            
            # loop through all companies 
            for subfolder in subfolders:
        
                # get all files for that subfolder
                json_files = os.listdir(os.path.join(path_new,subfolder))         
               
                # get date range of json files
                date_range_input = date_finder(json_files)
                
                # create path to selected folder
                file = os.path.join(path_new,subfolder)
                
                # get language from folder name
                if "de" in folder:
                    lang = "de"
                else:
                    lang = "en"

                # call sentiment function
                sentiment_over_time(0,lang,date_range_input,file,subfolder)


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

