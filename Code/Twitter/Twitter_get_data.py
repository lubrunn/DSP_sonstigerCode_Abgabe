import sys
sys.path.insert(0, r'C:\Users\lukas\Documents\GitHub\DSP_Sentiment_Covid\Code\Twitter')
from twitter_scraper_function import twitter_scraper
import pandas as pd
import nest_asyncio
nest_asyncio.apply()
import twint
import time
from datetime import datetime


#%% run the function
twitter_scraper(data_path = r"C:\Users\lukas\Documents\Uni\Data Science Project\Python\twint_webscraping\data")