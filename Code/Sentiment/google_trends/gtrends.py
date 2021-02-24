#https://github.com/qztseng/google-trends-daily/blob/master/google%20Trend%20daily%20data%20for%20iphone.ipynb
# reconstruct google trends data.
# google does not return daily data for a time horizon over 90 days
import pytrends
from pytrends.request import TrendReq
import pandas as pd
from datetime import date, datetime, timedelta
import matplotlib.pyplot as plt


# Specify the parameters to your liking
start_date= date(2018, 11, 30) # specify your start date
end_date= date(2021, 2, 19) # specify your end date
_cat = 0 # Category to narrow down your results
_gprop = '' # What Google property to filter to (e.g 'images')
_tz = 360 # specify your time-zone

def perdelta(start, end, delta):
    curr = start
    while curr < end:
        yield curr
        curr += delta

dates=[]
for res in perdelta(start_date, end_date, timedelta(days=90)):
    dates.append(res)  
dates.append(end_date)


key_word = 'coronavirus' 

geos = list(['EN','DE'])

hls = list(['en-EN','de-DE']) 

appended_data = []

for a in range(1):
    _geo = geos[a]
    _hl = hls[a]
    for i in range(len(dates)-1):
        try: 
            _timeframe = str(dates[i]) + ' ' + str(dates[i+1])
            totalTrend = TrendReq(hl=_hl, tz=_tz)
            totalTrend.build_payload([key_word], cat=_cat, timeframe=_timeframe, geo=_geo, gprop=_gprop)
            totalTrend = totalTrend.interest_over_time()
            appended_data.append(totalTrend)
        except KeyError: 
            print('Please specify the Parameters (e.g. Keyword)')
            break


for i in range(len(appended_data)-1):
    x = appended_data[i][key_word].tail(1).values
    y = appended_data[i+1][key_word].head(1).values
    if x == 0 and y == 0:
        factor = 1
    elif x == 0:
        factor = 0.5/y
    elif y == 0:
        factor = x/0.5
    else:
        factor = x/y
    appended_data[i+1][key_word] = appended_data[i+1][key_word] * factor


appended_df = pd.concat(appended_data, axis=0)

appended_df = appended_df[~appended_df.index.duplicated(keep='first')]

appended_df = appended_df.drop(["isPartial"], axis = 1)


finalb.to_csv(r"C:\Users\simon\OneDrive - UT Cloud\Eigene Dateien\Data\Twitter\sentiment\Model\Covid_trends_DE.csv")
