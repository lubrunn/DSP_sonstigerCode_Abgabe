def filter_aggregation(df,lan,long_tweet,filt_retweet,filt_likes,median_len,ticker):
     
    import pyarrow.feather as feather
    import numpy as np
    import pandas as pd
    
    # specify condition as boolean condition to speed up evaluation
    if long_tweet == "yes":
        condition = (df.retweets_count > filt_ret) & (df.likes_count > filt_lik) & (df.tweet_length > median_len)
    else:
        condition = (df.retweets_count > filt_ret) & (df.likes_count > filt_lik)         
    
    df = df[condition]
    
    
    # high performance pandas
    #df = df.query[ 'retweets_count > @filt_retweet and likes_count > @filt_likes']
       
    
    #check if after filtering all dates are still left
    
    all_dates = df['date'].unique()
    
    #calculate median once    
           
    mean_sentiment_by_retweet = [(i, np.ma.average(df['sentiment'].loc[df.date == i],
                                                   weights = df['retweets_count'].loc[df.date == i])) for i in all_dates] 
        
    # account for tweets with 0 retweets -> just mean
   # if mean_sentiment_by_retweet == "nan":
   #        mean_sentiment_by_retweet =  df["sentiment"].mean()
           
    # weight the sentiments by their length
    mean_sentiment_by_length = np.average(df['sentiment'], 
                                              weights = df['tweet_length'])           
        
    # weight the sentiments by their number of likes  
    mean_sentiment_by_likes = np.ma.average(df['sentiment'], 
                                              weights = df['likes_count'])
        
    # account for tweets with 0 retweets -> just mean
    #if mean_sentiment_by_likes == "nan":
    #       mean_sentiment_by_likes =  df["sentiment"].mean()

    # just mean
    mean_sentiment = df["sentiment"].mean()
            
        
        
    final = pd.DataFrame([{'date':df["date"].iloc[1],
                              'sentiment_mean':mean_sentiment,
                              'sentiment_weight_retweet':mean_sentiment_by_retweet,
                              'sentiment_weight_length':mean_sentiment_by_length,
                              'sentiment_weight_likes':mean_sentiment_by_likes,
                              'retweet_filter':filt_retweet,
                              'likes_filter':filt_likes,
                              'long_tweet':long_tweet}])
        
        
        
    final.to_csv(f"C://Users//simon//OneDrive - UT Cloud//Eigene Dateien//Data//Twitter//sentiment//Simon_test//{lan}_NoFilter_{ticker}.csv",mode = "a", 
                     index=False,header= False)    
    #feather.write_feather(final, 
    #                      r"...{lan}_NoFilter_{filt_retweet}_{filt_likes}_{long_tweet}.feather") 

    print(f"{lan}_NoFilter_{filt_retweet}_{filt_likes}_{long_tweet}")
        
