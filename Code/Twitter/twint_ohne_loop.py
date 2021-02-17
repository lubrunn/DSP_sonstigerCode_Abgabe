import pandas as pd
import nest_asyncio
nest_asyncio.apply()
import twint
import time
import os
os.chdir(r"C:\Users\lukas\Documents\Uni\Data Science Project\Python\twint_webscraping\data")
from datetime import datetime


#%%


time1 = time.time()
config = twint.Config() 

date1 = "2020-04-25"
date2 = "2020-04-24"

language = "de"
country = "Germany"
#search = " "
#search_term = "Santander"
#config.Search = f'until:"{date1}" since:{date2} near:"{country}" lang:{language}'
#config.Search = f'"{search_term}" until:{date1} since:{date2} lang:{language}'
#config.Search = f'min_retweets:2 until:{date1} since:{date2} lang:{language}'
config.Search = "apple"
config.Search = "JohnsonJohnson OR @JNJNews OR @JNJGlobalHealth min_retweets:0 lang:en until:2021-02-17 since:2021-02-16"
config.Store_object = True 

#create a folder for each country
# if not os.path.exists(country):
#     os.mkdir(country)
    
# if not os.path.exists(search_term):
#     os.mkdir(search_term)

#c.Store_csv = True
config.Limit = 100
#config.Store_csv = True
#config.Output = f'{country}/{country}_{date2}.csv'
#config.Output = f'{search_term}/{search_term}_{date2}.csv'
config.Store_json = True
config.Output = f"test.json"
#config.Output = f'{search_term}/{search_term}_{date2}.json'
config.Hide_output = True
twint.run.Search(config) 
#search_list = config.search_tweet_list

print(f"The process took {round(time.time() - time1)} seconds")



#%% read in results


