import nltk
nltk.download('vader_lexicon')
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import pandas as pd
def get_sentiment(text):
    sentiment = pd.DataFrame([sid_obj.polarity_scores(text)])
    return sentiment["compound"]

import numpy as np
#%%

sid_obj = SentimentIntensityAnalyzer()
get_sentiment("VADER is smart, handsome, and funny")

#%%
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
first = np.array([smart, handsome, funny, is_word, VADER, and_word])
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


# convert emojis to their textual descriptions
text_no_emoji = ""
prev_space = True
for chr in text:
    if chr in self.emojis:
        # get the textual description
        description = self.emojis[chr]
        if not prev_space:
            text_no_emoji += ' '
        text_no_emoji += description
        prev_space = False
    else:
        text_no_emoji += chr
        prev_space = chr == ' '
text = text_no_emoji.strip()

sentitext = SentiText(text)

sentiments = []
words_and_emoticons = sentitext.words_and_emoticons
for i, item in enumerate(words_and_emoticons):
    valence = 0
    # check for vader_lexicon words that may be used as modifiers or negations
    if item.lower() in BOOSTER_DICT:
        sentiments.append(valence)
        continue
    if (i < len(words_and_emoticons) - 1 and item.lower() == "kind" and
            words_and_emoticons[i + 1].lower() == "of"):
        sentiments.append(valence)
        continue

    sentiments = self.sentiment_valence(valence, sentitext, item, i, sentiments)

sentiments = self._but_check(words_and_emoticons, sentiments)

valence_dict = self.score_valence(sentiments, text)

return valence_dict
        


#%%
lexicon_full_filepath = r"C:\Users\lukas\Documents\Uni\Data Science Project\Python\Sentiment Analysis\vaderSentiment-master\vaderSentiment\vader_lexicon.txt"

for line in lexicon_full_filepath.rstrip('\n').split('\n'):
            if not line:
                continue
            (word, measure) = line.strip().split('\t')[0:2]
            lex_dict[word] = float(measure)
            
            
