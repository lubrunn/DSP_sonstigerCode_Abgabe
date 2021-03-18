import sys
sys.path.insert(0, r'C:\Users\lukas\Documents\GitHub\DSP_Sentiment_Covid\Code\Twitter')
from twitter_scraper_function_company import twitter_scraper_company
import pandas as pd
import nest_asyncio
nest_asyncio.apply()
import twint
import time
from datetime import datetime
import os

date_list = pd.date_range(start="2020-06-01",end="2020-06-08")
date_list = date_list.to_series().dt.date

company_list = pd.read_pickle(r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\search_terms_companies.pkl")
                          
#company_list = company_list.iloc[:,:]
#%%

twitter_scraper_company(data_path = r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\raw_test\tweets_per_day_test\Companies_en",
                        companies = company_list, date_list = date_list, language = "en",
                        tweet_day = 10000)