import sys
sys.path.insert(0, r'C:\Users\lukas\Documents\GitHub\DSP_Sentiment_Covid\Code\Twitter')
from twitter_scraper_function import twitter_scraper
import pandas as pd
import nest_asyncio
nest_asyncio.apply()
import twint
import time
from datetime import datetime
import os

#%%
#create date range for wanted dates
today = datetime.today().strftime('%Y-%m-%d')
date_list = pd.date_range(start="2019-12-01",end=today)
date_list = date_list.to_series().dt.date



country_list = ["USA", "Germany", "Spain", "Switzerland", "Australia", "Brasil", "Irland", "Austria",
                "Singapore", "India", "France", "Sweden", "Argentina", "Hongkong", "Mexico",
                #all countries written in german because we found that they yield different results sometimes
                "Deutschland", "Spanien", "Schweiz", "Australien", "Brasilien", "Österreich", 
                "Singapur", "Indien", "Frankreich", "Schweden","Argentinien"
                ]

#dictionary for the country code which is needed for twitter search querry to specify language
# otherwise get results from german twitter users in each country (at least in tests we did)
country_lang_code = {"USA":"en", "Germany":"de", "Spain":"es", "Switzerland":"de", "Australia":"en", "Brasil":"pt", "Irland":"en",
             "Austria":"de", "Singapore":"en", "India":"en", "France":"fr", "Sweden":"sv", "Argentina":"es",
             "Hongkong":"en", "Mexico":"es",
             "Deutschland":"de", "Spanien":"es", "Schweiz":"de", "Australien":"en", "Brasilien":"pt",
             "Österreich":"de", "Singapur":"en", "Indien":"en", "Frankreich":"fr", "Schweden":"sv", "Argentinien":"es"}

#do same for capitals
capital_list = ['Washington, D.C.', 'Berlin', 'Madrid', 'Bern', 'Canberra', 'Brasilia', 'Dublin',
                'Vienna', 'Singapore', 'New Delhi', 'Paris', 'Stockholm', 'Buenos Aires','Hongkong',
                'Mexico City', 'Wien', 'Singapur','Neu-Delhi'
                ]


capital_lang_code = {'Washington, D.C.': 'en', 'Berlin': 'de', 'Madrid': 'es', 'Bern': 'de',
                     'Canberra': 'en', 'Brasilia': 'pt', 'Dublin':'en', 'Vienna': 'de', 
                     'Singapore': 'en', 'New Delhi': 'en', 'Paris': 'fr', 'Stockholm': 'sv',
                     'Buenos Aires': 'es', 'Hongkong': 'en', 'Mexico City': 'es', 
                     'Wien': 'de', 'Singapur': 'en', 'Neu-Delhi': 'en'}





biggest_city_list = ["New York City", "Los Angeles", "Chicago",
                     "Berlin", "Hamburg", "München","Munich",
                     "Madrid", "Barcelona", "Valencia",
                     "Zürich", "Geneva", "Basel","Genf",
                     "Sydney", "Melbourne", "Brisbane",
                     "Sao Paulo", "Rio de Janeiro", "Brasilia",
                     "Dublin", "Cork", "Limerick",
                     "Vienna", "Graz", "Linz","Wien",
                     "Singapore", "Singapur",
                     "Mumbai", "New Delhi", "Kolkata", "Neu-Delhi",
                     "Paris", "Marseille", "Lyon",
                     "Stockholm", "Gothenburg", "Malmö",
                     "Buenos Aires", "Mendoza", "Rosario",
                     "Hongkong",
                     "Mexico City", "Ecatepec", "Guadalajara"]



biggest_city_lang_code = {
  **dict.fromkeys(["New York City", "Los Angeles", "Chicago"], "en"), 
  **dict.fromkeys(["Berlin", "Hamburg", "München","Munich"], "de"),
  **dict.fromkeys(["Madrid", "Barcelona", "Valencia"], "es"),
  **dict.fromkeys(["Zürich", "Geneva", "Basel","Genf"], "de"),
  **dict.fromkeys(["Sydney", "Melbourne", "Brisbane"], "en"),
  **dict.fromkeys(["Sao Paulo", "Rio de Janeiro", "Brasilia"], "pt"),
  **dict.fromkeys(["Dublin", "Cork", "Limerick"], "en"),
  **dict.fromkeys(["Vienna", "Graz", "Linz","Wien"], "de"),
  **dict.fromkeys(["Singapore", "Singapur"], "en"),
  **dict.fromkeys(["Mumbai", "New Delhi", "Kolkata", "Neu-Delhi"], "en"),
  **dict.fromkeys(["Paris", "Marseille", "Lyon"], "fr"),
  **dict.fromkeys(["Stockholm", "Gothenburg", "Malmö"], "sv"),
  **dict.fromkeys(["Hongkong"], "en"),
  **dict.fromkeys(["Mexico City", "Ecatepec", "Guadalajara"], "es")
}
#%% run the function
twitter_scraper(data_path = r"C:\Users\lukas\Documents\Uni\Data Science Project\Python\twint_webscraping\data", 
                near_list = biggest_city_list, lang_dict = biggest_city_lang_code, date_list = date_list, day_range = 1, 
                    sleep_location = 60, sleep_day = 1, tweet_goal = 1000000)