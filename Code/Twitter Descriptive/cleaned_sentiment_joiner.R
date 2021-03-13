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
#################################################################################

source_cleaned_main <- "cleaned"
source_sentiment_main <- "sentiment/Shiny_files"


source_cleaned <- "De_NoFilter"
source_sentiment <- "raw_sentiment_de"


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




###########################################
###########################################
################################ for companies
source_cleaned_main <- "cleaned"
source_sentiment_main <- "sentiment/Shiny_files_companies"


source_cleaned <- "Companies2"
source_sentiment <- "raw_sentiment_en_de"

subfolders <- list.files(file.path(source_cleaned_main, source_cleaned))[8:60]

# where to save files, main folder
dest_main <- "cleaned_sentiment"
dest_main = "C:/Users/lukas/Documents/Uni/Data Science Project/data_temp"

for (subfolder in subfolders) {
  print(glue("Wroking on {subfolder}"))
  # list files that exist in each folder
  files_source_cleaned <- list.files(file.path(source_cleaned_main, source_cleaned, subfolder))
  files_source_sentiment <- list.files(file.path(source_sentiment_main, source_sentiment, subfolder))
  
  #### files in both
  files_both <- intersect(files_source_cleaned,
                          files_source_sentiment)
  
  
  # path of subfolder
  dest <- file.path(dest_main, source_cleaned, subfolder)
  # create folder if doesnt exist
  dir.create(dest)
  
  
  i <- 0
  for (file in files_both){
    
   
    if (i %% 100 == 0){
      print(i)
    }
    i <- i + 1
    
    # new feather filename
    # filename
    filename <- strsplit(file, "[.]")[[1]][1]
    filename_feather <- glue("{filename}.feather")
    
    # only if file does not exist already at destination
    if (!(file.exists(file.path(dest, filename_feather))  & (file.exists(file.path(dest, file))))) {
      ### open cleaned
      #print(glue("Loading cleaned file: {file}"))
      df_cleaned <- read_csv(file.path(source_cleaned_main,source_cleaned, subfolder, file),
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
      #print(glue("Loading sentiment file: {file}"))
      df_sentiment <- read_csv(file.path(source_sentiment_main, source_sentiment, subfolder, file),
                                   col_types = cols_only(
                                     id = "c",
                                     sentiment = "d",
                                     created_at = "c",
                                     language = "c"
                                   ))
      
      df_sentiment$created_at <- as.Date(df_sentiment$created_at)
      
      # join the two essentially adding sentiment to cleaned file
      # print("Merging files")
      df <- df_cleaned %>% inner_join(df_sentiment, by = c("doc_id" = "id", "language" ="language"))
      
      
      # save file
      # print(glue("Saving file: {file}"))
      fwrite(df,
             file.path(dest, file), sep = ",")
      
      
      arrow::write_feather(df, file.path(dest, filename_feather))
      
      Sys.sleep(2)
    }
    
  }
  
  
  
  
}














