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
source_longlat_main <- "coords"


sources_cleaned <- c("De_NoFilter", "En_NoFilter")

for  (source_cleaned in sources_cleaned){
  #source_cleaned <- "En_NoFilter"
  #source_raw <- "De_NoFilter"
  source_longlat <- source_cleaned
  
  
  
  
  file_path_source_cleaned <- file.path(source_cleaned_main, source_cleaned)
  file_path_source_longlat <- file.path(source_longlat_main, source_longlat)
  
  
  
  files_source_cleaned <- list.files(file_path_source_cleaned)
  files_source_longlat <- list.files(file_path_source_longlat)
  
  #### files in both
  files_all <- intersect(files_source_cleaned, files_source_longlat)
  
  
  
  
  dest_main <- "coords/joined"
  dest <- file.path(dest_main, source_cleaned)
  files_dest <- list.files(dest)
  
  files_missing <- files_all[!files_all %in% files_dest]
  
  
  for (file in files_missing){
    
    # new feather filename
    # filename
    filename <- strsplit(file, "[.]")[[1]][1]
    
    filename_feather <- glue("{filename}.feather")
    
    # only if file does not exist already at destination
    if (!(file.exists(file.path(dest, filename_feather))  & (file.exists(file.path(dest, file))))) {
      ### open cleaned
      print(glue("Loading cleaned file: {file}"))
      df_cleaned <- readr::read_csv(file.path(file_path_source_cleaned, file),
                                    col_types =  cols_only(
                                      doc_id = "c",
                                      tweet_length = "i"
                                    ))
      
      
      df_longlat <-readr::read_csv(file.path(file_path_source_longlat, file),
                                   col_types = cols_only(id = "c",
                                                         date = "D",
                                                         language = "c",
                                                         retweets_count = "i",
                                                         likes_count = "i",
                                                         lat = "d",
                                                         long = "d"))
      
      
      
      
      
      
      # join the two essentially adding sentiment to cleaned file
      print("Merging files")
      df <- df_cleaned %>% right_join(df_longlat, by = c("doc_id" = "id"))
      
      
      
      
      # save file
      print(glue("Saving file: {file}"))
      readr::write_csv(df,
                       file.path(dest, file))
      
      
    }
    
  }
  
}


###########################################
###########################################
################################ for companies







source_cleaned_main <- "cleaned"
source_longlat_main <- "coords"





dest_main <- "coords/joined"


source_cleaned <- "Companies2"
source_longlat <- "Companies"


# list of all commpanies
subfolders <- list.files(file.path(source_cleaned_main, source_cleaned))

# where to save files, main folder

#dest_main = "C:/Users/lukas/Documents/Uni/Data Science Project/data_temp"

for (subfolder in subfolders) {
  print(glue("Wroking on {subfolder}"))
  # list files that exist in each folder
  files_source_cleaned <- list.files(file.path(source_cleaned_main, source_cleaned, subfolder))
  files_source_longlat <- list.files(file.path(source_longlat_main, source_longlat, subfolder))
  
  #### files in all
  files_all <- intersect(files_source_cleaned, files_source_longlat)
  
  
  # path of subfolder
  dest <- file.path(dest_main, source_longlat, subfolder)
  # create folder if doesnt exist
  dir.create(dest)
  
  # find missing files
  files_dest <- list.files(dest)
  files_missing <- files_all[!files_all %in% files_dest]
  
  
  i <- 0
  for (file in files_missing){
    
    
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
      df_cleaned <- readr::read_csv(file.path(source_cleaned_main,source_cleaned, subfolder, file),
                                    col_types =  cols_only(
                                      doc_id = "c",
                                      tweet_length = "i"
                                    ))
      
      
      df_longlat <- readr::read_csv(file.path(source_longlat_main,source_longlat, subfolder, file),
                                    col_types = cols_only(id = "c",
                                                          date = "D",
                                                          language = "c",
                                                          retweets_count = "i",
                                                          likes_count = "i",
                                                          lat = "d",
                                                          long = "d"))
      
      
      
      
      # join the two essentially adding sentiment to cleaned file
      # print("Merging files")
      df <- df_cleaned %>% right_join(df_longlat, by = c("doc_id" = "id"))
      
      
      
      
      
      
      # save file
      # print(glue("Saving file: {file}"))
      readr::write_csv(df,
                       file.path(dest, file))
      
      
      
      
      #Sys.sleep(1.5)
    }
    
  }
  
  
  
  
}














