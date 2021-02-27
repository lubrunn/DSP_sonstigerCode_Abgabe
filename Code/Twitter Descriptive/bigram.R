library(tidyverse)
library(tidytext)
df <- vroom("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/En_NoFilter/En_NoFilter_2018-11-30.csv",
            col_types = cols(.default = "c",
                             created_at = "c",
                             retweets_count = "i",
                             likes_count = "i", tweet_length = "i",
                             language = "c"))

df$date <- as.Date(df$created_at, "%Y-%m-%d")


time3 <- Sys.time()
bigrams <- df %>% unnest_tokens(word, text, token = "ngrams", n = 2) %>% 
  separate(word, c("word1", "word2"), sep = " ") %>%
  unite(words,word1, word2, sep = ", ") %>% 
  count(word)
Sys.time() - time3


bigrams2 <- df %>%
  unnest_tokens(bigram, text, token = "ngrams", n = 2) %>%
count(bigram)


install.packages("quanteda")
library(quanteda)

toks <- tokens(df$text)
toks_ngram <- tokens_ngrams(toks, 2)

head(toks_ngram[[2]], 30)
