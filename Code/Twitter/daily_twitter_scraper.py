import os
import re
from datetime import datetime
import numpy as np
import pandas as pd

#%%



######### check last day that was scraped
path = r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\raw"

# all folders 
folders = os.listdir(path)

# folders for comapny scraping
company_folders = [k for k in folders if "Companies" in k]

# folders for nofilter scraping
nofilter_folders = [k for k in folders if "NoFilter" in k]

i = 5
folder = folders[i]


# two cases, first case:
# for companies where the company folders contain subfolders for each company
# second case:
# nofilter folders do not have subfolders    
if folder in company_folders:
    
    k = 0
    # new path leading to all subfolders
    path_new = os.path.join(path,folder)
    
    # list all subfolders
    subfolders = os.listdir(path_new)
    
    # select 1 subfolders
    subfolder = subfolders[k]
    
    # get all files for that subfolder
    files = os.listdir(os.path.join(path_new,subfolder))
    
elif folder in nofilter_folders:
    
    # get all files for the nofilter folder
    files = os.listdir(os.path.join(path,folder))
    
#%%
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



