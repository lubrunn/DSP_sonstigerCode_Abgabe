library(tidyverse)
library(vroom)
setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")








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
hist_data_creator <- function(df, retweets_filter, likes_filter, length_filter, grouping_variable, file){
  time_hist <- Sys.time()
  # different groupings depending on companies
  if (file == "Companies_all.csv"){
    df <- df %>% filter(
      # filter out according to loop
      likes_count >= likes_filter &
        retweets_count >= retweets_filter &
        tweet_length >= length_filter) %>%
      
      # count number of tweets per bin in likes, length, retweets
      # for company file
      group_by(company, date,language,!!as.symbol(grouping_variable)) %>%
      
      summarise(n = n())
    grouping_vars <- quos()
  } else {
    df <-  df %>% filter(
      # filter out according to loop
      likes_count >= likes_filter &
        retweets_count >= retweets_filter &
        tweet_length >= length_filter) %>%
      
      # count number of tweets per bin in likes, length, retweets
      # for company file
      group_by(date,!!as.symbol(grouping_variable)) %>%
      
      summarise(n = n()) 
    
    
  }
  
  
  # for retweets hist
  df <- df %>%
    # spread dataframe
    pivot_wider(names_from = .data[[grouping_variable]], values_from = n) %>%
    # add values that were used to filter for later filtering
    mutate(retweets_count = retweets,
           likes_count = likes,
           tweet_length = longs,
           # count number of tweets that are part of one aggregated day
           tweet_number = sum(c_across(-c("retweets_count",
                                          "likes_count", 
                                          "tweet_length")), na.rm = T))%>%
    ungroup() %>%
    replace(is.na(.), 0) 
  print(glue("{file} for {grouping_variable} took {Sys.time() - time_hist)}"))
  return(df)
  
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
    df <- df %>% filter(
      likes_count >= likes_filter &
        retweets_count >= retweets_filter &
        #long_tweet == long
        tweet_length >= length_filter) %>%
      group_by(company, date,language)  %>%
      summarise(mean_rt = mean(retweets_count),
                mean_likes = mean(likes_count),
                mean_length = mean(tweet_length),
                std_rt = std(retweets_count),
                std_links = std(likes_count),
                std_length = std(tweet_length),
                count_tweeets = n()) 
    
  } else {
    df <-  df %>% filter(
      likes_count >= likes_filter &
        retweets_count >= retweets_filter &
        #long_tweet == long
        tweet_length >= length_filter) %>%
      group_by(date)   %>%
      summarise(mean_rt = mean(retweets_count),
                mean_likes = mean(likes_count),
                mean_length = mean(tweet_length),
                std_rt = std(retweets_count),
                std_links = std(likes_count),
                std_length = std(tweet_length),
                count_tweeets = n()) 
    
    
  } 
  
  
  df <- df %>%
    mutate(retweets_count = retweets,
           likes_count = likes,
           tweet_length = longs) %>%
    ungroup()
  print(glue("{file} took {Sys.time() - time_sum}"))
  return(df)
  
}

# function that applies functions to appended df and saves them
data_wrangler_and_saver <- function(df_all, retweets, likes, longs, file, folder){
  
  
  ##############################################################################  
  # call function that creates histograms for all three grouping variables
  # for retweets
  print("Computing histogram data for rt")
  df_bins_rt <- hist_data_creator(df_all,retweets_filter =  retweets,
                                  likes_filter = likes,
                                  length_filter = longs,
                                  grouping_variable = "retweets_count",
                                  file)
  # for likes
  print("Computing histogram data for likes")
  df_bins_likes <- hist_data_creator(df_all, retweets, likes, 
                                     longs, "likes_count",
                                     file)
  # for tweet length
  print("Computing histogram data for lengths")
  df_bins_long <- hist_data_creator(df_all, retweets, likes, longs, 
                                    "tweet_length", file)
  
  
  
  # call function that computes means by day and language of all variables
  print("Computing sum stats data")
  df_sum_stats_n <- sum_stats_creator(df_all,retweets, likes, longs, file)
  ############
  
  # check which name to five file
  if (longs == 81){
    long_name <- "long_only"
  } else{
    long_name <- "all"
  }
  
  
  # filesnames
  filename_rt <- glue("histo_rt_{folder}_rt_{retweets}_li_{likes}_lo_{long_name}.csv")
  filename_likes <- glue("histo_likes_{folder}_rt_{retweets}_li_{likes}_lo_{long_name}.csv")
  filename_long <- glue("histo_long_{folder}_rt_{retweets}_li_{likes}_lo_{long_name}.csv")
  filename_sum <- glue("sum_stats_{folder}_rt_{retweets}_li_{likes}_lo_{long_name}.csv")
  
  
  ##### save files
  print(glue("Saving files for {folder}, rt: {retweets}, likes: {likes}, length:{longs}"))
  vroom_write(df_bins_rt, file.path("plot_data", folder ,filename_rt),
              delim = ",")
  vroom_write(df_bins_likes, file.path("plot_data", folder ,filename_likes),
              delim = ",")
  vroom_write(df_bins_long, file.path("plot_data", folder ,filename_long),
              delim = ",")
  vroom_write(df_sum_stats, file.path("plot_data", folder ,filename_sum),
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




histo_cleaner <- function(files){
  
  for (retweets in retweets_list){
    for(likes in likes_list){
      for(longs in long_list){
        for (file in files){
          print(glue("Working on {file}, rt: {retweets}, likes: {likes}, length: {longs}"))
          # read all dfs (one per day)
          time1 <- Sys.time()
          print("Loading Data")
          if (file != "Companies_all.csv"){
            df <- vroom(file.path(source ,file),
                        col_types = cols_only(
                          company = "c",
                          date = "c",
                          retweets_count = "i",
                          likes_count = "i", tweet_length = "i",
                          language = "c"),
                        delim = ",") 
            
          } else if (grepl("NoFilter", file)){
            df <- vroom(file.path(source ,file),
                        col_types = cols_only(
                          date = "c",
                          retweets_count = "i",
                          likes_count = "i", tweet_length = "i",
                          language = "c"),
                        delim = ",") 
          }
          folder <- gsub("\\..*","",file)
          
          # drop missing tweets
          df <- df %>% tidyr::drop_na("text")
          
          
          
          print("Starting to wrangle.")
          # call function that wrangles df and saves it
          data_wrangler_and_saver(df, retweets, likes, longs,file = file,folder = folder)
          print(Sys.time() - time1)
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
combis <- expand.grid(likes_list, retweets_list)


source <- "cleaned_test/appended"
files <- list.files(source)[grepl(".csv",source)]


histo_cleaner(source)





