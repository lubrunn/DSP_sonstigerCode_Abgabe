
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
source_main <- "cleaned_test"





# function that open each file and appends them together and then saves appended file
appender <- function(files, source, dest, folder, companies = F){
  time1 <- Sys.time()
    print(glue("Working on all files in {source}"))
    df_all <- vroom(file.path(source,files),
                     col_types = cols(.default = "c",text = "c",
                                      created_at = "c",
                                      retweets_count = "i",
                                      long = "i", lat = "i",
                                      likes_count = "i", tweet_length = "i"),
                     delim = ",") 
    print("Finshed loading files")
    # convert created at to date
    df_all$date <- as.Date(df_all$created_at, "%Y-%m-%d")
    print("finished working on date conversion")
    
    # for company folder add the company name as column in order to be later able to filter for company names
    if (companies == T){
      print("Working on companies")
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
    }
    
    
    
    
  
  print("Saving files")
  # save entire big csv
  file_path <- file.path(dest, glue("{folder}_all.csv"))
  vroom_write(df_all, file_path, delim = ",")
  
  print(Sys.time() - time1)  
}



'
this function appends all files that have alreday been appended on a 
company level, goal is to have one df for all company tweets

'


# this function goes thru all folders and calls the appender
append_all <- function(source_main, folders){
  
  
  
  
  # go into each folder
  for (folder in folders){
    print(glue("Working on {folder}"))
    # if its the company folder
    if (grepl("Companies", folder)) {
      
      # path to company main folder
      source_all_comp <- file.path(source_main, folder)
      # list all company folder
      company_folders <- list.files(source_all_comp)
      print("Moving on to company folders")
      dest <- file.path(source_main, "appended/Companies")
      
      # for each company folder go in 
      for (company_folder in company_folders){
        print(glue("Working on {company_folder}"))
        # path to individual company folder
        source <- file.path(source_main, folder, company_folder)

        # list all files in individual company folder
        files <- list.files(source)
        
        # append each file together and save the appended file in the destination
        appender(files, source, dest, folder = company_folder, companies = T)
      }
      print("Finsihed for all companies")
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
      dest <- source
      
      # list all files in the source
      files <- list.files(source)
      print("Started appending files")
      # call function for each nofilter folder, append every single file and
      # save results in dest
      appender(files, source, dest, folder, companies = F)
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

folders <- folders[3:4]

# start function
append_all("cleaned", folders)







