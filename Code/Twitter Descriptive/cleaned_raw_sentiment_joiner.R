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
source_raw_main <- "raw_csv"
source_sentiment_main <- "sentiment/Shiny_files"

#sources_cleaned <- c("De_NoFilter", "En_NoFilter")

#for  (source_cleaned in sources_cleaned){
source_cleaned <- "En_NoFilter"
#source_raw <- "De_NoFilter"
source_raw <- source_cleaned
source_sentiment <- "raw_sentiment"



file_path_source_cleaned <- file.path(source_cleaned_main, source_cleaned)
file_path_source_raw <- file.path(source_raw_main, source_raw)
file_path_source_sentiment <- file.path(source_sentiment_main, source_sentiment)


files_source_cleaned <- list.files(file_path_source_cleaned)
files_source_raw <- list.files(file_path_source_raw)
files_source_sentiment <- list.files(file_path_source_sentiment)

#### files in both
files_all <- intersect(intersect(files_source_cleaned,
                                 files_source_sentiment), files_source_raw)




dest_main <- "cleaned_raw_sentiment"
dest <- file.path(dest_main, source_cleaned)
files_dest <- list.files(dest)


for (file in files_all){
  
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
    
    
    df_raw <- vroom::vroom(file.path(file_path_source_raw, file),
                           col_types = cols_only(id = "c",
                                                 tweet = "c"))
    
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
    df <- df_cleaned %>% inner_join(df_sentiment, by = c("doc_id" = "id")) %>% inner_join(df_raw, by = c("doc_id" = "id"))
    
    
    #### drop where text is missing or ""
    df <- df %>% na.omit() %>% filter(text != "")
    
    # save file
    print(glue("Saving file: {file}"))
    vroom::vroom_write(df,
                       file.path(dest, file), delim = ",")
    
    
    arrow::write_feather(df, file.path(dest, filename_feather))
  }
  
}

#}


###########################################
###########################################
################################ for companies
source_cleaned_main <- "cleaned"
source_raw_main <- "raw_csv"
source_sentiment_main <- "sentiment/Shiny_files_companies"


source_cleaned <- "Companies2"
source_raw <- "Companies"
source_sentiment <- "raw_sentiment_en_de"

# list of all commpanies
subfolders <- list.files(file.path(source_cleaned_main, source_cleaned))

# where to save files, main folder
dest_main <- "cleaned_raw_sentiment"
#dest_main = "C:/Users/lukas/Documents/Uni/Data Science Project/data_temp"

for (subfolder in subfolders) {
  print(glue("Wroking on {subfolder}"))
  # list files that exist in each folder
  files_source_cleaned <- list.files(file.path(source_cleaned_main, source_cleaned, subfolder))
  files_source_raw <- list.files(file.path(source_raw_main, source_raw, subfolder))
  files_source_sentiment <- list.files(file.path(source_sentiment_main, source_sentiment, subfolder))
  
  #### files in all
  files_all <- intersect(intersect(files_source_cleaned,
                                   files_source_sentiment), files_source_raw)
  
  
  # path of subfolder
  dest <- file.path(dest_main, source_raw, subfolder)
  # create folder if doesnt exist
  dir.create(dest)
  
  
  i <- 0
  for (file in files_all){
    
    
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
      
      
      df_raw <- read_csv(file.path(source_raw_main, source_raw, subfolder, file),
                         col_types = cols_only(id = "c",
                                               tweet = "c"))
      
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
      df <- df_cleaned %>% inner_join(df_sentiment, by = c("doc_id" = "id", "language" ="language")) %>% 
        inner_join(df_raw, by = c("doc_id" = "id"))
      
      
      
      
      #### drop where text is missing or ""
      df <- df %>% na.omit() %>% filter(text != "")
      
      # save file
      # print(glue("Saving file: {file}"))
      readr::write_csv(df,
                       file.path(dest, file))
      
      
      #arrow::write_feather(df, file.path(dest, filename_feather))
      
     
    }
    
  }
  
  
  
  
}














