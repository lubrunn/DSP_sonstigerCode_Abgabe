setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/sentiment/Shiny_files/raw_sentiment")

senti <- readr::read_csv("En_NoFilter_2018-11-30.csv",
                         col_types = cols(.default = "c",
                                          retweets_count = "i",
                                          likes_count = "i",
                                          tweet_length = "i",
                                          sentiment = "d"))



senti$long_tweet <- ifelse(senti$tweet_length > 80, 1, 0)
senti$date <- "2018-11-30"

a <- senti %>%
  select(date, retweets_count, likes_count, long_tweet, sentiment) %>%
  filter(retweets_count <= 100, likes_count <= 100) %>%
  group_by(likes_count, retweets_count, long_tweet) %>%
    summarise(sum_senti = sum(sentiment),
              n = n())




senti %>%
  filter(retweets_count > 5) %>%
ggplot2::ggplot() +
  geom_histogram(aes(sentiment))



