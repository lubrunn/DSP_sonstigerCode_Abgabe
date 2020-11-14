import pandas as pd
import nest_asyncio
nest_asyncio.apply()
import twint
import time
import os
os.chdir(r"C:\Users\lukas\Documents\Uni\Data Science Project\Python\twint_webscraping\data")
from datetime import datetime

#%%
#create date range for wanted dates
date_list = pd.date_range(start="2019-12-01",end="2020-11-12")
date_list = date_list.to_series().dt.date

#create country list
country_list = ["Austria", "Singapore", "India", "France", "Sweden", "Columbia", "Marocco", "Ecuador",
                "Switzerland", "Australia", "Southafrica", "Brasil", "Irland", "Israel", "Kenya", "Argentina",
                "USA", "Germany", "England", "Spain", "Italy", "China", "Russia"]

lang_code = {"Austria":"de", "Singapore":"en", "India":"en", "France":"fr", "Sweden":"sv", "Columbia":"es", "Marocco":"fr", "Ecuador":"es",
             "Switzerland":"de", "Australia":"en", "Southafrica":"en", "Brasil":"pt", "Irland":"en", "Israel":"he", "Kenya":"en", "Argentina":"es",
                "USA":"en", "Germany":"de", "England":"en", "Spain":"es", "Italy":"it", "China":"zh", "Russia":"ru"}

#%%


time1 = time.time()
config = twint.Config() 

date1 = "2019-12-01"
date2 = "2019-11-30"

language = "de"
country = "Linz"

config.Search = f"until:{date1} since:{date2} near:{country} lang:{language}"
config.Store_object = True 

#create a folder for each country
if not os.path.exists(country):
    os.mkdir(country)

#c.Store_csv = True
config.Limit = 1000
config.Store_csv = True
config.Output = f'{country}/{country}_{date2}.csv'
twint.run.Search(config) 
#search_list = config.search_tweet_list

print(f"The process took {round(time.time() - time1)} seconds")




#%%
df2 = pd.read_csv("Germany_2019-12-01.csv")

