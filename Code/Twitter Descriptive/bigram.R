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
  unnest_tokens(bigram, text, token = "ngrams", n = 3) %>%
  
count(bigram) %>%
  filter(n >= threshold_pairs) %>%
  arrange(desc(n))








  
  
retweets_filter <- 0
likes_filter <- 0
length_filter <- 0
  

emoji_words_coll <- paste0(emoji_words, collapse = "|")

# no emoji text
uni_bi_tri <- function(){

  bigram <- df %>% 
    filter(
      likes_count >= likes_filter &
        retweets_count >= retweets_filter &
        #long_tweet == long
        tweet_length >= length_filter
    ) %>%
    
    unnest_tokens(ngram, text, token = "ngrams", n = 2) %>%
    group_by(date_variable, language_variable, ngram) %>%
    summarise(n = n()) %>%
    filter(n >= 3) %>%
    pivot_wider(names_from = ngram, values_from =n)%>%
    ungroup() %>%
    #replace_na(list(0)) %>%
    #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
    mutate(
      
      retweets_count = retweets_filter,
      likes_count = likes_filter,
      tweet_length = length_filter
    ) 
  
  
  
  tri <- df %>% 
  filter(
  likes_count >= likes_filter &
    retweets_count >= retweets_filter &
    #long_tweet == long
    tweet_length >= length_filter
  ) %>%
  
  unnest_tokens(ngram, text, token = "ngrams", n = 3) %>%
  group_by(date_variable, language_variable, ngram) %>%
  summarise(n = n()) %>%
  filter(n >= 3) %>%
  pivot_wider(names_from = ngram, values_from =n)%>%
  ungroup() %>%
  #replace_na(list(0)) %>%
  #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
  mutate(
    
    retweets_count = retweets_filter,
    likes_count = likes_filter,
    tweet_length = length_filter
  ) 
  
  
  
  term_frequency <- df %>% filter(
  likes_count >= likes_filter &
    retweets_count >= retweets_filter &
    #long_tweet == long
    tweet_length >= length_filter)%>%
  
  tidytext::unnest_tokens(word, text, to_lower = F) %>%
  group_by(date_variable, language_variable, word) %>%
  summarise(n = n())  %>% 
  filter(n > threshold_single) %>%
  pivot_wider(names_from = word, values_from = n)  %>%
  ungroup() %>%
  #replace_na(list(0)) %>%
  #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
  mutate(
    #across(-c(date_variable, language_variable), ~replace_na(.x, 0)),
    retweets_count = retweets_filter,
    likes_count = likes_filter,
    tweet_length = length_filter
  ) 

}




uni_bi <- function(){
  
  bigram <- df %>% 
    filter(
      likes_count >= likes_filter &
        retweets_count >= retweets_filter &
        #long_tweet == long
        tweet_length >= length_filter
    ) %>%
    
    unnest_tokens(ngram, text, token = "ngrams", n = 2) %>%
    group_by(date_variable, language_variable, ngram) %>%
    summarise(n = n()) %>%
    filter(n >= 3) %>%
    pivot_wider(names_from = ngram, values_from =n)%>%
    ungroup() %>%
    #replace_na(list(0)) %>%
    #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
    mutate(
      
      retweets_count = retweets_filter,
      likes_count = likes_filter,
      tweet_length = length_filter
    ) 
  
  
  

  
  
  term_frequency <- df %>% filter(
    likes_count >= likes_filter &
      retweets_count >= retweets_filter &
      #long_tweet == long
      tweet_length >= length_filter)%>%
    
    tidytext::unnest_tokens(word, text, to_lower = F) %>%
    group_by(date_variable, language_variable, word) %>%
    summarise(n = n())  %>% 
    filter(n > threshold_single) %>%
    pivot_wider(names_from = word, values_from = n)  %>%
    ungroup() %>%
    #replace_na(list(0)) %>%
    #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
    mutate(
      #across(-c(date_variable, language_variable), ~replace_na(.x, 0)),
      retweets_count = retweets_filter,
      likes_count = likes_filter,
      tweet_length = length_filter
    ) 
  
}




uni <- function(){
  
  
  
  
  
  term_frequency <- df %>% filter(
    likes_count >= likes_filter &
      retweets_count >= retweets_filter &
      #long_tweet == long
      tweet_length >= length_filter)%>%
    
    tidytext::unnest_tokens(word, text, to_lower = F) %>%
    group_by(date_variable, language_variable, word) %>%
    summarise(n = n())  %>% 
    filter(n > threshold_single) %>%
    pivot_wider(names_from = word, values_from = n)  %>%
    ungroup() %>%
    #replace_na(list(0)) %>%
    #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
    mutate(
      #across(-c(date_variable, language_variable), ~replace_na(.x, 0)),
      retweets_count = retweets_filter,
      likes_count = likes_filter,
      tweet_length = length_filter
    ) 
  
}



uni_pair <- function(){
  pairs_df <- df %>%
    filter(
      likes_count >= likes_filter &
        retweets_count >= retweets_filter &
        #long_tweet == long
        tweet_length >= length_filter)%>%
    
    unnest_tokens(word, text) %>%
    group_by(date_variable, language_variable) %>%
    # show all pairs out of all pairs per tweet
    # feel so forgoten that --> feel so, feel forgotten, feel that, so feel, so forgotten, so that etc.
    widyr::pairwise_count(word, doc_id, sort = T) %>%
    rename("weight" = n) %>%
    filter(weight > threshold_pairs)
  
  
  #remove rows that are the same but item1 and item2 are reversed
  pairs_df <- pairs_df[!duplicated(t(apply(pairs_df,1,sort))),]
  
  # collapse both words
  pairs_df$pairs <- paste(pairs_df$item1,pairs_df$item2, sep = ", ")
  pairs_df <-  pairs_df %>% select(pairs, n = weight) %>%
    pivot_wider(names_from = pairs, values_from = n) %>%
    ungroup %>%
    replace(is.na(.), 0) %>%
    mutate(retweets_count = retweets_filter,
           likes_count = likes_filter,
           tweet_length = length_filter)
  
  
  
  
  term_frequency <- df %>% filter(
    likes_count >= likes_filter &
      retweets_count >= retweets_filter &
      #long_tweet == long
      tweet_length >= length_filter)%>%
    
    tidytext::unnest_tokens(word, text, to_lower = F) %>%
    group_by(date_variable, language_variable, word) %>%
    summarise(n = n())  %>% 
    filter(n > threshold_single) %>%
    pivot_wider(names_from = word, values_from = n)  %>%
    ungroup() %>%
    #replace_na(list(0)) %>%
    #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
    mutate(
      #across(-c(date_variable, language_variable), ~replace_na(.x, 0)),
      retweets_count = retweets_filter,
      likes_count = likes_filter,
      tweet_length = length_filter
    ) 
}



microbenchmark::microbenchmark(uni_bi_tri(), uni_bi(), uni(), uni_pair(), times = 1)

test_count <- function(){
df %>%
  unnest_tokens(ngram, text, token = "ngrams", n = 2) %>%
  #group_by(date_variable, language_variable) %>%
  count(ngram)
}

test_sum <- function(){
  df %>%
    unnest_tokens(ngram, text, token = "ngrams", n = 2) %>%
    group_by(date_variable, language_variable, ngram) %>%
    summarise(n = n())
}

microbenchmark::microbenchmark(test_count(), test_sum(), times = 3)








# try to speed up bigram
time1 <- Sys.time()
bigram <- df %>% 
  filter(
    likes_count >= likes_filter &
      retweets_count >= retweets_filter &
      #long_tweet == long
      tweet_length >= length_filter
  ) %>%
  
  unnest_tokens(ngram, text, token = "ngrams", n = 2) %>%
  group_by(date_variable, language_variable, ngram) %>%
  summarise(n = n()) %>%
  filter(n >= 3) %>%
  pivot_wider(names_from = ngram, values_from =n)%>%
  ungroup() %>%
  #replace_na(list(0)) %>%
  #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
  mutate(
    
    retweets_count = retweets_filter,
    likes_count = likes_filter,
    tweet_length = length_filter
  ) 

Sys.time() - time1




library(data.table)
#### with datatable
time1 <- Sys.time()
tokens <- df %>% 
  filter(
    likes_count >= likes_filter &
      retweets_count >= retweets_filter &
      #long_tweet == long
      tweet_length >= length_filter
  ) %>%
  
  unnest_tokens(ngram, text, token = "ngrams", n = 2) 
  
# turn into datatable
dt <- data.table::as.data.table(tokens)
# aggregate
dt <- dt[,.(.N), by = c("date_variable","language_variable", "ngram")]
# filter
dt <- dt[N > threshold_pairs & !is.na(ngram),]
# spread
dt2  <- dcast(dt, ... ~ ngram , value.var = "N")




dt2$retweets_count <- retweets_filter
dt2$likes_count <- likes_filter
dt2$tweet_length <- length_filter

# saving
Sys.time() - time1



# with dplyr


time1 <- Sys.time()
term_frequency <- df %>% filter(
  likes_count >= likes_filter &
    retweets_count >= retweets_filter &
    #long_tweet == long
    tweet_length >= length_filter)%>%
  
  tidytext::unnest_tokens(word, text, to_lower = F) %>%
  group_by(date_variable, language_variable, word) %>%
  summarise(n = n())  %>% 
  filter(n > threshold_single) %>%
  pivot_wider(names_from = word, values_from = n)  %>%
  ungroup() %>%
  #replace_na(list(0)) %>%
  #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
  mutate(
    #across(-c(date_variable, language_variable), ~replace_na(.x, 0)),
    retweets_count = retweets_filter,
    likes_count = likes_filter,
    tweet_length = length_filter
  ) 

Sys.time()- time1




dt_test <- function(){
tokens <- df %>% 
  filter(
    likes_count >= likes_filter &
      retweets_count >= retweets_filter &
      #long_tweet == long
      tweet_length >= length_filter
  ) %>%
  
  unnest_tokens(word, text, to_lower = F) 

# turn into datatable
dt <- data.table::as.data.table(tokens)
# aggregate
dt <- dt[,.(.N), by = c("date_variable","language_variable", "word")]
# filter
dt <- dt[N > threshold_single & !is.na(word),]
# spread
dt2  <- dcast(dt, ... ~ word , value.var = "N")




dt2$retweets_count <- retweets_filter
dt2$likes_count <- likes_filter
dt2$tweet_length <- length_filter
fwrite(dt2, "C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/term_freq/test.csv")

}


dplyr_test <- function(){
df <-  df %>% filter(
    likes_count >= likes_filter &
      retweets_count >= retweets_filter &
      #long_tweet == long
      tweet_length >= length_filter)%>%
    
    tidytext::unnest_tokens(word, text, to_lower = F) %>%
    group_by(date_variable, language_variable, word) %>%
    summarise(n = n())  %>%
    filter(n > threshold_single) %>%
    pivot_wider(names_from = word, values_from = n)  %>%
    ungroup() %>%
    #replace_na(list(0)) %>%
    #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
    mutate(
      #across(-c(date_variable, language_variable), ~replace_na(.x, 0)),
      retweets_count = retweets_filter,
      likes_count = likes_filter,
      tweet_length = length_filter
    )
vroom_write(df, "C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/term_freq/test.csv", delim = ",")
}


microbenchmark::microbenchmark(dt_test(), dplyr_test(), times = 5)



#### remove emoji words
dt_noemo <- dt[!word %in% emoji_words]
