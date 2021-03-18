import pandas as pd
import nest_asyncio
nest_asyncio.apply()
import twint
import time

import os

#define the function
def twitter_scraper_company(data_path, companies, date_list, day_range = 1, 
                    sleep_company = 60, sleep_day = 1, tweet_day = 5000, language = "en"):
    # sleep_country = how long going to sleep after scraping one country done, default is 60 sec
    # sleep_day = how long going to sleep after one day has been scraped, default is 5 sec
    
    os.chdir(data_path)
    
    for i in range(0, len(companies)):
        time1 = time.time()
        company = companies.index[i]
        print(f"Started fetching data for {company}")
        for date in date_list:
            for attempt in range(10):
                try:
                    #for measuring function run time
                    time2 = time.time() 
                    #setup Twitter scraper
                    config = twint.Config() 
                    
                    date1 = date
                    date2 = date - pd.Timedelta(days = day_range)
                    
                    #extract list of all search term (stored in the columns of companies df)
                    
                    
                    search_term = companies.iloc[i,0]
                    
                    config.Search = f'{search_term} until:{date1} since:{date2} lang:{language}'
                    config.Store_object = True 
                    
                    
                    #create a folder for each country
                    if not os.path.exists(company):
                        os.mkdir(company)
                    
                    
                    #how many tweets needed per day to reach wanted tweets in total
                    #limit = tweet_day
                    #round up to next 100
                    #limit -= limit % -100
                    
                    #set limit for number of tweets scraped per search
                    config.Limit = tweet_day
                    
                    #store data
                    config.Store_json = True
                    
                    config.Output = f'{company}/{company}_{date2}_{language}.json'
                    
                    #run twitter search
                    twint.run.Search(config) 
                    
                    
                    print(f"The process for {date2} for {company} took {round(time.time() - time2)} seconds. Going {sleep_day} seconds to sleep.")
                    
                    time.sleep(sleep_day)
                except:
                    time.sleep(10)
                    continue
                else:
                    break
            else:
                print("Error")
        print(f"The overall process for {company} took {round(time.time() - time1)} seconds. Going {sleep_company} seconds to sleep.")
        time.sleep(sleep_company)