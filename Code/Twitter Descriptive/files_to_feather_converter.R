library(arrow)
library(vroom)

'
In this file we load every csv, convert it to feather and save it again

'

folder <- ""
files <- list.files(folder)







############
###########
#### variant for default column types (when id is not included)
for (file in files){
  ### read csv file
  df <- vroom:vroom(file)
  
  
  ## new filename
  filename_part1 <- strsplit(file, "[.]")[[1]][1]
  filename_new <- glue("{filename_part1}.feather")
  
  ### save as feather
  arrow::write_feather(df, filename_new)
  
  
  
}




########
#######
### for cleaned df where we need all columns in correct format
for (file in files){
  ### read csv file
  df <- vroom:vroom(file.path(file_path_source_cleaned),
                    col_types =  cols_only(
                      doc_id = "c",
                      text = "c",
                      created_at = "D",
                      user_id = "c",
                      username = "c",
                      hashtags = "?",
                      language = "c",
                      retweets_count = "i",
                      likes_count = "i",
                      tweet_length = "i",
                      sentiment = "d"
                    ))
  
  
  
  
  
  ## new filename
  filename_part1 <- strsplit(file, "[.]")[[1]][1]
  filename_new <- glue("{filename_part1}.feather")
  
  ### save as feather
  arrow::write_feather(df, filename_new)
  
}