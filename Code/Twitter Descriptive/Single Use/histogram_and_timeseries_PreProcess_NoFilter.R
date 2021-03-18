library(tidyverse)
library(data.table)
library(vroom)
library(glue)







################################################################################
### this is simply for easier switching between vpcl and local
vpc = FALSE

# read in data
if (vpc == T) {
  setwd("/home/lukasbrunner/share/onedrive_new2/Data/Twitter")
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
  dt <- df[retweets_count >= retweets_filter &
             likes_count >= likes_filter &
             tweet_length >= length_filter,
           .(.N), by = c("created_at", grouping_variable)]
  
  
  
  
  ########## add infos
  # if its a file from a company folder add the company name as column
  if (!is.na(company_name)){
    dt$company <- company_name
  } 
  
  
  
  # add filters
  dt$retweets_count_filter <- retweets_filter
  dt$likes_count_filter <- likes_filter
  dt$tweet_length_filter <- length_filter
  
  
  
  
  
  
  
  
  
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
sum_stats_creator <- function(df_all, retweets_filter, likes_filter, length_filter, file, company_name = NA){
  time_sum <- Sys.time()
  
  dt <- df_all[retweets_count >= retweets_filter &
                 likes_count >= likes_filter &
                 tweet_length >= length_filter,
               .(.N,
                 
                 
                 mean_rt = mean(retweets_count),
                 mean_likes = mean(likes_count),
                 mean_length = mean(tweet_length),
                 mean_sentiment = mean(sentiment),
                 
                 
                 
                 median_rt = as.numeric(median(retweets_count)),
                 median_likes = as.numeric(median(likes_count)),
                 median_length = as.numeric(median(tweet_length)),
                 median_sentiment = as.numeric(median(sentiment)),
                 
                 
                 
                 std_rt = sd(retweets_count),
                 std_likes = sd(likes_count),
                 std_length = sd(tweet_length),
                 std_sentiment = sd(sentiment),
                 
                 
                 ##### min
                 min_rt = min(retweets_count),
                 min_likes = min(likes_count),
                 min_length = min(tweet_length),
                 min_sentiment = min(sentiment),
                 
                 ##### max
                 max_rt = max(retweets_count),
                 max_likes = max(likes_count),
                 max_length = max(tweet_length),
                 max_sentiment = max(sentiment),
                 
                 
                 
                 ## 25th quantile
                 q25_rt = quantile(retweets_count, 0.25),
                 q25_likes = quantile(likes_count, 0.25),
                 q25_length = quantile(tweet_length, 0.25),
                 q25_sentiment = quantile(sentiment, 0.25),
                 
                 
                 ### 75 quantile
                 q75_rt = quantile(retweets_count, 0.75),
                 q75_likes = quantile(likes_count, 0.75),
                 q75_length = quantile(tweet_length, 0.75),
                 q75_sentiment = quantile(sentiment, 0.75),
                 
                 
                 
                 
                 ######## weighted metrics
                 mean_sentiment_rt = weighted.mean(sentiment,retweets_count),
                 mean_sentiment_likes = weighted.mean(sentiment,likes_count),
                 mean_sentiment_length = weighted.mean(sentiment,tweet_length),
                 
                 median_sentiment_rt = matrixStats::weightedMedian(sentiment, retweets_count),
                 median_sentiment_likes = matrixStats::weightedMedian(sentiment, likes_count),
                 median_sentiment_length = matrixStats::weightedMedian(sentiment, tweet_length),
                 
                 std_sentiment_rt = sqrt(Hmisc::wtd.var(sentiment, retweets_count)),
                 std_sentiment_likes = sqrt(Hmisc::wtd.var(sentiment, likes_count)),
                 std_sentiment_length = sqrt(Hmisc::wtd.var(sentiment, tweet_length))
                 
               ), by = c("created_at", "language")]
  
  
  
  
  
  # if its a file from a company folder add the company name as column
  if (!is.na(company_name)){
    dt$company <- company_name
  } 
  
  
  # add used filters
  dt$retweets_count <- retweets_filter
  dt$likes_count <- likes_filter
  dt$tweet_length <- length_filter
  
  
  
  
  
  
  ##################################################################
  
  print(glue("{file} took {Sys.time() - time_sum}"))
  return(dt)
  
  
}




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
                                    
                                    
                                    filename_sum,
                                    
                                    filename_senti, 
                                    filename_senti_rt, 
                                    filename_senti_likes,
                                    filename_senti_length,
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
  # #for retweets
  # print("Computing histogram data for rt")
  # df_bins_rt <- hist_data_creator(df_all,retweets_filter =  retweets_filter,
  #                                 likes_filter = likes_filter,
  #                                 length_filter = length_filter,
  #                                 grouping_variable = "retweets_count",
  #                                 file,
  #                                 company_name)
  # # for likes
  # print("Computing histogram data for likes")
  # df_bins_likes <- hist_data_creator(df_all, retweets_filter, likes_filter,
  #                                    length_filter, "likes_count",
  #                                    file,company_name)
  # # for tweet length
  # print("Computing histogram data for lengths")
  # df_bins_long <- hist_data_creator(df_all, retweets_filter, likes_filter,
  #                                   length_filter, "tweet_length", file,
  #                                   company_name)
  # 
  # # for sentiment
  # print("Computing histogram data for sentiment")
  # df_bins_senti <- hist_data_creator(df_all, retweets_filter, likes_filter,
  #                                    length_filter, "sentiment_rd", file,
  #                                    company_name)
  # 
  # # for sentiment * rt
  # print("Computing histogram data for senti weighted by rt")
  # df_bins_senti_rt <- hist_data_creator(df_all, retweets_filter, likes_filter,
  #                                       length_filter, "sentiment_rt_rd", file,
  #                                       company_name)
  # 
  # # for sentiment * likes
  # print("Computing histogram data for senti weighted by likes")
  # df_bins_senti_likes <- hist_data_creator(df_all, retweets_filter, likes_filter,
  #                                          length_filter, "sentiment_likes_rd", file,
  #                                          company_name)
  # 
  # # for sentiment * tweet_length
  # print("Computing histogram data for senti weighted by length")
  # df_bins_senti_length <- hist_data_creator(df_all, retweets_filter, likes_filter,
  #                                           length_filter, "sentiment_length_rd", file,
  #                                           company_name)
  # 
  # 
  # 
  
  
  
  # call function that computes means by day and language of all variables
  print("Computing sum stats data")
  df_sum_stats <- sum_stats_creator(df_all,retweets_filter, likes_filter,
                                    length_filter, file,
                                    company_name)
  ############
  
  
  
  
  # filesnames
  
  ##### save files
  print(glue("Saving files for {folder}, rt: {retweets_filter}, likes: {likes_filter}, length:{length_filter}"))
  
  # # ##### non sentiment files
  #  vroom_write(df_bins_rt, file.path("plot_data", folder_dest ,filename_rt),
  #              delim = ",")
  #  vroom_write(df_bins_likes, file.path("plot_data", folder_dest ,filename_likes),
  #              delim = ",")
  # vroom_write(df_bins_long, file.path("plot_data", folder_dest ,filename_long),
  #             delim = ",")
  #  vroom_write(df_sum_stats, file.path("plot_data", folder_dest ,filename_sum),
  #              delim = ",")
  # 
  # 
  # # # sentiment files
  #  vroom_write(df_bins_senti, file.path("plot_data", folder_dest ,filename_senti),
  #              delim = ",")
  #  vroom_write(df_bins_senti_rt, file.path("plot_data", folder_dest ,filename_senti_rt),
  #              delim = ",")
  #  vroom_write(df_bins_senti_likes, file.path("plot_data", folder_dest ,filename_senti_likes),
  #              delim = ",")
  #  vroom_write(df_bins_senti_length, file.path("plot_data", folder_dest ,filename_senti_length),
  #              delim = ",")
   
  
  
  
  ##### upload data
  old_wd <- getwd()
  setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases")
  con <- DBI::dbConnect(RSQLite::SQLite(), "clean_database.db")
  
  # RSQLite::dbWriteTable(
  #   con,
  #   glue("histo_rt_{lang}"),
  #   df_bins_rt,
  #   append = T
  # )
  # 
  # # for likes histo
  # RSQLite::dbWriteTable(
  #   con,
  #   glue("histo_likes_{lang}"),
  #   df_bins_likes,
  #   append = T
  # )
  # 
  # # for length
  # RSQLite::dbWriteTable(
  #   con,
  #   glue("histo_len_{lang}"),
  #   df_bins_long,
  #   append = T
  # )
  # 
  
  # for sum stats
  RSQLite::dbWriteTable(
    con,
    glue("sum_stats_{lang}"),
    df_sum_stats,
    append = T
  )
  
  
  ##################
  # #### for sentiment
  #  RSQLite::dbWriteTable(
  #    con,
  #    glue("histo_sentiment_{lang}"),
  #    df_bins_senti,
  #    append = T
  # )
  # 
  # # for likes histo
  #  RSQLite::dbWriteTable(
  #    con,
  #    glue("histo_sentiment_rt_{lang}_all"),
  #    df_bins_senti_rt,
  #    append = T
  #  )
  # 
  #  # for length
  #  RSQLite::dbWriteTable(
  #    con,
  #    glue("histo_sentiment_likes_{lang}_all"),
  #    df_bins_senti_likes,
  #    append = T
  #  )
  # 
  #  # for sum stats
  #  RSQLite::dbWriteTable(
  #    con,
  #    glue("histo_sentiment_tweet_length_{lang}_all"),
  #    df_bins_senti_length,
  #    append = T
  # )
  
  
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



# filtering possibilities
likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)

# store all possible combinations in a dataframe
#combis <- expand.grid(likes_list, retweets_list)


source <- "sentiment/Shiny_files"
files_nofilter <- c("all_tweets_sentiment.csv", "all_tweets_sentiment_de.csv")
file <- files_nofilter[2]


source <- "sentiment/Shiny_files_companies/appended_files"
files_companies <- list.files(source)

#file <- files_companies[1]
#files_companies <- c("Linde.csv")








for (file in files_companies){ 
  
  
  # read all dfs (one per day)
  time1 <- Sys.time()
  print("Loading Data")
  
  if (grepl("all", file)){
    
    
    df <- fread(file.path(source ,file),
                select = c("id", "created_at", "language", "retweets_count", 
                           "likes_count", "tweet_length", "sentiment"),
                colClasses = c("created_at" = "character",
                               "id" = "character")
    ) 
    df$created_at <- as.Date(df$created_at, "%Y-%m-%d")
    # 
    # k <- "0"
    # 
    # df <- df[created_at <= "2019-12-31"]
    
    
    
    #df$created_at <- as.character(df$created_at)
    
    # coompute new variables dependent on sentiment
    df$sentiment_rt <- df$sentiment * df$retweets_count
    df$sentiment_likes <- df$sentiment * df$likes_count
    df$sentiment_length <- df$sentiment * df$tweet_length
    
    # create rounded sentiment variables for bincounts
    df$sentiment_rd <- round(df$sentiment, 2)
    df$sentiment_rt_rd <- round(df$sentiment_rt)
    df$sentiment_likes_rd <- round(df$sentiment_likes)
    df$sentiment_length_rd <- round(df$sentiment_length)
    
  } else  {
    
    df <- data.table::fread(file.path(source ,file),
                            select = c("id", "created_at", "language", "retweets_count", 
                                       "likes_count", "tweet_length", "sentiment"),
                            colClasses = c("created_at" = "Date",
                                           "id" = "character"))
    
    df$creatd_at <- as.Date(df$created_at)
    
    df$created_at <- as.character(df$created_at)
    
    
    # coompute new variables dependent on sentiment
    df$sentiment_rt <- df$sentiment * df$retweets_count
    df$sentiment_likes <- df$sentiment * df$likes_count
    df$sentiment_length <- df$sentiment * df$tweet_length
    
    # create rounded sentiment variables for bincounts
    df$sentiment_rd <- round(df$sentiment, 2)
    df$sentiment_rt_rd <- round(df$sentiment_rt)
    df$sentiment_likes_rd <- round(df$sentiment_likes)
    df$sentiment_length_rd <- round(df$sentiment_length)
    
    
    
  }
  
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
        
        
        if (grepl("all_tweets_sentiment_de", file)){
          folder <- "De_NoFilter"
          folder_dest <- "De_NoFilter"
          lang <- "de"
        } else if (grepl("all_tweets_sentiment", file)){
          folder <- "En_NoFilter"
          folder_dest <- "En_NoFilter"
          lang <- "en"
        } else{
          folder <- stringr::str_split(file, "[.]")[[1]][1]
          folder_dest <- "Companies"
          lang <- "companies"
        }
        # non senti files names
        filename_rt <- glue("histo_rt_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
        filename_likes <- glue("histo_likes_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
        filename_long <- glue("histo_long_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
        
        filename_sum <- glue("sum_stats_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
        
        # senti filesnames
        filename_senti <- glue("histo_senti_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
        filename_senti_rt <- glue("histo_senti_rt_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
        filename_senti_likes <- glue("histo_senti_likes_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
        filename_senti_length <- glue("histo_senti_long_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
        
        
        # check if any of the files already exists
        if (!(
          file.exists(file.path("plot_data", folder_dest, filename_sum)) 
          
          #file.exists(file.path("plot_data", folder_dest, filename_senti))  |
          # file.exists(file.path("plot_data", folder_dest, filename_rt)) |
          # file.exists(file.path("plot_data", folder_dest, filename_likes)) |
          # file.exists(file.path("plot_data", folder_dest, filename_long))
        )) {
          
          
          
          # folder <- gsub("\\..*","",file)
          
          print("Starting to wrangle.")
          # call function that wrangles df and saves it
          if (grepl("NoFilter", folder)) {
            
            
            
            
            data_wrangler_and_saver(df_all = df, 
                                    retweets_filter, 
                                    likes_filter, 
                                    length_filter, 
                                    file, 
                                    folder_dest, 
                                    
                                    filename_rt,
                                    filename_likes,
                                    filename_length,
                                    
                                    
                                    filename_sum,
                                    
                                    filename_senti, 
                                    filename_senti_rt, 
                                    filename_senti_likes,
                                    filename_senti_length,
                                    lang,
                                    company_name = NA)
            
            
            
            
          } else{
            data_wrangler_and_saver(df_all = df, 
                                    retweets_filter, 
                                    likes_filter, 
                                    length_filter, 
                                    file, 
                                    folder_dest, 
                                    
                                    filename_rt,
                                    filename_likes,
                                    filename_length,
                                    
                                    
                                    filename_sum,
                                    
                                    filename_senti, 
                                    filename_senti_rt, 
                                    filename_senti_likes,
                                    filename_senti_length,
                                    lang,
                                    company_name =folder )
          }
          print(Sys.time() - time1)
        } else {print(glue("All files for {file} already exist at destination plot_data/{folder}"))}
        
        
      } 
    }
  }
}






















