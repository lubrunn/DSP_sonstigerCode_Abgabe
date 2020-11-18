import os
os.chdir(r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter")
import pandas as pd


#results = {}
df = pd.DataFrame(columns = ["Location", "File", "number_tweets"])
folders = os.listdir()
for folder in folders:
    files = os.listdir(folder)
    for file in files:
    
        with open(f"{folder}/{file}", encoding="utf8") as fp:
            count = 0
            for _ in fp:
                count += 1
        
        #results[folder] = (file, count)
        df_series = pd.DataFrame(data = [[folder, file, count]], columns = ["Location", "File", "number_tweets"])
        df = pd.concat([df, df_series])

#%%
df["number_tweets"] = df["number_tweets"].astype("int64")
#%%
df_alldays = df.groupby("Location").filter(lambda x: len(x) > 345)
#%%
df_alldays_group = df_alldays.groupby("Location")["number_tweets"].mean()