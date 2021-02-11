import pandas as pd
import os
os.chdir(r"C:\Users\simon\Desktop\WS_20_21\DS_12\Twitter_scrape")
import re
from datetime import datetime
import numpy as np
from sentiment_final_vader import sentiment_over_time
import pyarrow.feather as feather


df_full = pd.read_feather(r"C:\Users\simon\Desktop\WS_20_21\DS_12\test_feather")


path_1 = r"C:\Users\simon\Desktop\WS_20_21\DS_12\Sentiment"

# store empty dataframe for the sentiment function
df = pd.DataFrame(list())
df.to_csv(r"C:\Users\simon\Desktop\WS_20_21\DS_12\test.csv")


# all folders 
folders = os.listdir(path_1)

# folders for comapny scraping
company_folders = [k for k in folders if "Companies" in k]

# folders for nofilter scraping
nofilter_folders = [k for k in folders if "NoFilter" in k]

# create a function that returns the missing dates
def date_difference(files,folder,df):
    
    # extract date from file names
    dates = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files]
    
    # convert to dates
    dates_list = [datetime.strptime(date, "%Y-%m-%d").date() for date in np.array(dates)]
    
    # filter for the selected folder in dataframe,
    # so dates are only compared for slected folder
    dates_list_2 = list(df["date"][df["company"] == folder])
    
    # create a list of dates
    dates_list_2 = [datetime.strptime(date, "%Y-%m-%d").date() for date in np.array(dates_list_2)]
    
    # Now we can just difference both list of dates
    date_diff = set(dates_list) - set(dates_list_2)

    # find last date
    last_date = max(date_diff)
    
    # find first date
    first_date = min(date_diff)
    
    # create a range of dates
    date_range_input = pd.date_range(start=first_date,end=last_date)


    return date_range_input


# loop through the folders from the given path
for folder in folders:
        
    # differentiate between NoFilter and company folders                
    # the follwing structure is for the NoFilter folers              
    if folder in nofilter_folders:   
    
            # create a list of json files within the selected folder 
            json_files = os.listdir(os.path.join(path_1,folder))
            
            # get date range of json files which are missing from original dataframe
            date_range_input = date_difference(json_files,folder,df_full)
            
            # get number of retweets from folder name
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
            
    elif folder in company_folders:
         
            # new path leading to all subfolders
            path_new = os.path.join(path_1,folder)
         
            # list all subfolders
            subfolders = os.listdir(path_new)
         
            for subfolder in subfolders:
        
                # get all files for that subfolder
                json_files = os.listdir(os.path.join(path_new,subfolder))         
                
                # get date range of json files which are missing from original dataframe
                date_range_input = date_difference(json_files,subfolder,df_full)
                 
                file = os.path.join(path_new,subfolder)
                
                # get language from folder name
                if "de" in folder:
                    lang = "de"
                else:
                    lang = "en"

                # call sentiment function
                sentiment_over_time(0,lang,date_range_input,file,subfolder)     
            
            
            
# load the created csv with the missing data    
df_final = pd.read_csv(r"C:\Users\simon\Desktop\WS_20_21\DS_12\test.csv")

# reset index
df_final = df_final.reset_index()

# rename columns
df_final = df_final.rename(columns={"level_0":"language","level_1":"retweet_count",
                         "level_2":"date","level_3":"company","level_4":"sentiment_mean",
                         "level_5":"sentiment_weight_retweet","level_6":"sentiment_weight_length",
                         "Unnamed: 0":"sentiment_weight_likes"})

# append dataframe to the original dataframe
df_full = df_full.append(df_final)            

# sort values
df_full = df_full.sort_values(by=['company','language','retweet_count'])

# write a feather file with the complete dataframe
feather.write_feather(df_full, r"C:\Users\simon\Desktop\WS_20_21\DS_12\test_feather")   




