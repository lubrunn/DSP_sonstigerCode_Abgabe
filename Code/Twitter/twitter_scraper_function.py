#define the function
def twitter_scraper(data_path, near_list, lang_dict, date_list, day_range = 1, 
                    sleep_location = 60, sleep_day = 1, tweet_goal = 1000000):
    # sleep_country = how long going to sleep after scraping one country done, default is 60 sec
    # sleep_day = how long going to sleep after one day has been scraped, default is 5 sec
    
    for location in near_list:
        time1 = time.time()
        print(f"Started working on {location}")
        for date in date_list:
            #for measuring function run time
            time2 = time.time() 
            #setup Twitter scraper
            config = twint.Config() 
            
            date1 = date
            date2 = date - pd.Timedelta(days = day_range)
            
            
            language = lang_dict[location]
            
            config.Search = f"until:{date1} since:{date2} near:{location} lang:{language}"
            config.Store_object = True 
            
            #create a folder for each country
            if not os.path.exists(location):
                os.mkdir(location)
            
            
            #how many tweets needed per day to reach wanted tweets in total
            limit = tweet_goal/len(date_list)
            #round up to next 100
            limit -= limit % -100
            
            #set limit for number of tweets scraped per search
            config.Limit = limit 
            
            #store data
            config.Store_csv = True
            
            config.Output = f'{data_path}/{location}/{location}_{date2}.csv'
            
            #run twitter search
            twint.run.Search(config) 
            
            
            print(f"The process for {date2} in {location} took {round(time.time() - time2)} seconds. Going {sleep_day} to sleep.")
            
            time.sleep(sleep_day)
        print(f"The overall process for {location} took {round(time.time() - time1)} seconds. Going {sleep_location} to sleep.")
        time.sleep(sleep_location)