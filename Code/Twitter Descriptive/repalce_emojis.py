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
df = pd.read_csv(r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\raw_csv\En_NoFilter\En_NoFilter_2018-12-10.csv")
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



#%%

import itertools 
#One letter in a word should not be present more than twice in continuation 
tweet = "r u mad ths is soo awesm enjoyd"
print("After standardizing the tweet is:-\n{}".format(tweet)) 
  
from autocorrect import Speller  
spell = Speller(lang='en') 
#spell check 
tweet=spell(tweet) 
print("After Spell check the tweet is:-\n{}".format(tweet))


#%%
import requests
slangText = 'r u MAD bruh ths is sooo awsm fk off fuk'
slangText = "Hello this is a normal text"
def slang_translator(slangText):
    prefixStr = '<div class="translation-text">'
    postfixStr = '</div'
    
    
    
    r = requests.post('https://www.noslang.com/', {'action': 'translate', 'p': 
    slangText, 'submit': 'Translate'})
    startIndex = r.text.find(prefixStr)+len(prefixStr)
    endIndex = startIndex + r.text[startIndex:].find(postfixStr)
    return r.text[startIndex:endIndex]


slang_translator(slangText)

#%% test for mutliple tweets
a = df.head(100)
time1 = time.time()
a["tweet_n"] = a["tweet"].swifter.progress_bar(False).apply(lambda tweet: slang_translator(tweet))
time2 = time.time() - time1
print(time2)



#%%
from bs4 import BeautifulSoup
import requests, json
resp = requests.get("http://www.netlingo.com/acronyms.php")
soup = BeautifulSoup(resp.text, "html.parser")
slangdict= {}
key=""
value=""
for div in soup.findAll('div', attrs={'class':'list_box3'}):
    for li in div.findAll('li'):
        for a in li.findAll('a'):
            key =a.text
            value = li.text.split(key)[1]
            slangdict[key]=value

with open('myslang.json', 'w') as f:
    json.dump(slangdict, f, indent=2)
    
    
    
#%% 
from bs4 import BeautifulSoup
import urllib3
import json
http=urllib3.PoolManager()
Abbr_dict={}
#Function to get the Slangs from https://www.noslang.com/dictionary/
def getAbbr(alpha):
    global Abbr_dict
    r=requests.get('https://www.noslang.com/dictionary/'+alpha)
    soup=BeautifulSoup(r.content,'html.parser')
    
    for i in soup.findAll('div',{'class':'dictionary-word'}): 

        abbr=i.find('abbr')['title']
        Abbr_dict[i.find('span').text[:-2]]=abbr
linkDict=[]
#Generating a-z
for one in range(97,123):
    linkDict.append(chr(one))
#Creating Links for https://www.noslang.com/dictionary/a...https://www.noslang.com/dictionary/b....etc
for i in linkDict:
    getAbbr(i)
# finally writing into a json file
with open('ShortendText.json','w') as file:
    jsonDict=json.dump(Abbr_dict,file)
    
    
    
#%% test
print(Abbr_dict["test"])

#%% list of all keys
keys = list(slangdict.keys())

# remove keys containig special characters bc causes problem with replace function
new_keys = [s for s in keys if s.isalnum()]

# new dict with only non special keys
newdict = {k: slangdict[k] for k in new_keys}


#%%
a["tweet"] = "this is a test tweet fk off bruh u mad md awsm fuk lol lmao rofl imo asap"

a.loc[:,"tweet_n"] =  a.loc[:,'tweet'].replace(newdict, regex = True)

print(a["tweet"][0])
print(a["tweet_n"][0])