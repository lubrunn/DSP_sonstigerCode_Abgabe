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
# country_list_long = ["Austria", "Singapore", "India", "France", "Sweden", "Columbia", "Marocco", "Ecuador",
#                 "Switzerland", "Australia", "Southafrica", "Brasil", "Irland", "Israel", "Kenya", "Argentina",
#                 "USA", "Germany", "England", "Spain", "Italy", "China", "Russia"]

# lang_code_long = {"Austria":"de", "Singapore":"en", "India":"en", "France":"fr", "Sweden":"sv", "Columbia":"es", "Marocco":"fr", "Ecuador":"es",
#              "Switzerland":"de", "Australia":"en", "Southafrica":"en", "Brasil":"pt", "Irland":"en", "Israel":"he", "Kenya":"en", "Argentina":"es",
#                 "USA":"en", "Germany":"de", "England":"en", "Spain":"es", "Italy":"it", "China":"zh", "Russia":"ru"}

# country_list_ger_long = ["Österreich", "Singapur", "Indien", "Frankreich", "Schweden", "Kolumbien", "Marokko", "Ecuador",
#                 "Schweiz", "Australien", "Südafrika", "Brasilien", "Irland", "Israel", "Kenia", "Argentinien",
#                 "USA", "Deutschland", "England", "Spanien", "Italien", "China", "Russland"]

# lang_code_ger_long = {"Österreich":"de", "Singapur":"en", "Indien":"en", "Frankreich":"fr", "Schweden":"sv", "Kolumbien":"es", "Marokko":"fr", "Ecuador":"es",
#              "Schweiz":"de", "Australien":"en", "Southafrica":"en", "Brasilien":"pt", "Irland":"en", "Israel":"he", "Kenia":"en", "Argentinnien":"es",
#                 "USA":"en", "Deutschland":"de", "England":"en", "Spain":"es", "Italy":"it", "China":"zh", "Russia":"ru"}

country_list = ["USA", "Germany", "Spain", "Switzerland", "Australia", "Brasil", "Irland", "Austria",
                "Singapore", "India", "France", "Sweden", "Argentina", "Hongkong", "Mexico",
                #all countries written in german because we found that they yield different results sometimes
                "Deutschland", "Spanien", "Schweiz", "Australien", "Brasilien", "Österreich", 
                "Singapur", "Indien", "Frankreich", "Schweden","Argentinien"
                ]

#dictionary for the country code which is needed for twitter search querry to specify language
# otherwise get results from german twitter users in each country (at least in tests we did)
lang_code = {"USA":"en", "Germany":"de", "Spain":"es", "Switzerland":"de", "Australia":"en", "Brasil":"pt", "Irland":"en",
             "Austria":"de", "Singapore":"en", "India":"en", "France":"fr", "Sweden":"sv", "Argentina":"es",
             "Hongkong":"en", "Mexico":"es",
             "Deutschland":"de", "Spanien":"es", "Schweiz":"de", "Australien":"en", "Brasilien":"pt",
             "Österreich":"de", "Singapur":"en", "Indien":"en", "Frankreich":"fr", "Schweden":"sv", "Argentinien":"es"}


#%%
date_list = date_list[:2]
country_list = country_list[:2]
#how long going to sleep after scraping one country done
sleep_country = 60
#how long going to sleep after one day has been scraped
sleep_day = 5
for country in country_list:
    print(f"Started working on {country}")
    for date in date_list:
        time1 = time.time()
        config = twint.Config() 
        
        date1 = date
        date2 = date - pd.Timedelta(days = 1)
        
        language = lang_code[country]
        
        config.Search = f"until:{date1} since:{date2} near:{country} lang:{language}"
        config.Store_object = True 
        
        #create a folder for each country
        if not os.path.exists(country):
            os.mkdir(country)
        
        #c.Store_csv = True
        config.Limit = 2900 #number needed to get around 1mio posts per country
        config.Store_csv = True
        config.Output = f'{country}/{country}_{date2}.csv'
        twint.run.Search(config) 
        #search_list = config.search_tweet_list
        
        print(f"The process took {round(time.time() - time1)} seconds")
        time.sleep(5)
    time.sleep(60)



#%% test loop
for country in country_list:
    print(f"Started working on {country}")
    for date in date_list:
        
        
        
        date1 = date
        date2 = date - pd.Timedelta(days = 1)
        
        language = lang_code[country]
        
        

