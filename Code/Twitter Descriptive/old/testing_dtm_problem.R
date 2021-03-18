
# c contains data from appended dataset
df_app <- vroom("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/appended/En_NoFilter/En_NoFilter_1_100_lessCols.csv",
                col_types = cols(.default = "c",
                                 date = "c",
                                 retweets_count = "i",
                                 likes_count = "i", tweet_length = "i",
                                 language = "c"), delim = ",")

# df contains data from single day dataset
df_single_app <- df_app %>% filter(date == "2018-11-30")






##################################
df_single <- vroom("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/En_NoFilter/En_NoFilter_2018-11-30.csv",
            col_types = cols(.default = "c",
                             created_at = "c",
                             retweets_count = "i",
                             likes_count = "i", tweet_length = "i",
                             language = "c"))

df_single$date <- as.Date(df_single$created_at, "%Y-%m-%d")




# find rows that are not the same (text is not the same)
df_dif_app <- df_single_app[!df_single_app$text == df_single$text,]

df_dif <- df_single[!df_single_app$text == df_single$text,]

df_na <- df_single %>% filter(is.na(text))

df_na_app <- df_single_app %>% filter(is.na(text))






threshold_single <- 0

retweets_filter <- 2000
likes_filter <- 2000
length_filter <- 10


term_frequency2 <- df_single %>% 
  rename(date_variable = date, 
         language_variable = language) %>%
    filter(
  likes_count >= likes_filter &
    retweets_count >= retweets_filter &
    #long_tweet == long
    tweet_length >= length_filter)%>%
  
  tidytext::unnest_tokens(word, text) %>%
  group_by(date_variable, language_variable, word) %>%
  summarise(n = n())  %>% 
  filter(n > threshold_single) %>%
  pivot_wider(names_from = word, values_from = n)  %>%
  ungroup() %>%
  #replace_na(list(0)) %>%
  #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
  mutate(retweets_count = retweets_filter,
         likes_count = likes_filter,
         tweet_length = length_filter
         #across(everything(), ~replace_na(.x, 0))
         ) 
