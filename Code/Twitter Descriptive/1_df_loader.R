df <- vroom("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/En_NoFilter/En_NoFilter_2018-11-30.csv",
            col_types = cols(.default = "c",
              created_at = "c",
              retweets_count = "i",
              likes_count = "i", tweet_length = "i",
              language = "c"))

df$date <- as.Date(df$created_at, "%Y-%m-%d")
