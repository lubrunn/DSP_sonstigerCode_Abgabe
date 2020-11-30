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

date_list = pd.date_range(start="2019-12-01",end="2019-12-08")
date_list = date_list.to_series().dt.date

company_list = pd.read_csv(r"C:\Users\lukas\Documents\Uni\Data Science Project\Python\Stock\data\company_names.csv",
                           encoding = "ISO-8859-1")["Company Name"].to_list()

company_list = list(set(company_list))

twitter_scraper_company(data_path = r"C:\Users\lukas\Documents\Uni\Data Science Project\Python\twint_webscraping\data\company_de",
                        company_list = company_list, date_list = date_list, language = "de")