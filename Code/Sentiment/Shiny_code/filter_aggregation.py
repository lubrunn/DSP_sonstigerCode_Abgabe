def filter_aggregation(df,lan,filt_len,filt_ret,filt_lik,median_len,ticker):
    
    import functools
    import operator
    import numpy as np
    import pandas as pd
    
    # specify condition as boolean condition to speed up evaluation
    if filt_len == "yes":
        condition = (df.retweets_count > filt_ret) & (df.likes_count > filt_lik) & (df.tweet_length > median_len)
    else:
        condition = (df.retweets_count > filt_ret) & (df.likes_count > filt_lik)         
    
    df = df[condition]
    
    
    # high performance pandas
    #df = df.query[ 'retweets_count > @filt_retweet and likes_count > @filt_likes']
       
    
    #check if after filtering all dates are still left
    
    all_dates = df['date'].unique()
    
    #calculate median once    
    # slow: look for alternatives      
    mean_sentiment_by_retweet = [(i, np.ma.average(df['sentiment'].loc[df.date == i],
                                                   weights = df['retweets_count'].loc[df.date == i])) for i in all_dates] 
 
    
    #result =  df.groupby(['date']).apply(lambda x: np.ma.average(df['sentiment'], weights=df['retweets_count']))

    
    # flatten tuple and remove date
    mean_sentiment_by_retweet = functools.reduce(operator.iconcat, mean_sentiment_by_retweet, [])
    mean_sentiment_by_retweet = pd.Series(mean_sentiment_by_retweet[1::2])
    
           
    # weight the sentiments by their length
    mean_sentiment_by_length = [(i, np.ma.average(df['sentiment'].loc[df.date == i],
                                                   weights = df['tweet_length'].loc[df.date == i])) for i in all_dates] 
    # flatten tuple and remove date
    mean_sentiment_by_length = functools.reduce(operator.iconcat, mean_sentiment_by_length, [])
    mean_sentiment_by_length = pd.Series(mean_sentiment_by_length[1::2])    
    
    # weight the sentiments by their number of likes  
    mean_sentiment_by_likes = [(i, np.ma.average(df['sentiment'].loc[df.date == i],
                                                   weights = df['likes_count'].loc[df.date == i])) for i in all_dates]
        
    # flatten tuple and remove date
    mean_sentiment_by_likes = functools.reduce(operator.iconcat, mean_sentiment_by_likes, [])
    mean_sentiment_by_likes = pd.Series(mean_sentiment_by_likes[1::2])    


    # just mean
    mean_sentiment  = [(i, df['sentiment'].loc[df.date == i].mean()) for i in all_dates]
    
    # flatten tuple and remove date
    mean_sentiment = functools.reduce(operator.iconcat, mean_sentiment, [])
    mean_sentiment = pd.Series(mean_sentiment[1::2])    

    print(f"{lan}_NoFilter_{filt_ret}_{filt_lik}_{filt_len}")
    
    filt_ret = pd.Series(np.repeat(filt_ret, len(mean_sentiment), axis=0))   
    filt_lik = pd.Series(np.repeat(filt_lik, len(mean_sentiment), axis=0))   
    filt_len = pd.Series(np.repeat(filt_len, len(mean_sentiment), axis=0))   
    
    all_dates = pd.Series(all_dates)
    
    final = pd.DataFrame({'date':all_dates,
                              'sentiment_mean':mean_sentiment,
                              'sentiment_weight_retweet':mean_sentiment_by_retweet,
                              'sentiment_weight_length':mean_sentiment_by_length,
                              'sentiment_weight_likes':mean_sentiment_by_likes,
                              'retweet_filter':filt_ret,
                              'likes_filter':filt_lik,
                              'long_tweet':filt_len})
  
    
    final.to_csv(f"C://Users//simon//OneDrive - UT Cloud//Eigene Dateien//Data//Twitter//sentiment//Simon_test//{lan}_NoFilter_{ticker}.csv",mode = "a", 
                     index=False,header= False)    
  
        
