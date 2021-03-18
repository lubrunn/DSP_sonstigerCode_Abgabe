import os
os.chdir(r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\raw_test\tweets_per_day_test\Companies_de")
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
df_en = df
df_de = df
#%%
df = pd.concat([df_en, df_de])

#%%
df["number_tweets"] = df["number_tweets"].astype("int64")
df_de["number_tweets"] = df_de["number_tweets"].astype("int64")

#%% average tweets overall
print(df_en.describe())
#%%
#df_alldays = df.groupby("Location").filter(lambda x: len(x) == 8)
#%%
df_alldays_group = df.groupby("Location")["number_tweets"].mean()

#%%
df_alldays_group.sort_values(inplace = True, ascending = False)
df_alldays_group = df_alldays_group.to_frame()
df_alldays_group.reset_index(inplace = True)
