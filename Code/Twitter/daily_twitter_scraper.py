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
folders = iter(folders)
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
    
    



    
    
    



