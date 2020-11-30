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

date1 = "2020-05-20"
date2 = "2020-05-19"

language = "en"
country = "Germany"
#search = " "
#search_term = "Santander"
#config.Search = f'until:"{date1}" since:{date2} near:"{country}" lang:{language}'
#config.Search = f'"{search_term}" until:{date1} since:{date2} lang:{language}'
config.Search = f'Merck until:{date1} since:{date2} lang:{language}'
config.Store_object = True 

#create a folder for each country
# if not os.path.exists(country):
#     os.mkdir(country)
    
# if not os.path.exists(search_term):
#     os.mkdir(search_term)

#c.Store_csv = True
config.Limit = 2000
#config.Store_csv = True
#config.Output = f'{country}/{country}_{date2}.csv'
#config.Output = f'{search_term}/{search_term}_{date2}.csv'
config.Store_json = True
config.Output = "test2.json"
#config.Output = f'{search_term}/{search_term}_{date2}.json'
twint.run.Search(config) 
#search_list = config.search_tweet_list

print(f"The process took {round(time.time() - time1)} seconds")




#%%
df2 = pd.read_json("test2.json", lines = True)

