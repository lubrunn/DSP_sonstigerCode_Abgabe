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
hist_data_creator <- function(dt, retweets_filter, likes_filter, length_filter, grouping_variable, file){
  time_hist <- Sys.time()
  # different groupings depending on companies
  if (!grepl("NoFilter", file)){
    
    
    
    
    dt <- dt[retweets_count >= retweets_filter &
                    likes_count >= likes_filter &
                    tweet_length >= length_filter,
                  .(.N), by = c("company", "date", "language", grouping_variable)]
    dt$company <- file
    
  } else if (grepl("NoFilter", file)) {
    
    
    
    dt <- df[retweets_count >= retweets_filter &
                    likes_count >= likes_filter &
                    tweet_length >= length_filter,
                  .(.N), by = c("date", grouping_variable)]
    
  }
  
  
  ######## data.table
  
  
  #fmla <- glue("... ~ {grouping_variable}")
  #dt2 <- dcast(dt, fmla , value.var = "N")
  
  # add row sums
  #dt$number_tweets <- rowSums(dt[,!c("date")],na.rm=TRUE)
  
  dt$retweets_count_filter <- retweets_filter
  dt$likes_count_filter <- likes_filter
  dt$tweet_length_filter <- length_filter
  
  dt$date <- as.character(dt$date)
  
  # remove NAs
  #dt2 <- setnafill(dt2, fill=0)
  
  
  
  
  
  
  #############################################################
  ########## placeholder to include company name for companies
 
  
  ###
  
  
  ##################################################################
  
  print(glue("{file} for {grouping_variable} took {Sys.time() - time_hist}"))
  return(dt)
  
}

#################################################################################
#################################################################################
'
function that aggregates by day and language and takes the means of likes,
retweets and tweet_length --> will be used for plotting time series of
the means according to several filters
'
sum_stats_creator <- function(df_all, retweets_filter, likes_filter, length_filter, file){
  time_sum <- Sys.time()
  if (file == "Companies_all.csv"){
    dt <- df_all[retweets_count >= retweets_filter &
                    likes_count >= likes_filter &
                    tweet_length >= length_filter,
                  .(.N,
                    mean_rt = mean(retweets_count),
                    mean_likes = mean(likes_count),
                    mean_length = mean(tweet_length),
                    median_rt = median(retweets_count),
                    median_likes = median(likes_count),
                    median_length = median(tweet_length),
                    
                    std_rt = sd(retweets_count),
                    std_likes = sd(likes_count),
                    std_length = sd(tweet_length)), by = c("company", "date", "language")]
    
    # remove NAs
    #dt[,!c("date", "language", "company")] <- setnafill(dt[,!c("date", "language")], fill=0)
    
    
    
    
    
  } else {
    dt <- df_all[retweets_count >= retweets_filter &
                    likes_count >= likes_filter &
                    tweet_length >= length_filter,
                  .(.N,
                    mean_rt = mean(retweets_count),
                    mean_likes = mean(likes_count),
                    mean_length = mean(tweet_length),
                    median_rt = median(retweets_count),
                    median_likes = median(likes_count),
                    median_length = median(tweet_length),
                    
                    std_rt = sd(retweets_count),
                    std_likes = sd(likes_count),
                    std_length = sd(tweet_length)), by = c("date", "language")]
                    
    
  } 
  
  
  

  
  dt$retweets_count <- retweets_filter
  dt$likes_count <- likes_filter
  dt$tweet_length <- length_filter
  
  
  
  #############################################################
  ########## placeholder to include company name for companies
  if (folder == "Companies"){
    df$company <- folder
  }
  
  ###
  
  
  ##################################################################
  
  return(dt)
  print(glue("{file} took {Sys.time() - time_sum}"))
  
}




# function that applies functions to appended df and saves them
data_wrangler_and_saver <- function(df_all, retweets_filter, likes_filter, length_filter, file, folder, 
                                    filename_rt, filename_likes, filename_long, filename_sum){
  
  # remove when text is missing
  df_all <- na.omit(df_all, cols = "text")
  ##############################################################################  
  # call function that creates histograms for all three grouping variables
  # for retweets
  print("Computing histogram data for rt")
  df_bins_rt <- hist_data_creator(df_all,retweets_filter =  retweets_filter,
                                  likes_filter = likes_filter,
                                  length_filter = length_filter,
                                  grouping_variable = "retweets_count",
                                  file)
  # for likes
  print("Computing histogram data for likes")
  df_bins_likes <- hist_data_creator(df_all, retweets_filter, likes_filter, 
                                     length_filter, "likes_count",
                                     file)
  # for tweet length
  print("Computing histogram data for lengths")
  df_bins_long <- hist_data_creator(df_all, retweets_filter, likes_filter, 
                                    length_filter, "tweet_length", file)
  
  
  
  # call function that computes means by day and language of all variables
  print("Computing sum stats data")
  df_sum_stats <- sum_stats_creator(df_all,retweets_filter, likes_filter,
                                      length_filter, file)
  ############
  
 
  
  
  # filesnames
  
  ##### save files
  print(glue("Saving files for {folder}, rt: {retweets_filter}, likes: {likes_filter}, length:{length_filter}"))
  vroom_write(df_bins_rt, file.path("plot_data", folder ,filename_rt),
              delim = ",")
  vroom_write(df_bins_likes, file.path("plot_data", folder ,filename_likes),
              delim = ",")
  vroom_write(df_bins_long, file.path("plot_data", folder ,filename_long),
              delim = ",")
  vroom_write(df_sum_stats, file.path("plot_data", folder ,filename_sum),
              delim = ",")
  
  
  ##### upload data
  old_wd <- getwd()
  setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases")
  con <- DBI::dbConnect(RSQLite::SQLite(), "test.db")
  
  # write data to sql for rt histo
  RSQLite::dbWriteTable(
    con,
    "histo_rt_en",
    df_bins_rt,
    append = T
    )
  
  # for likes histo
  RSQLite::dbWriteTable(
    con,
    "histo_likes_en",
    df_bins_likes,
    append = T
  )
  
  # for length
  RSQLite::dbWriteTable(
    con,
    "histo_len_en",
    df_bins_long,
    append = T
  )
  
  # for sum stats
  RSQLite::dbWriteTable(
    con,
    "sum_stats_en",
    df_sum_stats,
    append = T
  )
  
  DBI::dbDisconnect(con)
  setwd(old_wd)
  
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




histo_cleaner <- function(source, folders){
for (folder in folders){ 
  files <- list.files(file.path(source,folder))
  
   
  for (file in files){ 
     
     
     # read all dfs (one per day)
     time1 <- Sys.time()
     print("Loading Data")
     if (grepl("Companies", file)){
       
       dt <- fread(file.path(source ,file),
                   select = c("company", "text", "date", "language", "retweets_count", 
                              "likes_count", "tweet_length"),
                   colClasses = c("date" = "character")) 
       
       
       
       
       
     } else if (grepl("NoFilter", file)){
       
       
       df <- fread(file.path(source, folder ,file),
                   select = c("date","text", "language", "retweets_count", 
                              "likes_count", "tweet_length"),
                   colClasses = c("date" = "character")) 
     
     
     
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
          
          if (grepl("NoFilter", file)){
            filename_addon <- gsub(".*?_([[:digit:]]+)_.*", "\\1", file)
          }
          
          if (!missing(filename_addon)){
            filename_rt <- glue("histo_rt_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}_{filename_addon}.csv")
            filename_likes <- glue("histo_likes_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}_{filename_addon}.csv")
            filename_long <- glue("histo_long_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}_{filename_addon}.csv")
            filename_sum <- glue("sum_stats_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}_{filename_addon}.csv")
            
          } else{
            filename_rt <- glue("histo_rt_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
            filename_likes <- glue("histo_likes_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
            filename_long <- glue("histo_long_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
            filename_sum <- glue("sum_stats_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
          }
            
          
          # check if any of the files already exists
          if (!(file.exists(file.path("Plot_data", folder, filename_likes)) |
              file.exists(file.path("Plot_data", folder, filename_rt)) |
              file.exists(file.path("Plot_data", folder, filename_long)) |
              file.exists(file.path("Plot_data", folder, filename_sum))
              )) {
              
              
            
           # folder <- gsub("\\..*","",file)
            
            print("Starting to wrangle.")
            # call function that wrangles df and saves it
            data_wrangler_and_saver(df, retweets_filter, likes_filter, length_filter,file = file,folder = folder,
                                    filename_rt, filename_likes, filename_long, filename_sum)
            print(Sys.time() - time1)
          } else {print(glue("All files for {file} already exist at destination plot_data/{folder}"))}
          
          
          } 
        }
      }
    }
  }
  }
}


################################################################################
################################################################################
##################################### Call Function ############################
################################################################################
################################################################################

# filtering possibilities
likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)

# store all possible combinations in a dataframe
#combis <- expand.grid(likes_list, retweets_list)


source <- "cleaned/appended"
folders <- c("EnNoFilter", "De_NoFilter", "Companies")
folders <- "En_NoFilter"
#files <- list.files(source)[grepl(".csv",source)]


histo_cleaner(source, folders)







##################################################################################
# test datatable


# library(data.table)
# 
# 
# 
# df2 <- data.table::fread("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/De_NoFilter/De_NoFilter_2018-11-30.csv",
#                         select = c("created_at", "language", "retweets_count", 
#                                    "likes_count", "tweet_length"),
#                         colClasses = 
#                           c(
#                             created_at = "character",
#                             retweets_count = "integer",
#                             likes_count = "integer", tweet_length = "integer",
#                             language = "character")) 
# 
# 
# df_orig <- dplyr::bind_rows(df_orig, df_orig)
# retweets_filter <- 0
# likes_filter <- 0
# length_filter <- 0
# grouping_variable <- "retweets_count"
# 
# df_orig <- df
# 
# 
# df_orig$date <- as.Date(df_orig$created_at, "%Y-%m-%d")
# df2$date <- as.Date(df2$created_at, "%Y-%m-%d")
# 
# 
# #datatable
# dt <- df_orig[retweets_count >= retweets_filter &
#            likes_count >= likes_filter &
#            tweet_length >= length_filter,
#          .(.N,
#            mean_rt = mean(retweets_count),
#            mean_likes = mean(likes_count),
#            mean_length = mean(tweet_length),
#            median_rt = median(retweets_count),
#            median_likes = median(likes_count),
#            median_length = median(tweet_length),
#            
#            std_rt = sd(retweets_count),
#            std_likes = sd(likes_count),
#            std_length = sd(tweet_length)), by = c("date", "language")]
# 
# dt$retweets_count <- retweets_filter
# dt$likes_count <- likes_filter
# dt$tweet_length <- length_filter
# 
# # remove NAs
# dt[,!c("date", "language")] <- setnafill(dt[,!c("date", "language")], fill=0)
# 
# 
# # dplyr
# df <-  df_orig %>% filter(
#   likes_count >= likes_filter &
#     retweets_count >= retweets_filter &
#     #long_tweet == long
#     tweet_length >= length_filter) %>%
#   group_by(date, language)   %>%
#   summarise(mean_rt = mean(retweets_count),
#             mean_likes = mean(likes_count),
#             mean_length = mean(tweet_length),
#             std_rt = sd(retweets_count),
#             std_links = sd(likes_count),
#             std_length = sd(tweet_length),
#             count_tweeets = n()) 
# 
# 
#  
# 
# 
# df <- df %>%
#   mutate(retweets_count = retweets,
#          likes_count = likes,
#          tweet_length = longs) %>%
#   ungroup()







  