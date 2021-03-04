library(tidyverse)
library(data.table)
library(glue)







################################################################################
### this is simply for easier switching between vpcl and local
vpc = FALSE

# read in data
if (vpc == T) {
  setwd("/home/lukasbrunner/share/onedrive_new/Data/Twitter")
} else {
  setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
}


source_cleaned_main <- "cleaned"
source_sentiment_main <- "sentiment/Shiny_files"


source_cleaned <- "De_NoFilter"
source_sentiment <- "raw_sentiment"


file_path_source_cleaned <- file.path(source_cleaned_main, source_cleaned)
file_path_source_sentiment <- file.path(source_sentiment_main, source_sentiment)


files_source_cleaned <- list.files(file_path_source_cleaned)
files_source_sentiment <- list.files(file_path_source_sentiment)

#### files in both
files_both <- intersect(files_source_cleaned,
                        files_source_sentiment)




dest_main <- "cleaned_sentiment"
dest <- file.path(dest_main, source_cleaned)


for (file in files_both){
  
  # new feather filename
  # filename
  filename <- strsplit(file, "[.]")[[1]][1]
  filename_feather <- glue("{filename}.feather")
  
  # only if file does not exist already at destination
  if (!(file.exists(file.path(dest, filename_feather))  & (file.exists(file.path(dest, file))))) {
  ### open cleaned
  print(glue("Loading cleaned file: {file}"))
  df_cleaned <- vroom::vroom(file.path(file_path_source_cleaned, file),
                            col_types =  cols_only(
                              doc_id = "c",
                              text = "c",
                             
                              #user_id = "c",
                              username = "c",
                              #hashtags = "?",
                              language = "c",
                              retweets_count = "i",
                              likes_count = "i",
                              tweet_length = "i"
                              ))
  
  #### open sentiment
  print(glue("Loading sentiment file: {file}"))
  df_sentiment <- vroom::vroom(file.path(file_path_source_sentiment, file),
                               col_types = cols_only(
                                 id = "c",
                                 sentiment = "d",
                                 created_at = "D"
                               ))
  
  
  # join the two essentially adding sentiment to cleaned file
  print("Merging files")
  df <- df_cleaned %>% inner_join(df_sentiment, by = c("doc_id" = "id"))
  
  
  # save file
  print(glue("Saving file: {file}"))
  vroom::vroom_write(df,
                    file.path(dest, file), delim = ",")
  

  arrow::write_feather(df, file.path(dest, filename_feather))
  }
  
}




