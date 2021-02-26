
'
Here we write a function that goes through a main model and appends for each 
subfolder the files fo each day into on big csv
this csv will be used for sql, term_freq calc, histogram calc and maybe more
'



#################################################################################
#################################################################################
############################# packages ##########################################
library(tidyverse)

library(vroom)
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

################################################################################






# function that open each file and appends them together and then saves appended file
appender <- function(files, source, dest, folder, companies = F, filename = NA){
time1 <- Sys.time()
  df_all <- NULL
  for (file in files){
    print(glue("Working on {file}"))
    df <- read_csv(file.path(source, file),
                   col_types = cols(.default = "c",text = "c",
                                         created_at = "c",
                                         retweets_count = "i",
                                          long = "i", lat = "i",
                                         likes_count = "i", tweet_length = "i")) 
    
    print("Loaded data, converting date")
    # convert created at to date
    df$date <- as.Date(df$created_at, "%Y-%m-%d")
    
    
    # for company folder add the company name as column in order to be later able to filter for company names
    # for Johnson & Johnson change name
    if (companies == T){
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
    }
    
    print("Merging files")
    time2 <- Sys.time()
    # if first file in loop set it to df_all otherwise appen
    if (is.null(df_all)){
      df_all <- df
    } else {
      df_all <- rbind(df_all, df)
    }
    print(glue("Merging files took {Sys.time() - time2}"))
    
  }
  
  print("Saving files")
  # save entire big csv
  if (!is.na(filename)){
  file_path <- file.path(dest, filename)
  } else {
    file_path <- file.path(dest, glue("{folder}_all.csv"))
    
  }
  vroom_write(df_all, file_path, delim = ",")
  
  print(Sys.time() - time1)  
}



'
this function appends all files that have alreday been appended on a 
company level, goal is to have one df for all company tweets

'



company_appender <- function(source_main, dest, folder, company_folder){
  df_all <- NULL
  for (company_folder in company_folders){
    # read entire df for company
    file_path <- file.path(source_main, folder, company_folder, glue("{folder}_all.csv"))
    df <- read_csv(file_path,
             col_types = cols(.default = "c",text = "c",
                              created_at = "c",
                              retweets_count = "i",
                              long = "i", lat = "i",
                              likes_count = "i", tweet_length = "i"))
    
    # append
    # if first df then set it to df_all otherwise append
    if (is.null(df_all)){
      df_all <- df
    } else {
      df_all <- rbind(df_all, df)
    }
    
    ### save df
    file_path <- file.path(dest,  glue("{folder}_all.csv"))
    write_csv(df_all, file_path)
  }
}
  
  

# this function goes thru all folders and calls the appender
append_all <- function(source_main, folders){
  
  
  
  
  # go into each folder
  for (folder in folders){
    
    # if its the company folder
    if (grepl("Companies", folder)) {
      
      # path to company main folder
      source_all_comp <- file.path(source_main, folder)
      # list all company folder
      company_folders <- list.files(source_all_comp)
      
      # for each company folder go in 
      for (company_folder in company_folders){
        
        # path to individual company folder
        source <- file.path(source_main, folder, company_folder)
        # same as source just created for clarity (only string no long comp time)
        dest <- file.path(source_main, "appended/Companies")
        
        # list all files in indivdual company folder
        files <- list.files(source)
        
        # append each file togehter and save the appended file in the destination
        appender(files, source, dest, folder = company_folder, companies = T)
      }
      
      # then take each appended company df containing all 
      # days and append all company df to one big company df containing all 
      # days for all companies

      print("Now appending all individually appended company files")
      files <- list.files(dest)
      # select new destination
      dest <- file.path(source_main, "appended")
      # append all single files
      appender(files, source = dest, dest = dest, folder = "Companies",
               companies = F)
      
      
      
      

      

      
      
      
      # for all no filter folders go on
    } else if (grepl("NoFilter", folder)) {
      
      # path to en_nofilter/de_nofilter
      source <- file.path(source_main, folder)
      # destination
      dest <- file.path(source_main, "appended")
      
      # list all files in the source
      
      # split append process into 4 subprocesses so in case of error/stuck
      # not all progress lost
      subset_list <- c(0, 100, 200, 300, 400, 500,600, 700, 813)
      for (i in 1:8){
        
      files <- list.files(source)[(subset_list[i] + 1):subset_list[i + 1]]
      
      filename <- glue("{folder}_{subset_list[i] +1 }_{subset_list[i+1]}.csv")  
      
      #if doesnt exist in destination start appender
      if (!(filename  %in% list.files(dest))){
      # call function for each nofilter folder, append every single file and
      # save results in dest
      
      appender(files, source, dest, folder, companies = F, filename)
      }
      }
    }
  
  

}

  }

################################################################################
################################################################################
############################## Call Function ###################################
################################################################################
################################################################################

# which folders should be appended
source_main <- "cleaned"

# list all folders in source main
folders <- list.files(source_main)

folders <- folders[4]

# start function
append_all(source_main, folders)





'
Function that appends sub appended lists
'

final_appender <- function(source_main){
  files <- list.files(file.path(source_main), "appended", lang)
  
  files <- files[grepl(glue("^{lang}.*\\.csv"), files)]
  
  df <- vroom(files,
              col_types = cols(.default = "c",text = "c",
                               created_at = "c",
                               retweets_count = "i",
                               long = "i", lat = "i",
                               likes_count = "i", tweet_length = "i"),
              delim = ",")
  
  
  
  
  write_vroom(df, "De_NoFilter_all.csv", dleim = ",")
}








