import os
import re
from datetime import datetime
import numpy as np
import pandas as pd

#%%
def date_missing_finder(files):
    # check what is the last date for which tweets were scraped
    
    # extract date from file names
    dates = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files]
    
    # convert to dates
    dates_list = [datetime.strptime(date, "%Y-%m-%d").date() for date in np.array(dates)]
    
    # find last date
    last_update = max(dates_list)
    
    # find dates between last scrape and today
    today = datetime.today().strftime('%Y-%m-%d')
    missing_dates = pd.date_range(start=last_update,end=today)
    
    return missing_dates


######### check last day that was scraped
path = r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\raw"

# all folders 
folders = os.listdir(path)

# folders for comapny scraping
company_folders = [k for k in folders if "Companies" in k]

# folders for nofilter scraping
nofilter_folders = [k for k in folders if "NoFilter" in k]


i = 0
folder = folders[i]
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
 
#%% scrape missing dates for each folder 

# create df that contains info for limit, search terms etc.
info_df = pd.DataFrame(data = np.empty((10,4)),
    columns = ["folder", "min_retweets", "lang", "limit"]) 

# fill df
info_df.iloc[0,:] = ["NoFilter_de", 0, "de", 20000]  
info_df.iloc[1,:] = ["NoFilter_min_retweets_2_de", 2, "de", 40000]  
info_df.iloc[2,:] = ["NoFilter_en", 0, "en", 20000]  
info_df.iloc[3,:] = ["NoFilter_min_retweets_2_en", 2, "en", 20000]  
info_df.iloc[4,:] = ["NoFilter_min_retweets_10_en", 10, "en", 20000]  
info_df.iloc[5,:] = ["NoFilter_min_retweets_50_en", 50, "en", 20000]  
info_df.iloc[6,:] = ["NoFilter_min_retweets_100_en", 100, "en",20000]  
info_df.iloc[7,:] = ["NoFilter_min_retweets_200_en", 200, "en", 40000]  
info_df.iloc[8,:] = ["Companies_de", 0, "de", 5000]  
info_df.iloc[9,:] = ["Companies_en", 0, "en", 5000]  

#%%
folder = folders[0]

min_retweets = int(info_df.loc[info_df["folder"] == folder, "min_retweets"].values[0])
lang = info_df.loc[info_df["folder"] == folder, "lang"].values[0]
limit = int(info_df.loc[info_df["folder"] == folder, "limit"].values[0])

if folder in company_folders:
    path_new = os.path.join(path, folder)
    
    # list all subfolders (one per company)
    subfolders = os.listdir(path_new)
    
    for subfolder in subfolders:
        search_name = subfolder
        
        search_term1 = f"{search_name} min_retweets:{min_retweets} lang:{lang}"
        
        for date in missing_dates_dic[subfolder]:
            date1 = date.date()
            date2 = (date - pd.Timedelta(days = 1)).date()
            
            search_term = f"{search_term1} unitl:{date1} since:{date2}"
            print(search_term)
elif folder in nofilter_folders:
    search_term1 = f"{search_name} min_retweets:{min_retweets} lang:{lang}"

    for date in missing_dates_dic[subfolder]:
            date1 = date.date()
            date2 = (date - pd.Timedelta(days = 1))
            
            search_term = f"{search_term1} unitl:{date1} since:{date2}"
            print(search_term)
    



