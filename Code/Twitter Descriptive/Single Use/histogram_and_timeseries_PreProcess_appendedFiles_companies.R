library(tidyverse)
library(data.table)
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


# #### for testing
# folder <- folders[4]
# # read data
# files <- list.files(file.path("cleaned", folder))
# files <- files[1:10]
# file <- files[1]
# retweets_filter <- 0
# likes_filter <- 0
# length_filter <- 0





#################################################################################
#################################################################################
#################################################################################
#################################################################################


'
 function that aggreagtes data on a daily basis based on several filter
 this will be used to create histograms for retweets, likes and tweet length
 this is done for preprocessing because live computation may take very long otherwise
 depending on chosen filter, e.g. for filter that take out a lot of data (e.g. retweets > 200)
 the live computation would be somewhat fast enough but for broad filter (retweets  >0)
 computation would take up to 1 minute per histogram
'
hist_data_creator <- function(dt, retweets_filter, likes_filter, length_filter, grouping_variable, file, company_name = NA){
  time_hist <- Sys.time()
  
  
  # filter data, group ny and count for gorups  
  dt <- dt[retweets_count >= retweets_filter &
                  likes_count >= likes_filter &
                  tweet_length >= length_filter,
                .(.N), by = c("created_at", "language", grouping_variable)]
  
  
  
  
  ########## add infos
  # if its a file from a company folder add the company name as column
  
    dt$company <- company_name
   
      
      
      
 
  
  
  # add filters
  dt$retweets_count_filter <- retweets_filter
  dt$likes_count_filter <- likes_filter
  dt$tweet_length_filter <- length_filter
  
  
  
  dt2 <- data.frame("created_at" = as.Date("2021-02-19"), "language" = as.character(NA) , grouping_variable = as.integer(NA),
                    "N" = as.integer(NA), "company" = company_name, 
                    "retweets_count_filter"  =  retweets_filter,
                    "likes_count_filter" =  retweets_filter, "tweet_length_filter" =  retweets_filter)
  
  names(dt2)[names(dt2) == "grouping_variable"] <- grouping_variable
  
  
  dt <- dplyr::bind_rows(dt, dt2)
  ##################################################################
  
  
  return(dt)
  
}

#################################################################################
#################################################################################
'
function that aggregates by day and language and takes the means of likes,
retweets and tweet_length --> will be used for plotting time series of
the means according to several filters
'





# function that applies functions to appended df and saves them
data_wrangler_and_saver <- function(df_all, 
                                    retweets_filter, 
                                    likes_filter, 
                                    length_filter, 
                                    file, 
                                    folder_dest, 
                                    
                                    filename_rt,
                                    filename_likes,
                                    filename_length,
                                    
                                    
                                    
                                    
                                    filename_senti, 
                                 
                                    lang = "",
                                    company_name = NA){
  
  
  # remove duplicates
  df_all <- unique(df_all, by = "id")
  ##############################################################################  
  # call function that creates histograms for all three grouping variables
  # for retweets
  # print("Computing histogram data for rt")
  # #browser()
  # 
  # 
  # for retweets
  print("Computing histogram data for rt")
  df_bins_rt <- hist_data_creator(df_all,retweets_filter =  retweets_filter,
                                  likes_filter = likes_filter,
                                  length_filter = length_filter,
                                  grouping_variable = "retweets_count",
                                  file,
                                  company_name)
  # for likes
  print("Computing histogram data for likes")
  df_bins_likes <- hist_data_creator(df_all, retweets_filter, likes_filter,
                                     length_filter, "likes_count",
                                     file,company_name)
  # for tweet length
  print("Computing histogram data for lengths")
  df_bins_long <- hist_data_creator(df_all, retweets_filter, likes_filter,
                                    length_filter, "tweet_length", file,
                                    company_name)

  # for sentiment
  print("Computing histogram data for sentiment")
  df_bins_senti <- hist_data_creator(df_all, retweets_filter, likes_filter,
                                     length_filter, "sentiment_rd", file,
                                     company_name)

 
  
  
  
  
 
  
  
  
  # filesnames
  
  ##### save files
  print(glue("Saving files for {folder}, rt: {retweets_filter}, likes: {likes_filter}, length:{length_filter}"))
  
  ##### non sentiment files
  vroom_write(df_bins_rt, file.path("plot_data", folder_dest ,filename_rt),
              delim = ",")
  vroom_write(df_bins_likes, file.path("plot_data", folder_dest ,filename_likes),
              delim = ",")
  vroom_write(df_bins_long, file.path("plot_data", folder_dest ,filename_long),
              delim = ",")
 


  # sentiment files
  vroom_write(df_bins_senti, file.path("plot_data", folder_dest ,filename_senti),
              delim = ",")
  
  
  
  
 
}




#################################################################################
#################################################################################
################################################################################
################################################################################
'
now we run the functions for each combination of filters we will later offer
in the shiny app, we then have 1 csv file per filtering method, we might append
this files again and store them in one big database, however keeping them
separately would also work. The idea is tha we only have to read in the least
amount of data needed at a time. This way we can vastly increase execution
speed and reduce live computing
'



# filtering possibilities
likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)

# store all possible combinations in a dataframe
#combis <- expand.grid(likes_list, retweets_list)





source_main <- "sentiment/Shiny_files_companies/appended_files"
files_all <- list.files(source_main)[56:60]

#file <- files_companies[1]
for (file in files_all){





df <- data.table::fread(file.path(source_main, file),
                        select = c("id", "created_at", "language", "retweets_count", 
                                   "likes_count", "tweet_length", "sentiment"),
                        colClasses = c("created_at" = "Date",
                                       "id" = "character"))







  
  
  # read all dfs (one per day)
  time1 <- Sys.time()
  print("Loading Data")
  
  
    
    
    df$created_at <- as.Date(df$created_at)
    
    
    # coompute new variables dependent on sentiment
    df$sentiment_rt <- df$sentiment * df$retweets_count
    df$sentiment_likes <- df$sentiment * df$likes_count
    df$sentiment_length <- df$sentiment * df$tweet_length
    
    # create rounded sentiment variables for bincounts
    df$sentiment_rd <- round(df$sentiment, 2)
  
    
    
    
  
  
  for (retweets_filter in retweets_list){
    for(likes_filter in likes_list){
      for(length_filter in long_list){
        
        # check which name to five file
        if (length_filter == 81){
          long_name <- "long_only"
        } else{
          long_name <- "all"
        }
        
        
        print(glue("Working on {file}, rt: {retweets_filter}, likes: {likes_filter}, length: {length_filter}"))
        
        
      
        folder <- stringr::str_split(file, "[.]")[[1]][1]
        folder_dest <- file.path("Companies",folder)
        lang <- "companies"
        
        # non senti files names
        filename_rt <- glue("histo_rt_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
        filename_likes <- glue("histo_likes_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
        filename_long <- glue("histo_long_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")


        # senti filesnames
         filename_senti <- glue("histo_senti_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
    
        
        # create destination directory
        dir.create(file.path("plot_data", folder_dest))
        
        # check if any of the files already exists
        if (!(
          #file.exists(file.path("plot_data", folder_dest, filename_rt)) 
          # placeholder
          F!=F
          #file.exists(file.path("plot_data", folder_dest, filename_senti))  |
         # file.exists(file.path("plot_data", folder_dest, filename_rt)) |
         # file.exists(file.path("plot_data", folder_dest, filename_likes)) |
          #file.exists(file.path("plot_data", folder_dest, filename_long))
        )) {
          
          
          
          # folder <- gsub("\\..*","",file)
          
          print("Starting to wrangle.")
          # call function that wrangles df and saves it
         
            data_wrangler_and_saver(df_all = df, 
                                    retweets_filter, 
                                    likes_filter, 
                                    length_filter, 
                                    file, 
                                    folder_dest, 
                                    
                                    filename_rt,
                                    filename_likes,
                                    filename_length,
                                    
                                    
                                    
                                    
                                    filename_senti, 
                                    
                                    lang,
                                    company_name =folder)
          
          print(Sys.time() - time1)
        } else {print(glue("All files for {file} already exist at destination plot_data/{folder}"))}
        
        
      } 
    }
  }










}












