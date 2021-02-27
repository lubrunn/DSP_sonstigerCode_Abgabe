df <- vroom("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/En_NoFilter/En_NoFilter_2018-11-30.csv",
            col_types = cols(.default = "c",
              created_at = "c",
              retweets_count = "i",
              likes_count = "i", tweet_length = "i",
              language = "c"))

df$date <- as.Date(df$created_at, "%Y-%m-%d")
df <- df %>% rename(date_variable = date, 
                    language_variable = language)




df_abc <- vroom("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/appended/En_NoFilter_all.csv",
            col_types = cols(.default = "c",
                             created_at = "c",
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
