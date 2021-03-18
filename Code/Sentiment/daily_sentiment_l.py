import os
#os.chdir(r"/home/simonhassler/share/local_code/GerVADER-master/")
os.chdir("C:/Users/lukas/Documents/GitHub/DSP_Sentiment_Covid/Code/Sentiment/GerVADER-master")
import pandas as pd
import nltk
#nltk.download('GERVaderLexicon')
#from vaderSentimentGER import SentimentIntensityAnalyzer
nltk.download('vader_lexicon')
#from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import numpy as np
import swifter
import time
from datetime import datetime
import re
#load sentiment_daily
#load_raw_csv
#extract folders from both match the difference
# de /en no filter loop


# wrap this object in a function
# returns the weighted sentiment for the complete tweet    
def get_sentiment(text):
   sentiment = pd.DataFrame([sid_obj.polarity_scores(text)])
   return sentiment["compound"]



# get date from yesterday
yesterday = (datetime.today() - pd.Timedelta(days=1)).strftime('%Y-%m-%d')

#complete daterange
#no range !!!
date_list_needed = pd.date_range(start="2018-11-30",end=yesterday)


# path to folders with all files (updates every day)
#path_raw = r"/home/simonhassler/share/Lukas_onedrive/Data/Twitter/raw_csv"
path_raw = r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\raw_csv"

#extract folder names from file with current files
#path = r"/home/simonhassler/share/Lukas_onedrive/Data/Twitter/sentiment_daily"
path = r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\sentiment_daily"
folders = os.listdir(path)

#filter for NoFilter folder
nofilter_folders = [k for k in folders if "NoFilter" in k]
company_folders = [k for k in folders if "Companies" in k]

#subseet language for companies
language = list(["en","de"])


#go through  german and englisch NoFilter folder
for folder in nofilter_folders:
    
    #create new path
    path_new = os.path.join(path,folder)
   
    #get file names
    files = os.listdir(path_new)
    
    # extract date from file names
    dates = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files]
    
    # convert to dates
    dates_list_have = [datetime.strptime(date, "%Y-%m-%d").date() for date in np.array(dates)]    
    #filter missing files
    missing_dates = [k for k in date_list_needed if k not in dates_list_have]
    # from timpesatamp to string
    missing_dates = [date_obj.strftime('%Y-%m-%d') for date_obj in missing_dates]
    #paste csv to evry string
    missing_dates =  [x + '.csv' for x in missing_dates]    
        
    #get path to all files    
    path_comp = os.path.join(path_raw,folder)
    
    #get all missing files and calculate sentiment
    for files_csv in missing_dates:
        #load file
        tweet = pd.read_csv(f"{path_comp}/{folder}_{files_csv}",engine='python')  
        #drop row with no tweet
        tweet = tweet.dropna(subset = ['tweet'])   
        #remove strings after date
        tweet['created_at'] = tweet['created_at'].map(lambda x: str(x)[:-13])    
        
        # load vader based on langunge
        substring = "De"
        #check if substring is in folder name
        if substring in folder:
            from vaderSentimentGER import SentimentIntensityAnalyzer
        else:
            from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

        # initialize the object to get sentiment   
        sid_obj = SentimentIntensityAnalyzer()
        # calculate sentiment for every tweet
        tweet["sentiment"] = tweet["tweet"].swifter.progress_bar(False).apply(lambda x: get_sentiment(x))
        
        # tweet.to_csv(f"/home/simonhassler/share/Lukas_onedrive/Data/Twitter/sentiment_daily/{folder}/{folder}_{files_csv}", 
        #             index=False)
        
        tweet.to_csv(f"C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/sentiment_daily/{folder}/{folder}_{files_csv}", 
                    index=False)
        
        
        
        print(files_csv)
        

#loop for the companies
for folder in company_folders:

    # new path leading to all subfolders
    path_new = os.path.join(path,folder)
    path_new_raw = os.path.join(path_raw,folder)
    # list all subfolders
    subfolders = os.listdir(path_new)

    # go thorugh all company folder   
    for subfolder in subfolders:
     
        # get all files for that subfolder
        files = os.listdir(os.path.join(path_new,subfolder))
        files_raw = os.listdir(os.path.join(path_new_raw,subfolder))
        
        dates_raw = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files_raw]
         
        # convert to dates
        dates_list_have_raw = [datetime.strptime(date, "%Y-%m-%d").date() for date in np.array(dates_raw)]    

        
        # find last date that has been updated
        # extract date from file names
        dates = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files]
         
        # convert to dates
        dates_list_have = [datetime.strptime(date, "%Y-%m-%d").date() for date in np.array(dates)]    
        #filter missing files
        missing_dates = [k for k in dates_list_have_raw if k not in dates_list_have]
        # from timpesatamp to string
        missing_dates = [date_obj.strftime('%Y-%m-%d') for date_obj in missing_dates]
        #paste csv to evry string
        missing_dates =  [x + '.csv' for x in missing_dates]   
        
        
        #get path to all files    
        path_comp = os.path.join(path_raw,folder)
        # go through all subfolder companies
        for a in missing_dates:
            #create empty list to append later
            tweet_full = pd.DataFrame(list()) 
            # load csv
            tweet = pd.read_csv(f"{path_comp}/{subfolder}/{subfolder}_{a}",engine='python') 
            #drop missing tweets
            tweet = tweet.dropna(subset = ['tweet'])    
            #extract date from string
            tweet['created_at'] = tweet['created_at'].map(lambda x: str(x)[:-13])         
            #subset datframe by language to get correct vader
            for i in language:
            
                if i == "en":
                    from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
                else:
                    from vaderSentimentGER import SentimentIntensityAnalyzer
                    
                #init sentiment object
                sid_obj = SentimentIntensityAnalyzer()
                # subset dataset by language
                tweet1 = tweet[tweet['language']== i ]
                #calculate sentiment
                tweet1["sentiment"] = tweet1["tweet"].swifter.progress_bar(False).apply(lambda x: get_sentiment(x))
                        
                # append both languages
                tweet_full = tweet_full.append(tweet1)
                
                    
                                    
            # tweet_full.to_csv(f"/home/simonhassler/share/Lukas_onedrive/Data/Twitter/sentiment_daily/{folder}/{subfolder}/{subfolder}_{a}", 
            #                     index=False)
            
            tweet_full.to_csv(f"C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/sentiment_daily/{folder}/{subfolder}/{subfolder}_{a}", 
                                index=False)

            print(a)











