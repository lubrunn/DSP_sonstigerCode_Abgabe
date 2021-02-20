import os
import re

os.chdir(r"C:\Users\simon\Documents\GitHub\DSP_Sentiment_Covid\Code\Sentiment\Shiny_code")

import pandas as pd
from get_date import date_finder
from tweet_collector import tweet_collector
import pyarrow.feather as feather

               
# path to company and non-specific tweets
path_1 = r"C:\Users\simon\OneDrive - UT Cloud\Eigene Dateien\Data\Twitter\raw"


# all folders 
folders = os.listdir(path_1)

# folders for comapny scraping
company_folders = [k for k in folders if "Companies" in k]

# folders for nofilter scraping
nofilter_folders = [k for k in folders if "NoFilter" in k]
nofilter_folders = [k for k in nofilter_folders if "En" in k]
nofilter_folders.remove("En_NoFilter")   

# loop through the all folders in given path   
for folder in folders:
    
    if folder in nofilter_folders:
        
    #print(folder)    
    #df = pd.DataFrame(list())
    #df.to_csv(f"/home/simonhassler/share/Lukas_onedrive/Data/Twitter/sentiment/Shiny_files/tweets_en_{folder}.csv")
             
    # create a list of json files within the selected folder 
        json_files = os.listdir(os.path.join(path_1,folder))
        json_files = [k for k in json_files if "NoFilter" in k]
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
   # tweet_collector(int(retweets),"En",date_range_input,file,date_list,folder)           
          

        # sructure for the company folders
    elif folder in company_folders:
        
            
            # new path leading to all subfolders
        path_new = os.path.join(path_1,folder)
         
            # list all subfolders
        subfolders = os.listdir(path_new)
            # slice for testing
        subfolders = subfolders[18:20]
            
            # loop through all companies 
        for subfolder in subfolders:
                print(subfolder)
                df = pd.DataFrame(list())
                df.to_csv(f"C:\\Users\\simon\\OneDrive - UT Cloud\\Eigene Dateien\\Data\\Twitter\\sentiment\\Shiny_files_companies\\tweets_{subfolder}.csv")
         
                # get all files for that subfolder
                json_files = os.listdir(os.path.join(path_new,subfolder))         
               
                # get date range of json files
                date_range_input = date_finder(json_files)
                date_list = date_range_input.to_series().dt.date
                
                # create path to selected folder
                file = os.path.join(path_new,subfolder)
                
                # get language from folder name
                if "de" in folder:
                    lang = "de"
                else:
                    lang = "en"

                # call sentiment function
                tweet_collector(0,"de",date_range_input,file,date_list,folder,subfolder)


#####################companies##########################

#after storing csv's load them and append german and englisch csv

# path to csvs
path_csvs = r"C:\Users\simon\OneDrive - UT Cloud\Eigene Dateien\Data\Twitter\sentiment\Shiny_files_companies"

files = os.listdir(path_csvs)

file = files[0]

for file in files:
    
    splitat = 7
    strip_file_name = file[:-splitat]
    
    df_en = pd.read_csv(f"{path_csvs}\\{strip_file_name}_en.csv")
    df_en["language"] = "en"
    df_de = pd.read_csv(f"{path_csvs}\\{strip_file_name}_de.csv")
    df_de["language"] = "de"
    
    df_en = df_en.append(df_de)
    del df_de
    # reset index
    df_en = df_en.reset_index()

    # rename columns
    df_en = df_en.rename(columns={"level_0":"id","level_1":"date",
                         "level_2":"retweets_count","level_3":"likes_count","level_4":"user_id",
                         "level_5":"tweet_length","Unnamed: 0":"sentiment"})

    
    strip_company = file.split("_")[1]
    
    feather.write_feather(df_en, f"{path_csvs}\{strip_company}.feather") 

    












# read in the csv file which was created by the sentiment function  
df_final = pd.read_csv(r"C:\Users\simon\Desktop\WS_20_21\DS_12\test.csv")



# write the dataframe as complete feather file
# (feather files do not allow to append data)
