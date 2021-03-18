df_all <- vroom("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/appended/De_NoFilter_701_813.csv",
                col_types = cols(.default = "c",
                                 created_at = "c",
                                 retweets_count = "i",
                                 likes_count = "i", tweet_length = "i",
                                 language = "c"), delim = ",")




### duplicate rows
df_dups <- df_all[duplicated(df_all$doc_id),]


vroom_write(df_all, delim = ",", "C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/appended/De_NoFilter_701_813_n.csv")



#### go into daily files and do same
df <- vroom::vroom("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/De_NoFilter/De_NoFilter_2020-12-24.csv",
                col_types = readr::cols(.default = "c",
                                 created_at = "c",
                                 retweets_count = "i",
                                 likes_count = "i", tweet_length = "i",
                                 language = "c"), delim = ",")

# drop duplciates
dups <- df[duplicated(df$doc_id), ]
