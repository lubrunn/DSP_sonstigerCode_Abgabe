
library(tidytext)
setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")

# read data
df <- df <- readr::read_csv(file.path("cleaned/En_NoFilter" ,glue("En_NoFilter_2018-11-30.csv")),
                            col_types = cols(.default = "c",text = "c",
                                             created_at = "c",
                                             retweets_count = "i",
                                             long = "i", lat = "i",
                                             likes_count = "i", tweet_length = "i"))


  
  
  '
gives nice overview of all possible word combinations in a day
bigramm:
  shows only word combinations moving forward
here:
  shows all bigrams from a sentence --> backwards and skipping words

example: "I am lukas and like R"
bigram:
  "I am", "am lukas", "lukas and" etc.
herre:
  "I am", "I lukas", ... , "I R", "am I", "am lukas", etc.
  
pro bigram:
  - uebersichtlicher da weniger
pro here:
  - mehr connections, man sieht connection in beide Richtungen und sieht auch Beziehungen von Woertern die nicht direkt nacheinander kommen
con bigram:
  - nur consecutive bigram und nicht backwards --> missing info
con here:
  - kann unübersichtlich werden, wenn man es nicht richtig einstellt --> mehr requirements an User oder preprocess
  
'
  # approximate threshold
  threshold <- as.integer(0.001 * dim(df)[1])
  # put every single word into new column, so one row per word in tweet
  network_df <- df %>%
    unnest_tokens(word, text) %>%
  
  # show all pairs out of all pairs per tweet
  # feel so forgoten that --> feel so, feel forgotten, feel that, so feel, so forgotten, so that etc.
  widyr::pairwise_count(word, doc_id, sort = T) %>%
  rename("weight" = n) %>%
  filter(weight > threshold)
 
  
  #remove rows that are the same but item1 and item2 are reversed
  network_df <- network_df[!duplicated(t(apply(network_df,1,sort))),]
  
  # collapse both words
  network_df$pairs <- paste(network_df$item1, network_df$item2, sep = ", ")
  network_df <-  network_df %>% select(pairs, n = weight)
  




