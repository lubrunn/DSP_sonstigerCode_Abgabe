setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/appended")

files <- list.files()[2:9]

for (file in files){
  gc()
  df <- vroom(file,
        col_types = cols_only(doc_id = "c",text = "c",
                              user_id = "c",
                              username = "c",
                              date = "c",
                              retweets_count = "i",
                              language = "c",
                              likes_count = "i", tweet_length = "i"),
        delim = ",")
  
  file <- glue("{strsplit(file, '[.]')[[1]][1]}_lessCols.csv")
  vroom_write(df, file, delim = ",")
  
}
names(df)
