
'
Here we write a function that goes through a main model and appends for each subfolder the files fo each day into on big csv
this csv will be used for sql, term_freq calc, histogram calc and maybe more
'



#################################################################################
#################################################################################
############################# packages ##########################################
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

################################################################################
source_main <- "cleaned"





# function that open each file and appends them together and then saves appended file
appender <- function(files, source, dest, folder, companies = F){
  df_all <- NULL
  for (file in files){
    df <- read_csv(file.path(source, file),
                   col_types = cols(.default = "c",text = "c",
                                         created_at = "c",
                                         retweets_count = "i",
                                          long = "i", lat = "i",
                                         likes_count = "i", tweet_length = "i")) 
    
    # convert created at to date
    df$date <- as.Date(df$created_at, "%Y-%m-%d")
    
    
    # for company folder add the company name as column in order to be later able to filter for company names
    # for Johnson & Johnson change name
    if (folder == "JohnsonJohnson"){
      df$company <- "Johnson & Johnson"
    } else {
      # replace umlaute
      company_name <- stringi::stri_replace_all_fixed(
        folder, 
        c("ä", "ö", "ü", "Ä", "Ö", "Ü"), 
        c("ae", "oe", "ue", "Ae", "Oe", "Ue"), 
        vectorize_all = FALSE
      )
      df$company <- company_name
    }
    
    # if first file in loop set it to df_all otherwise appen
    if (df_all <- NULL){
      df_all <- df
    } else {
      df_all <- rbind(df_all, df)
    }
    
    
  }
  
  # save entire big csv
  file_path <- file.path(dest, glue("{folder}_all.csv"))
  write_csv(df_all, filename)
  
    
}
  
  
# this function goes thru all folders and calls the appender
append_all <- function(source_main){
  folders <- list.files(source_main)
  for (folder in folders){
    if (grepl("Companies", folder)) {
      source_all_comp <- file.path(source_main, folder)
      company_folders <- list.files(source_all_comp)
      
      for (company_folder in company_folders){
        source <- file.path(source_main, folder, company_folder)
        dest <- file.path(source_main, folder, company_folder)
        
        # list all files in folder
        files <- list.files(source)
        appender(files, source, dest, folder = company_folder, companies = T)
      }
    } else if (grepl("NoFilter", folder)) {
      source <- file.path(source_main, folder)
      dest <- file.path(source_main, folder)
      
      files <- list.files(source)
      
      # call function for each nofilter folder
      appender(files, source, dest, folder, companies = F)
    }
  }
  
}