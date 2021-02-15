def id_finder(retweet,lan,date_range_input,path_raw,date_list):
   
       import pandas as pd
       import json
       
       for date in date_list:
           
            if "NoFilter" in path_raw:
               # account for different structure of json files within NoFilter folder
               if retweet == 0:
                   path =  f"{path_raw}\\{lan}_NoFilter_{date}.json"
               else:
                   path = f'{path_raw}\\{lan}_NoFilter_min_retweets_{retweet}_{date}.json'
        
        # initilalize tweets list
            tweets = []
    
            for line in open(path, 'r',encoding="utf8"):
                tweets.append(json.loads(line))
            
            df = pd.DataFrame(tweets)
            
            if len(df) == 0:
                continue
            
            df = df["id"]
            
            df.to_csv(r"C:\Users\simon\OneDrive - UT Cloud\Eigene Dateien\Data\Twitter\sentiment\Tweet_Ids\IDs.csv",mode = "a", 
                     index=False,header= False)