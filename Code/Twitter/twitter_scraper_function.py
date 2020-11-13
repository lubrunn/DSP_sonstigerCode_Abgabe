from datetime import datetime
import pandas as pd


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


capital_lang_code = {'Washington, D.C.': 'USA', 'Berlin': 'Germany', 'Madrid': 'Spain', 'Bern': 'Switzerland',
                     'Canberra': 'Australia', 'Brasilia': 'Brasil', 'Dublin': 'Irland', 'Vienna': 'Austria', 
                     'Singapore': 'Singapore', 'New Delhi': 'India', 'Paris': 'France', 'Stockholm': 'Sweden',
                     'Buenos Aires': 'Argentina', 'Hongkong': 'Hongkong', 'Mexico City': 'Mexico', 
                     'Wien': 'Austria', 'Singapur': 'Singapore', 'Neu-Delhi': 'India'}



#define the function
def twitter_scraper(data_path, near_list = capital_list, lang_dict = capital_lang_code, date_list = date_list, day_range = 1, 
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