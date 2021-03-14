library(tidyverse)
library(glue)

####### first go into each folder:
  # cleaned
  # sentiment_daily
  # raw_csv


### then get all filenames
### check latest date
### take minimum latest date of all three

### then go to destination cleaned_raw_sentimetn
### get all filenames
### check latest date


### get list of dates between latest at source and latest at destination

### for these missing files load all three files from source
### join them, convert created_at to date, drop all with missing text








################################################################################
### this is simply for easier switching between vpcl and local
vpc = FALSE

# read in data
if (vpc == T) {
  setwd("/home/lukasbrunner/share/onedrive_new2/Data/Twitter")
} else {
  setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
} 


source_cleaned_main <- "cleaned"
source_raw_main <- "raw_csv"
source_sentiment_main <- "sentiment_daily"
dest_main <- "cleaned_raw_sentiment"




folders_dest <- c("Companies", "En_NoFilter", "De_NoFilter")

for (folder in folders_dest){
  print(glue("Working on {folder}"))
  
  if (grepl("Companies", folder)){
    ### list all subfolders
    subfolders <- list.files(file.path(dest_main, folder))
    
    #### for each company folder
    for (subfolder in subfolders){
      print(glue("Working on {subfolder}"))
    
      ##### list all files in the each source folder
      files_source_cleaned <- list.files(file.path(source_cleaned_main, "Companies2", subfolder))
      files_source_raw <- list.files(file.path(source_raw_main, folder, subfolder))
      files_source_sentiment <- list.files(file.path(source_sentiment_main, folder,subfolder))
      
      
      ##### list files that are available in all three sources
      files_all <- intersect(intersect(files_source_cleaned,
                                       files_source_sentiment), files_source_raw)
      
      
      ##### check lattest date
      last_date_avail <- max(parsedate::parse_date(files_all))
      
      
      #### now check what is latest update at destination
      
      ### list all files
      files_all_dest <- list.files(file.path(dest_main, folder, subfolder))
      if (is_empty(files_all_dest)){
        last_update <- as.Date("2018-11-29")
      } else {
        last_update <- max(parsedate::parse_date(files_all_dest))
      }
      
      ####### find dates that still need to be updated
      #### check if lastupdate actually smaller then last date avail
      if (as.Date(last_update) < as.Date(last_date_avail)) {
        dates_missing <- seq(as.Date(last_update) + lubridate::days(1) , as.Date(last_date_avail), by="days")
      } else {
        ##### if up to date move on to next loop
        print("no missing dates found")
        next 
      }
      
      
      ### get missing files
      ### only start process for files that are missing
      files_missing <- files_all[grepl(paste(dates_missing,collapse = "|"), files_all)]
      
      ### now for all files that are missing join all three sources and save to destinaiton
      for (file in files_missing){
        
        #### double check if does not already exist
        if (!file.exists(file.path(dest_main, folder, subfolder, file))){
          print(glue("Updating {file}"))
          df_cleaned <- read_csv(file.path(source_cleaned_main,"Companies2", subfolder, file),
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
          
          
          df_raw <- read_csv(file.path(source_raw_main, "Companies", subfolder, file),
                             col_types = cols_only(id = "c",
                                                   tweet = "c"))
          
          #### open sentiment
          #print(glue("Loading sentiment file: {file}"))
          df_sentiment <- read_csv(file.path(source_sentiment_main, "Companies", subfolder, file),
                                   col_types = cols_only(
                                     id = "c",
                                     sentiment = "d",
                                     created_at = "c",
                                     language = "c"
                                   ))
          
          #### convert to date
          df_sentiment$created_at <- as.Date(df_sentiment$created_at)
          
          # join the two essentially adding sentiment to cleaned file
          # print("Merging files")
          df <- df_cleaned %>% inner_join(df_sentiment, by = c("doc_id" = "id", "language" ="language")) %>% 
            inner_join(df_raw, by = c("doc_id" = "id"))
          
          
          
          
          #### drop where text is missing or ""
          df <- df %>% na.omit() %>% filter(text != "")
          
          # save file
          # print(glue("Saving file: {file}"))
          write.table(df, file.path(dest_main,folder,subfolder, file),
                      append = T, sep = ",",
                      row.names = F, col.names = F)
          
          
          
          
        }
        
        
        
      }
    }
     
  } else { ### for nofilter folders
    ##### list all files in the each source folder
    files_source_cleaned <- list.files(file.path(source_cleaned_main, folder))
    files_source_raw <- list.files(file.path(source_raw_main, folder))
    files_source_sentiment <- list.files(file.path(source_sentiment_main, folder))
    
    
    ##### list files that are available in all three sources
    files_all <- intersect(intersect(files_source_cleaned,
                                     files_source_sentiment), files_source_raw)
    
    
    ##### check lattest date
    last_date_avail <- max(parsedate::parse_date(files_all))
    
    
    #### now check what is latest update at destination
    
   
    ### list all files
    files_all_dest <- list.files(file.path(dest_main, folder))
    if (is_empty(files_all_dest)){
      last_update <- as.Date("2018-11-29")
    } else {
      last_update <- max(parsedate::parse_date(files_all_dest))
    }
    
    ####### find dates that still need to be updated
    #### check if lastupdate actually smaller then last date avail
    if (as.Date(last_update) < as.Date(last_date_avail)) {
      dates_missing <- seq(as.Date(last_update) + lubridate::days(1) , as.Date(last_date_avail), by="days")
    } else {
      ##### if up to date move on to next loop
      print("no missing dates found")
      next 
    }
    
    ### get missing files
    ### only start process for files that are missing
    files_missing <- files_all[grepl(paste(dates_missing,collapse = "|"), files_all)]
    
    ### now for all files that are missing join all three sources and save to destinaiton
    for (file in files_missing){
      
      #### double check if does not already exist
      if (!file.exists(file.path(dest_main, folder, subfolder, file))){
        print(glue("Updating {file}"))
        
        df_cleaned <- readr::read_csv(file.path(source_cleaned_main,folder, file),
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
        
        
        df_raw <- readr::read_csv(file.path(source_raw_main,folder, file),
                           col_types = cols_only(id = "c",
                                                 tweet = "c"))
        
        #### open sentiment
        #print(glue("Loading sentiment file: {file}"))
        df_sentiment <- readr::read_csv(file.path(source_sentiment_main,folder, file),
                                 col_types = cols_only(
                                   id = "c",
                                   sentiment = "d",
                                   created_at = "c",
                                   language = "c"
                                 ))
        
        #### convert to date
        df_sentiment$created_at <- as.Date(df_sentiment$created_at)
        
        # join the two essentially adding sentiment to cleaned file
        # print("Merging files")
        df <- df_cleaned %>% inner_join(df_sentiment, by = c("doc_id" = "id", "language" ="language")) %>% 
          inner_join(df_raw, by = c("doc_id" = "id"))
        
        
        
        
        #### drop where text is missing or ""
        df <- df %>% na.omit() %>% filter(text != "")
        
        # save file
        # print(glue("Saving file: {file}"))
        write.table(df, file.path(dest_main,folder, file),
                    append = T, sep = ",",
                    row.names = F, col.names = F)
        
        
        
        
      }
      
      
      
    }
  }
  
  
  
}





