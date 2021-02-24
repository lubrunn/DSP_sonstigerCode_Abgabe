import pandas as pd
import nest_asyncio
nest_asyncio.apply()
import twint
import time
import os
os.chdir(r"C:\Users\lukas\Documents\Uni\Data Science Project\Python\twint_webscraping\data\mtu_de")
from datetime import datetime

#%%
#create date range for wanted dates
today = datetime.today().strftime('%Y-%m-%d')
date_list = pd.date_range(start="2018-12-01",end='2021-02-19')
date_list = date_list.to_series().dt.date



#%% filter by country
#how long going to sleep after scraping one country done

#how long going to sleep after one day has been scraped
sleep_day = 1
number_tweets = 10000

for date in date_list:
    time1 = time.time()
    config = twint.Config() 
    
    date1 = date
    date2 = date - pd.Timedelta(days = 1)
    
    language = "de"
    
    config.Search = f"MTU Aero Engines OR @MTUaeroeng  until:{date1} since:{date2} lang:{language}"
    config.Store_object = True 
    
    
    
    #c.Store_csv = True
    config.Limit = number_tweets #number needed to get around 1mio posts per country
    config.Store_json = True
    config.Output = f'MTU Aero Engines_{date2}_{language}.json'
    twint.run.Search(config) 
    #search_list = config.search_tweet_list
    
    print(f"The process took {round(time.time() - time1)} seconds")
    time.sleep(sleep_day)




        

        

