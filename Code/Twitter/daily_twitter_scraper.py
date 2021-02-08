import os
import re
from datetime import datetime
import numpy as np
import pandas as pd



#%%
# all required dates
today = datetime.today().strftime('%Y-%m-%d')
dates_list_needed = pd.date_range(start="2018-12-01",end=today)

#%%

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
    missing_dates = [k for k in date_list_needed if k not in dates_list]
    
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


#%% read in search terms for companies
search_terms_companies = pd.read_excel(r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\twitter handles.xlsx")

# drop with rows are only NAs
search_terms_companies = search_terms_companies[search_terms_companies["Company"].notna()]

# company name as index
search_terms_companies = search_terms_companies.set_index("Company", drop = False)

# for each row join all non-nas to a search term separated with OR
# set up new column
search_terms_companies["search_term"] = None
for i in range(0,len(search_terms_companies)):
    
    # get all twitter handles and merge them to one search term
    terms = [k for k in search_terms_companies.iloc[i,:].tolist() if str(k) != "nan" and k != None]
    search_term_comp = ' OR '.join(terms)
    
    # store in df
    search_terms_companies.iloc[i,search_terms_companies.shape[1] - 1] = search_term_comp
    
    
# only keep search term column
search_terms_companies = search_terms_companies[["search_term"]]
#%%
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
            search_name = search_terms_companies[search_terms_companies.index == subfolder].search_term.item()
            
            # set up first part of search term (without dates)
            search_term1 = f"{search_name} min_retweets:{min_retweets} lang:{lang}"
            
            # go thru datelist and scrape once for each day
            search_term_list = []
            for date in missing_dates_dic[subfolder]:
                date1 = date.date()
                date2 = (date - pd.Timedelta(days = 1)).date()
                
                search_term = f"{search_term1} unitl:{date1} since:{date2}"
                # add search terms to list
                search_term_list.append(search_term)
            # save search term list to dict
            if folder == "Companies_de":
                subfolder = f"{subfolder}_de"
            search_term_dict[subfolder] = search_term_list
    elif folder in nofilter_folders:
        # setup first part of search term without dates
        search_term1 = f"min_retweets:{min_retweets} lang:{lang}"
        # go thru datelist and scrape once for each day
        for date in missing_dates_dic[subfolder]:
                date1 = date.date()
                date2 = (date - pd.Timedelta(days = 1)).date()
                
                search_term = f"unitl:{date1} since:{date2}"
                
                # save to list
                search_term_list.append(search_term)
        # save search term list to dict
        search_term_dict[folder] = search_term_list
                
        
    
    
    
