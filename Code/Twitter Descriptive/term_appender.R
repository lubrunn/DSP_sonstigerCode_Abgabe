
library(vroom)
library(glue)
library(tidyverse)






################################################################################
### this is simply for easier switching between vpcl and local
vpc = FALSE

# read in data
if (vpc == T) {
  setwd("/home/lukasbrunner/share/onedrive_new/Data/Twitter")
} else {
  setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
}



source_main <- "term_freq"

folders_main <- c("En_NoFilter", "De_NoFilter")
folders_main <- folders_main[1]


likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)

#### process for nofilter folders
for (folder in folders_main){
  folders_sub <- list.files(file.path(source_main, folder))
  
  for (subfolder in folders_sub[!grepl("appended", folders_sub)]){
    
    # list all files
    files <- list.files(file.path(source_main, folder, subfolder))
  
  for (retweets_filter in retweets_list){
    for(likes_filter in likes_list){
      for(length_filter in long_list){
        # check which name to five file
        if (length_filter == 81){
          long_name <- "long_only"
        } else{
          long_name <- "all"
        }
        
        add_on <- glue("rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}")
        # check all files that have this addon
        selected_files <-  files[grepl(add_on, files)] 
        
        # create new file name
        new_filename <- glue("{subfolder}_{folder}_{add_on}.csv")
        # destination
        dest <- file.path(source_main,folder, glue("{subfolder}_appended"),new_filename )
        
        # check if filename alreday exists at destination
        if(!file.exists(dest)){
          print(glue("Working on {new_filename}"))
          time1 <- Sys.time()
          # read all files and append
          df_all <- NULL
          for (selected_file in selected_files){
            df <- data.table::fread(file.path(source_main, folder, subfolder, selected_file), sep = ",") %>%
              rename(date = date_variable, language = language_variable)
            if (is.null(df_all)){
              df_all <- df
            } else {
              df_all <- bind_rows(df_all,df)
            }
          }
          
          
          print(glue("Saving {new_filename}"))
          vroom_write(df_all, dest, delim =",")
          print(Sys.time() - time1)
        
        
        } else{ # if clause
        print(glue("{new_filename} already exists"))
          }
        
        
      }
        
      }
    }
  }
}



