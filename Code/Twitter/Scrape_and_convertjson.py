import os
import re
from datetime import datetime
import numpy as np
import pandas as pd

import nest_asyncio
nest_asyncio.apply()
import twint
import time



#### readjson


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


# vpc or local?
vpc = False
#%% set path were all the data is

if vpc == True:
    path = "/home/lukasbrunner/share/onedrive_new2/Data/Twitter/raw"
    
    # set path were company search term pkl is
    path_comp = "/home/lukasbrunner/share/onedrive_new2/Data/Twitter"

else:
    path = r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\raw"
    
    # set path were company search term pkl is
    path_comp = r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter"

 #%% set up function to find out which dates still need to be scraped
def date_missing_finder(files, date_list_needed):
    '''
    

    Parameters
    ----------
    files : list of all files in a given folder
    
    PROCESS
    ----------
    extract dates of tweet files and find missing dates that still need
    to be scraped

    Returns
    -------
    missing_dates : list of dates that still need to be scraped for a specific
    folder

    '''
    # only use json files
    files = [k for k in files if ".json" in k]
    
    ### check what is the last date for which tweets were scraped
    # extract date from file names
    dates = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files]
    
    # convert to dates
    dates_list_have = [datetime.strptime(date, "%Y-%m-%d").date() for date in np.array(dates)]
    
    # find all missing dates by checking difference between the dates we have 
    # and the dates that we should have (dates_list_needed)
    missing_dates = [k for k in date_list_needed if k not in dates_list_have]
    
    return missing_dates
    
#%
# create df that contains info for limit, search terms etc.
info_df = pd.DataFrame(data = np.empty((10,4)),
    columns = ["folder", "min_retweets", "lang", "limit"]) 

# fill df
info_df.iloc[0,:] = ["De_NoFilter", 0, "de", 20000]  
info_df.iloc[1,:] = ["De_NoFilter_min_retweets_2", 2, "de", 40000]  
info_df.iloc[2,:] = ["En_NoFilter", 0, "en", 20000]  
info_df.iloc[3,:] = ["En_NoFilter_min_retweets_2", 2, "en", 20000]  
info_df.iloc[4,:] = ["En_NoFilter_min_retweets_10", 10, "en", 20000]  
info_df.iloc[5,:] = ["En_NoFilter_min_retweets_50", 50, "en", 20000]  
info_df.iloc[6,:] = ["En_NoFilter_min_retweets_100", 100, "en",20000]  
info_df.iloc[7,:] = ["En_NoFilter_min_retweets_200", 200, "en", 40000]  
info_df.iloc[8,:] = ["Companies_de", 0, "de", 10000]  
info_df.iloc[9,:] = ["Companies_en", 0, "en", 10000]  
    
# read in search terms for companies
search_terms_companies = pd.read_pickle(os.path.join(path_comp,"search_terms_companies.pkl"))
def twitter_scraper(info_df, search_terms_companies):
    #
    # all required dates
    yesterday = (datetime.today()- pd.Timedelta(days = 1)).strftime('%Y-%m-%d') 
    
    # do it for yesterday because otherwise search might be incomplete because 
    # current day is still generating tweets
    date_list_needed = pd.date_range(start="2018-11-30",end=yesterday)
    
    
    
    
    
    
    
   
    
    #
    ######### run missing_dates function over all folders
    
    
    # all folders 
    folders = os.listdir(path)
    
    
    # folders for comapny scraping
    company_folders = [k for k in folders if "Companies" in k]
    
    # folders for nofilter scraping
    nofilter_folders = [k for k in folders if "NoFilter" in k]
    
    
    
    missing_dates_dic = {}
    
    for folder in folders:
        # two cases, first case:
        # for companies where the company folders contain subfolders for each company
        # second case:
        # nofilter folders do not have subfolders    
        if folder in company_folders:
            
            
            # new path leading to all subfolders
            path_new = os.path.join(path,folder)
            
            # list all subfolders
            subfolders = os.listdir(path_new)
            
            for subfolder in subfolders:
           
            
                # get all files for that subfolder
                files = os.listdir(os.path.join(path_new,subfolder))
                
                # find last date that has been updated
                # extract date from file names
                dates = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files]
                 
                # convert to dates
                dates_list = [datetime.strptime(date, "%Y-%m-%d").date() for date in np.array(dates)]
                
                # find last date
                last_update = max(dates_list)
                
                 
                # find dates between last scrape and today
                # if last_update is same or later than yesterday do not update
                if last_update < datetime.strptime(yesterday, "%Y-%m-%d").date():
                    missing_dates = pd.date_range(start=last_update + pd.Timedelta(days = 1),end=yesterday)
                else:
                    missing_dates = []
                        
                # get missing dates
                # missing_dates = date_missing_finder(files)
                
                # save missing dates to folder name into dict
                missing_dates_dic[subfolder] = missing_dates
            
        elif folder in nofilter_folders:
            
            # get all files for the nofilter folder
            files = os.listdir(os.path.join(path,folder))
            
            # find missing dates in these files
            missing_dates = date_missing_finder(files, date_list_needed)
            
            # save missing dates to folder name into dict
            missing_dates_dic[folder] = missing_dates
     
    
    
    
    # get dict with all search terms that need to be querried
    folder = folders[0]
    search_term_dict = {}
    # scrape missing dates for each folder
    for folder in [k for k in folders if k in company_folders or k in nofilter_folders]:
        # check search terms from info_df
        min_retweets = int(info_df.loc[info_df["folder"] == folder, "min_retweets"].values[0])
        lang = info_df.loc[info_df["folder"] == folder, "lang"].values[0]
        limit = int(info_df.loc[info_df["folder"] == folder, "limit"].values[0])
        
        # different process for company scraping
        if folder in company_folders:
            path_new = os.path.join(path, folder)
            
            # list all subfolders (one per company)
            subfolders = os.listdir(path_new)
            
            # for each company
            for subfolder in subfolders:
                # find search term for company in search term df
                
                
                search_name = search_terms_companies[search_terms_companies.index == subfolder.split("_")[0]].search_term.item()
    
                # set up first part of search term (without dates)
                search_term1 = f"{search_name} min_retweets:{min_retweets} lang:{lang}"
                
                # go thru datelist and scrape once for each day
                search_term_list = []
                for date in missing_dates_dic[subfolder]:
                    
                    date1 = (date + pd.Timedelta(days = 1)).date()
                    date2 = date.date()
                    
                    search_term = f"{search_term1} until:{date1} since:{date2}"
                    # add search terms to list
                    search_term_list.append(search_term)
                # save search term list to dict
                # if folder == "Companies_de":
                #     subfolder = f"{subfolder}_de"
                # elif folder == "Companies_en": 
                #     subfolder = f"{subfolder}_en"
                search_term_dict[subfolder] = search_term_list
        elif folder in nofilter_folders:
            # setup first part of search term without dates
            search_term1 = f"min_retweets:{min_retweets} lang:{lang}"
            # go thru datelist and scrape once for each day
            search_term_list = []
            for date in missing_dates_dic[folder]:
                    date1 = (date + pd.Timedelta(days = 1)).date()
                    date2 = date.date()
                    
                    search_term = f"{search_term1} until:{date1} since:{date2}"
                    
                    # save to list
                    search_term_list.append(search_term)
            # save search term list to dict
            search_term_dict[folder] = search_term_list
                    
            
        
        
    # now run scraper for each row in dict for all search terms  
    # get smaller dict for testing
    #import random
    #search_term_dict_test = dict(random.sample(search_term_dict.items(), 2))
    
    for key,value in search_term_dict.items():
        # retry 10 times in case of html token error
        print(f"Started working on {key}")
        for attempt in range(10):
            
            try:
                print(f"Attempt: {attempt}")
                #print(key, value)
                # check if key (folder name) is not in nofilter folder --> company folder
                if key not in nofilter_folders:
                    limit = 5000
                else: # --> nofilter folder
                    limit = int(info_df.loc[info_df["folder"] == key, "limit"].values[0])
                    
                search_dict = search_term_dict[key]
                for search_term in search_dict:
                    print(f"Scraping tweets for search term: {search_term}")
                    # set up scraper
                    config = twint.Config() 
                    # search for search terms in dict
                    config.Search = search_term
                    # store results
                    config.Store_object = True 
                    
                    # store data as json
                    config.Store_json = True
                    
                    # set limit for number of tweets scraped per search
                    config.Limit = limit
                    
                    # extract date info from search term for saving
                    date2 = search_term.split("since:")[1]
                    # define where to save output
                    # first for company folders
                    if key not in nofilter_folders:
                        # here check if german or english company folder
                        country_code = key.split("_")[1]
                        config.Output = os.path.join(path,"Companies" + "_" + country_code,
                                                     key, key.split("_")[0] + "_" +
                                                     str(date2) + "_" + 
                                                     country_code + ".json")
                    # then for no filter folders
                    else:
                        config.Output = os.path.join(path, key,
                                                     key + "_" + str(date2) + ".json")
                    # dont show tweets being scraped in console    
                    config.Hide_output = True
                    #run twitter search
                    twint.run.Search(config) 
            except:
                  error_sleep = 60
                  print(f"Encountered problem going to {error_sleep} seconds to sleep and will then retry.")
                  time.sleep(60)
                  continue
            else:
                print("Breaking after too many fails.")
                break
        else:
            print("Too many errors")
            
#%% run scraper
twitter_scraper(info_df, search_terms_companies)

#################################################################################
################################################################################
#################################################################################
###########
#%% convert jsons to csv and do first cleaning

# get folder names
source = "raw"
dest = "raw_csv"
dest_cleaned = "pre_cleaned"
folders_all = [k for k in os.listdir(os.path.join(path_comp,source)) if "Comp" in k or "Filter" in k]

company_folders = ["Companies_en", "Companies_de"]
nofilter_folders = [k for k in folders_all if "Filter" in k]

# get all company folders without en/de
subfolders = [k.split("_")[0] for k in  os.listdir(os.path.join(path_comp, source, "Companies_en"))]


#%%
        
def df_cleaner(df, lang_controller = False, lang = None):        
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
        reference_pattern = re.compile(r"\@\w+|\@\w+\'|\@\w+\|<.*?>|https?://\S+|www\.\S+|\d+\.|\d+|\#|\&amp|RT")
        return reference_pattern.sub(r'', text)






#%%

# list all subfolders
def json_converter_companies(source, dest, dest_cleaned,
                             company_folders, 
                             subfolders):
    for subfolder in subfolders:
        print(f"Working on {subfolder}")
        new_dest = os.path.join(path_comp, dest,"Companies", subfolder)
        new_dest_cleaned = os.path.join(path_comp, dest_cleaned,"Companies2", subfolder)
        
        # create folder in new destination if it does not already exist
        if not os.path.exists(os.path.join(path_comp, new_dest)):
            os.mkdir(os.path.join(path_comp, new_dest))
        if not os.path.exists(os.path.join(path_comp, new_dest_cleaned)):
            os.mkdir(os.path.join(path_comp, new_dest_cleaned))
        
        # now go into each company folder in the source an concat files from same day together
        # for this need to check if files exist in both and control for it
        files_de = os.listdir(os.path.join(path_comp, source, "Companies_de", f"{subfolder}_de"))
        files_en = os.listdir(os.path.join(path_comp, source, "Companies_en", f"{subfolder}_en"))
        
    
        # get the dates available in both datasets
        dates_de = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files_de]
        dates_en = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files_en]
        dates_both_source = list(set(dates_de) & set(dates_en))
        dates_all_source = list(set(dates_de + dates_en))
        
        
        # now check which dates already exist at dest
        files_dest = os.listdir(os.path.join(path_comp, dest, "Companies", subfolder))
        files_dest_cleaned =  os.listdir(os.path.join(path_comp, dest_cleaned, "Companies2", subfolder))
        
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
                path = os.path.join(path_comp, source,folder,f"{subfolder}_{folder.split('_')[1]}", file)
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
                
                df.to_csv(os.path.join(path_comp, new_dest ,new_filename_csv),
                          index = False)
                
                
                
                
                ###########
                # now replace emojis and save in different destination
                ###########
                df["tweet"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: demoji.replace_with_desc(tweet, 
                                                                                                   sep = " "))# replace _ from emojis with " "
                df.tweet = df.tweet.str.replace("_", " ")
                #save df
                df.to_csv(os.path.join(path_comp, new_dest_cleaned,new_filename_csv),
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
            path = os.path.join(path_comp, source,"Companies_de",f"{subfolder}_de", file)
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
                df.to_csv(os.path.join(path_comp, new_dest ,new_filename_csv),
                          index = False)
                
                ###########
                # now replace emojis and save in different destination
                ###########
                df["tweet"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: demoji.replace_with_desc(tweet, 
                                                                                                   sep = " "))# replace _ from emojis with " "
                df.tweet = df.tweet.str.replace("_", " ")
                #save df
                df.to_csv(os.path.join(path_comp, new_dest_cleaned,new_filename_csv),
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
            path = os.path.join(path_comp, source,"Companies_en",f"{subfolder}_en", file)
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
                df.to_csv(os.path.join(path_comp, new_dest ,new_filename_csv),
                          index = False)  
            
                ###########
                # now replace emojis and save in different destination
                ###########
                df["tweet"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: demoji.replace_with_desc(tweet, 
                                                                                                   sep = " "))# replace _ from emojis with " "
                df.tweet = df.tweet.str.replace("_", " ")
                #save df
                df.to_csv(os.path.join(path_comp, new_dest_cleaned,new_filename_csv),
                          index = False)
            
        
        
            
                
    
    


#%% run convert on companies
json_converter_companies(source, dest, dest_cleaned,
                             company_folders, 
                             subfolders) 
    
            


#%%  process for all NoFilter folders
# for nofilter folders concat all tweets from one day together

# store language folders seperately
en_folders = [k for k in nofilter_folders if "En" in k]
de_folders = [k for k in nofilter_folders if "De" in k]
lang_folders = ["En", "De"]




#%% process for nofilter folders
# for each date go into all folders concat the dfs, clean them and store them inside new folder
def json_converter_nofilter(lang_folders, en_folders, de_folders,
                            dest, dest_cleaned):
    for lang in lang_folders:
        if lang == "De":
            folders = de_folders
        else:
            folders = en_folders
        
        print("Started working, checking for missing files")
        # find dates that are missing, check for one folder in source because we assume all have the same dates avaialble
        files_source = [k for k in os.listdir(os.path.join(path_comp, source, folders[0])) if ".json" in k]
        # convert to datelist
        dates_source = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files_source]
        
        # check which files already exist
        files_dest = [k for k in os.listdir(os.path.join(path_comp, dest,folders[0])) if ".csv" in k]
        files_dest_cleaned = [k for k in os.listdir(os.path.join(path_comp, dest_cleaned,folders[0])) if ".csv" in k]
        
        # inner join list and find last date that exists in both
        files_dest_both = list(set(files_dest) & set(files_dest_cleaned))
        # convert to datelist
        dates_dest = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files_dest_both]
        
        # find files in source but not dest
        dates_missing = list(set(dates_source) - set(dates_dest))
        
        if len(dates_missing) == 0:
            print("No missing files found")
    
            
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
                path1 = os.path.join(path_comp, source, folder, filename)
                
                # load json files
                if filename in os.listdir(os.path.join(path_comp, source, folder)):
                    for line in open(path1, 'r',encoding="utf8"):
                        tweets.append(json.loads(line,parse_int=str))
            
            # convert to df
            df = pd.DataFrame(tweets)
            
            # clean dataframe
            print("Cleaning df")
            df = df_cleaner(df, lang_controller = True, lang = lang)
            
            
            
            
            new_filename_csv = f"{lang}_NoFilter_{date}.csv"
            
            # save df
            print("Saving data")
            df.to_csv(os.path.join(path_comp, dest, f"{lang}_NoFilter",new_filename_csv),
                      index = False)
            
            
            # now replace emojis and save in different destination
            df["tweet"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: demoji.replace_with_desc(tweet, 
                                                                                               sep = " "))
            
            # replace _ from emojis with " "
            df.tweet = df.tweet.str.replace("_", " ")
            
            #save df
            df.to_csv(os.path.join(path_comp, dest_cleaned, f"{lang}_NoFilter",new_filename_csv),
                      index = False)
#%% run converter for nofilter
json_converter_nofilter(lang_folders, en_folders, de_folders,
                        dest, dest_cleaned)
