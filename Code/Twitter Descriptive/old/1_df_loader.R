df <- vroom::vroom("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/De_NoFilter/De_NoFilter_2021-02-19.csv",
            col_types = readr::cols(.default = "c",
              created_at = "c",
              retweets_count = "i",
              likes_count = "i", tweet_length = "i",
              language = "c"))

df$date <- as.Date(df$created_at, "%Y-%m-%d")
df <- df %>% rename(date_variable = date, 
                    language_variable = language)




df_abc <- vroom::vroom("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/appended/En_NoFilter/En_NoFilter_101_200_lessCols.csv",
            col_types = readr::cols(.default = "c",
                             date = "c",
                             retweets_count = "i",
                             likes_count = "i", tweet_length = "i",
                             language = "c"), delim = ",")



df <- read_csv("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/En_NoFilter/En_NoFilter_2019-01-01.csv",
            col_types = cols(.default = "c",
                             created_at = "c",
                             retweets_count = "i",
                             likes_count = "i", tweet_length = "i",
                             language = "c"))


new_DF2 <- c[rowSums(is.na(c)) > 0,]

new_DF3 <- a[rowSums(is.na(a)) > 0,]

a <- subset(df, select = c(date, doc_id, text, retweets_count, language, likes_count, tweet_length))







term_freq_test <- read_csv("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/term_freq/En_NoFilter/term_freq_En_NoFilter_2018-12-01_rt_50_li_0_lo_all.csv")


library(tidyverse)

a <- df_abc %>%
  group_by(date) %>%
  summarise(n = n())





##### load sentiment files



df <- data.table::fread("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/sentiment/Shiny_files/raw_sentiment/En_NoFilter_2019-01-01.csv",
                        select = c("id", "created_at", "language", "retweets_count", 
                                   "likes_count", "tweet_length", "sentiment"),
                        colClasses = c("created_at" = "character",
                                       "id" = "character"))

