import nltk
nltk.download('vader_lexicon')
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import pandas as pd


import numpy as np
import math
#%%
def get_sentiment(text):
    sentiment = pd.DataFrame([sid_obj.polarity_scores(text)])
    return sentiment["compound"]
sid_obj = SentimentIntensityAnalyzer()
get_sentiment("VADER is smart, handsome, and funny")

#%%
sid_obj = SentimentIntensityAnalyzer()
sentiment = sid_obj.polarity_scores("smart handsome funny")

#%%
a = sid_obj. make_lex_dict()

smart = a["smart"]
handsome = a["handsome"]
funny = a["funny"]

sentiments = [smart, handsome, funny]

sum_s = float(sum(sentiments))
compound = normalize(sum_s)

#%%
smart = 1.7 
smart2 = 0.78102

is_word = 1
VADER = 1
and_word = 1

handsome = 2.2	
handsome2 = 0.74833

funny = 1.9	
funny2 = 0.53852

#%%
first = np.array([smart, handsome, funny])
sec = np.array([smart2, handsome2, funny2])

#%%
print(first.mean())
print(sec.mean())

#%%
first_norm = first/abs(first).max()
#%%
print(first_norm.mean())

#%%
def normalize(score, alpha=15):
    """
    Normalize the score to be between -1 and 1 using an alpha that
    approximates the max expected value
    """
    norm_score = score / math.sqrt((score * score) + alpha)
    if norm_score < -1.0:
        return -1.0
    elif norm_score > 1.0:
        return 1.0
    else:
        return norm_score
    
print(normalize(1.9))
    
#%%
print(normalize(sum(first)))


#%%

text = "VADER is smart, handsome, and funny"



#%%
lexicon_full_filepath = r"C:\Users\lukas\Documents\Uni\Data Science Project\Python\Sentiment Analysis\vaderSentiment-master\vaderSentiment\vader_lexicon.txt"

for line in lexicon_full_filepath.rstrip('\n').split('\n'):
            if not line:
                continue
            (word, measure) = line.strip().split('\t')[0:2]
            lex_dict[word] = float(measure)
            
            
#%% try different text
text = "VADER is VERY SMART, uber handsome, and FRIGGIN FUNNY!!!"
            
sid_obj = SentimentIntensityAnalyzer()
sentiment = sid_obj.polarity_scores(text) 


#%%
smart = 1.7 + 0.733 + 0.733 + 0.293
handsome = 2.2 + 0.293 + 0.9 * (0.733 + 0.293)
funny = 1.9 + 0.733 + 0.293 + 0.733 + 3 * 0.292  

'''
SMART = 1.7 + 0.733 (C_INCR thru CAPS) + 0.9 * (0.733 + 0.293) (dampened effect of booster on handsome, boosters have effect on next word: 1, second next word: 0.95 and thrid next word: 0.9, with all words included)
FUNNY = 1.9 + 0.733 (C_INCR thru CAPS)
VERY = +C_INCR = 0.293 (B_INCR thru booster word) + 0.733 (C_INCR thru CAPS)
uber = +B_INCR = 0.293 (B_INCR thru booster word)
FRIGGIN = +C_INCR = 0.293 (B_INCR thru booster word) + 0.733 0.733 (C_INCR thru CAPS)
!!! = 3 * 0.292
'''

all_val = [smart, handsome, funny]
print(round(normalize(sum(all_val)), 4))

#%%
list(text.split())


