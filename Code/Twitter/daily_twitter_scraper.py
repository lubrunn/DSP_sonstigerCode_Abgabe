import os
import re
from datetime import datetime
import numpy as np
import pandas as pd

import nest_asyncio
nest_asyncio.apply()
import twint
import time

#%% set path were all the data is
path = "/home/lukasbrunner/share/onedrive/Data/Twitter/raw"

# set path were company search term pkl is
path_comp = "/home/lukasbrunner/share/onedrive/Data/Twitter"

#%%
# all required dates
today = datetime.today().strftime('%Y-%m-%d')
date_list_needed = pd.date_range(start="2018-11-30",end=today)


#%% 
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
info_df.iloc[8,:] = ["Companies_de", 0, "de", 5000]  
info_df.iloc[9,:] = ["Companies_en", 0, "en", 5000]  


#%% read in search terms for companies
search_terms_companies = pd.read_pickle(os.path.join(path_comp,"search_terms_companies.pkl"))


#%% set up function to find out which dates still need to be scraped
def date_missing_finder(files):
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

#%%
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
            
            # get missing dates
            missing_dates = date_missing_finder(files)
            
            # save missing dates to folder name into dict
            missing_dates_dic[subfolder] = missing_dates
        
    elif folder in nofilter_folders:
        
        # get all files for the nofilter folder
        files = os.listdir(os.path.join(path,folder))
        
        # find missing dates in these files
        missing_dates = date_missing_finder(files)
        
        # save missing dates to folder name into dict
        missing_dates_dic[folder] = missing_dates
 



#%% get dict with all search terms that need to be querried
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
            if "Johnson" in subfolder:
                search_name = search_terms_companies[search_terms_companies.index.str.split(" ").str[0] == subfolder.split("_")[0].split(" ")[0]].search_term.item()
            else:
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
        for date in missing_dates_dic[subfolder]:
                date1 = (date + pd.Timedelta(days = 1)).date()
                date2 = date.date()
                
                search_term = f"{search_term1} until:{date1} since:{date2}"
                
                # save to list
                search_term_list.append(search_term)
        # save search term list to dict
        search_term_dict[folder] = search_term_list
                
        
    
    
#%% now run scraper for each row in dict for all search terms  
# get smaller dict for testing
#import random
#search_term_dict_test = dict(random.sample(search_term_dict.items(), 2))

for key,value in search_term_dict.items():
    # retry 10 times in case of html token error
    print(f"Started working on {key}")
    for attempt in range(10):
        
        try:
            print(f"Attempt: {attempt})")
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