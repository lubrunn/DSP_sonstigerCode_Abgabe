import emoji
import time
import swifter
import pandas as pd

#%%
text = "game is on 🔥 🔥 :-)"
print(emoji.demojize(text, delimiters=("", "")))
print(emoji.demojize(text))

#%%
# load data
df = pd.read_feather(r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\raw_feather\En_NoFilter\En_NoFilter_2018-12-10.feather")
#%%
time1 = time.time()
df["tweet_n"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: emoji.demojize(tweet, 
                                                                                           delimiters = (" ", " ")))
time2 = time.time() - time1
print(time2)

#%%
a = df[["id", "tweet", "tweet_n"]].head(1000)


#%% with different package
import demoji

demoji.download_codes()

#%%
print(demoji.findall(text))
#%%
print(demoji.replace_with_desc(text, sep = ""))
#%% take time
time1 = time.time()
df["tweet_n"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: demoji.replace_with_desc(tweet, 
                                                                                           sep = " "))
time2 = time.time() - time1
print(time2)


#%% replace _ from emojis with " "
df.tweet_n = df.tweet_n.str.replace("_", " ")



#%% replace emoticons
from emot.emo_unicode import UNICODE_EMO, EMOTICONS
import re


def convert_emoticons(text):
    for emot in EMOTICONS:
        text = re.sub(u'(' +emot+ ')', " ".join(EMOTICONS[emot].replace(",","  ").split()), text)
    return text

print(convert_emoticons(text))

print(convert_emoticons("I love u:)"))

#%%
time1 = time.time()
df["tweet_n"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: convert_emoticons(tweet))
time2 = time.time() - time1
print(time2)



#%% contractions
import contractions
print(contractions.fix("you've"))
print(contractions.fix("he's"))





#%% remove html markup
from bs4 import BeautifulSoup
from html import unescape
s = "&lt;b&gt;&lt;i&gt;&lt;u&gt;Charming boutique selling trendy casual &amp;amp; dressy apparel for women, some plus sized items, swimwear, shoes &amp;amp; jewelry.&lt;/u&gt;&lt;/i&gt;&lt;/b&gt;"

soup = BeautifulSoup(unescape(s), 'lxml').text
print(soup.text)   
    
#%%
time1 = time.time()
df["tweet_n"] = df["tweet"].swifter.progress_bar(False).apply(lambda tweet: BeautifulSoup(unescape(tweet), 'lxml')).text
time2 = time.time() - time1
print(time2)