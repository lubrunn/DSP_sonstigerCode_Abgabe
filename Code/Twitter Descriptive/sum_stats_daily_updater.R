library(tidyverse)
library(R.utils)
library(glue)




################################################################################
### this is simply for easier switching between vpcl and local
vpc = FALSE

# read in data
if (vpc == T) {
  setwd("/home/lukasbrunner/share/onedrive_new2/Data/Twitter")
  db_wd <- "/home/lukasbrunner/share/onedrive_new2/Data/SQLiteStudio/databases/clean_database.db"
  
} else {
  setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
  db_wd <- "C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases/clean_database.db"
  
}

################################################################################




########## find last date that is in the appended csvs, i.e. the last updated day
last_update_finder <- function(dest, likes_filter, retweets_filter, 
                               long_name){
  
  #### account for diffrent structure in commpaneis folder
  
  
  
  ##### get all files for filter
 
  files <- list.files(file.path(dest))
  filename_addon <- glue::glue("rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
  files <- files[grepl(filename_addon, files)]
  
  #### for each file check last update and then take minimum date of all last updates
  # set up empty list to append dates to
  dates_last_update <- c()
  
  #### only check 1 files because otherwise takes too long
  for (file in files[1]){
    #### read in only last line to see what last date was
    l2keep <- 1
    nL <- R.utils::countLines(file.path(dest, file))
    last_update <- read.csv(file.path(dest, file), header=FALSE, skip=nL-l2keep) %>% select(V1) %>% unlist()
    ## append date
    ### control for empty csvs
    if (!grepl("-", last_update)) {
      last_update = Sys.Date() - lubridate::days(1)
    } 
    
    dates_last_update <- rlist::list.append(dates_last_update, format(as.POSIXct(last_update), format="%Y-%m-%d"))
    
  }
  
  
    
  
  
  #### get minimum last update
  last_update <- min(dates_last_update)
  
  
 
  return(last_update)
}




##### find all files that that need to updated
missing_files_finder <- function(source_main, folder_all, last_update){
 
  
  ## source
  source <- file.path(source_main, folder_all)
  
  #### get all files at source
  all_files <- list.files(source)
  
  ### exclude files that have temp in their name
  all_files <- all_files[!grepl("tmp", all_files)]
  
  #### find last available date
  last_date_avail <- max(parsedate::parse_date(all_files)) 
  
  ####### find dates that still need to be updated
  
  ### check if last update smaller then last date avail
  if (as.Date(last_update) < as.Date(last_date_avail)) {
  dates_missing <- seq(as.Date(last_update) + lubridate::days(1) , as.Date(last_date_avail), by="days")
  } else {
    print(glue("no missing dates found for {source}"))
    return(c())
  }
  ### only start process for files that are missing
  files_missing <- all_files[grepl(paste(dates_missing,collapse = "|"), all_files)]
  ### exclude tmp files
  files_missing<- files_missing[!grepl("tmp", files_missing)]
  

  return(files_missing)
}








####### once the files are found, load everyone and perform computations
file_looper <- function(files_missing, retweets_filter, likes_filter, length_filter, 
                        folder, source, folder_dest, lang, long_name,
                        db_wd){
  for (file in files_missing){
    # read all dfs (one per day)
    time1 <- Sys.time()
    print("Loading Data")
    
    
    
    ##### load missing file
    df <- readr::read_csv(file.path(source ,file),
                          col_types = cols_only(
                            "id" = "c",
                            "created_at" = "c",
                            "language" = "c",
                            "retweets_count" = "i",
                            "likes_count" = "i",
                            "tweet_length" = "i",
                            "sentiment" = "d"
                          ))
                
     #### convert to date
    df$created_at <- as.Date(df$created_at, "%Y-%m-%d")
    
    
    # coompute new variables dependent on sentiment
    df$sentiment_rt <- df$sentiment * df$retweets_count
    df$sentiment_likes <- df$sentiment * df$likes_count
    df$sentiment_length <- df$sentiment * df$tweet_length
    
    # create rounded sentiment variables for bincounts
    df$sentiment_rd <- round(df$sentiment, 2)
    df$sentiment_rt_rd <- round(df$sentiment_rt)
    df$sentiment_likes_rd <- round(df$sentiment_likes)
    df$sentiment_length_rd <- round(df$sentiment_length)
    
    ### convert to datatable
    data.table::setDT(df)
      
   
    
    
          
          
    print(glue::glue("Working on {file}, rt: {retweets_filter}, likes: {likes_filter}, length: {length_filter}"))
    
   
    # non senti files names
    filename_rt <- glue::glue("histo_rt_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
    filename_likes <- glue::glue("histo_likes_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
    filename_long <- glue::glue("histo_long_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
    
    filename_sum <- glue::glue("sum_stats_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
    
    # senti filesnames
    filename_senti <- glue::glue("histo_senti_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
    filename_senti_rt <- glue::glue("histo_senti_rt_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
    filename_senti_likes <- glue::glue("histo_senti_likes_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
    filename_senti_length <- glue::glue("histo_senti_long_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
    
   
      
      
      
    # folder <- gsub("\\..*","",file)
    
    print("Starting to wrangle.")
    # call function that wrangles df and saves it
    if (grepl("NoFilter", folder)) {
      
      
      
      
      data_wrangler_and_saver(df_all = df, 
                              retweets_filter, 
                              likes_filter, 
                              length_filter, 
                              
                              folder_dest, 
                              
                              filename_rt,
                              filename_likes,
                              filename_long,
                              
                              
                              filename_sum,
                              
                              filename_senti, 
                              filename_senti_rt, 
                              filename_senti_likes,
                              filename_senti_length,
                              lang,
                              company_name = NA,
                              db_wd)
      
      
      
      
    } else{
      data_wrangler_and_saver(df_all = df, 
                              retweets_filter, 
                              likes_filter, 
                              length_filter, 
                               
                              folder_dest, 
                              
                              filename_rt,
                              filename_likes,
                              filename_long,
                              
                              
                              filename_sum,
                              
                              filename_senti, 
                              filename_senti_rt, 
                              filename_senti_likes,
                              filename_senti_length,
                              lang,
                              company_name =folder,
                              db_wd)
    }
    print(Sys.time() - time1)
    
    
  }
}










#################################################################################
#################################################################################
#################################################################################
#################################################################################


# function that applies functions to appended df and saves them
data_wrangler_and_saver <- function(df_all, 
                                    retweets_filter, 
                                    likes_filter, 
                                    length_filter, 
                                     
                                    folder_dest, 
                                    
                                    filename_rt,
                                    filename_likes,
                                    filename_long,
                                    
                                    
                                    filename_sum,
                                    
                                    filename_senti, 
                                    filename_senti_rt, 
                                    filename_senti_likes,
                                    filename_senti_length,
                                    lang = "",
                                    company_name = NA,
                                    db_wd){
  
  
  # remove duplicates
  df_all <- unique(df_all, by = "id")
  ##############################################################################  
  # call function that creates histograms for all three grouping variables
  # for retweets
  # print("Computing histogram data for rt")
  
  # 
  # 
  # #for retweets
  print("Computing histogram data for rt")
  df_bins_rt <- hist_data_creator(df_all,retweets_filter =  retweets_filter,
                                  likes_filter = likes_filter,
                                  length_filter = length_filter,
                                  grouping_variable = "retweets_count",
                                  
                                  company_name)
  # for likes
  print("Computing histogram data for likes")
  df_bins_likes <- hist_data_creator(df_all, retweets_filter, likes_filter,
                                     length_filter, "likes_count",
                                     company_name)
  # for tweet length
  print("Computing histogram data for lengths")
  df_bins_long <- hist_data_creator(df_all, retweets_filter, likes_filter,
                                    length_filter, "tweet_length", 
                                    company_name)

  # for sentiment
  print("Computing histogram data for sentiment")
  df_bins_senti <- hist_data_creator(df_all, retweets_filter, likes_filter,
                                     length_filter, "sentiment_rd", 
                                     company_name)

  # # for sentiment * rt
  # print("Computing histogram data for senti weighted by rt")
  # df_bins_senti_rt <- hist_data_creator(df_all, retweets_filter, likes_filter,
  #                                       length_filter, "sentiment_rt_rd", 
  #                                       company_name)
  # 
  # # for sentiment * likes
  # print("Computing histogram data for senti weighted by likes")
  # df_bins_senti_likes <- hist_data_creator(df_all, retweets_filter, likes_filter,
  #                                          length_filter, "sentiment_likes_rd", 
  #                                          company_name)
  # 
  # # for sentiment * tweet_length
  # print("Computing histogram data for senti weighted by length")
  # df_bins_senti_length <- hist_data_creator(df_all, retweets_filter, likes_filter,
  #                                           length_filter, "sentiment_length_rd", 
  #                                           company_name)



  
  
  
  # call function that computes means by day and language of all variables
  print("Computing sum stats data")
  df_sum_stats <- sum_stats_creator(df_all,retweets_filter, likes_filter,
                                    length_filter,
                                    company_name)
  ############
  
  
  
  
  
  ##### save files
  print(glue::glue("Saving files for {filename_rt}, rt: {retweets_filter}, likes: {likes_filter}, length:{length_filter}"))
  
  # # ##### non sentiment files
   write.table(df_bins_rt, file.path(folder_dest ,filename_rt),
               append = T, sep = ",",
               row.names = F, col.names = F)
   
   write.table(df_bins_likes, file.path( folder_dest ,filename_likes),
               append = T, sep = ",",
               row.names = F, col.names = F)
   
  write.table(df_bins_long, file.path( folder_dest ,filename_long),
              append = T, sep = ",",
              row.names = F, col.names = F)
  
   write.table(df_sum_stats, file.path( folder_dest ,filename_sum),
               append = T, sep = ",",
               row.names = F, col.names = F)


  # # sentiment files
   write.table(df_bins_senti, file.path( folder_dest ,filename_senti),
               append = T, sep = ",",
               row.names = F, col.names = F)
   
   # write.table(df_bins_senti_rt, file.path( folder_dest ,filename_senti_rt),
   #             append = T, sep = ",",
   #             row.names = F, col.names = F)
   # 
   # write.table(df_bins_senti_likes, file.path( folder_dest ,filename_senti_likes),
   #             append = T, sep = ",",
   #             row.names = F, col.names = F)
   # 
   # write.table(df_bins_senti_length, file.path( folder_dest ,filename_senti_length),
   #             append = T, sep = ",",
   #             row.names = F, col.names = F)
   # 
  
  
  
  #### upload summary stats to sql
  con <- DBI::dbConnect(RSQLite::SQLite(), db_wd)



  # for sum stats
  RSQLite::dbWriteTable(
    con,
    glue::glue("sum_stats_{lang}"),
    df_sum_stats,
    append = T
  )



  ### disconnect
  DBI::dbDisconnect(con)

  
}




'
 function that aggreagtes data on a daily basis based on several filter
 this will be used to create histograms for retweets, likes and tweet length
 this is done for preprocessing because live computation may take very long otherwise
 depending on chosen filter, e.g. for filter that take out a lot of data (e.g. retweets > 200)
 the live computation would be somewhat fast enough but for broad filter (retweets  >0)
 computation would take up to 1 minute per histogram
'
hist_data_creator <- function(dt_orig, retweets_filter, likes_filter, length_filter, grouping_variable, company_name = NA){
  time_hist <- Sys.time()
  
  if (!is.na(company_name)){
    # group company data also by language
  
  # filter data, group ny and count for gorups  
  dt <- dt_orig[retweets_count >= retweets_filter &
             likes_count >= likes_filter &
             tweet_length >= length_filter,
           .(.N), by = c("created_at", "language", grouping_variable)]
  
  } else {
    # filter data, group ny and count for gorups  
    dt <- dt_orig[retweets_count >= retweets_filter &
                    likes_count >= likes_filter &
                    tweet_length >= length_filter,
                  .(.N), by = c("created_at", grouping_variable)]
  }
  
  
  ########## add infos
  # if its a file from a company folder add the company name as column
  
  #### if df empty than add empty row with date
  if (!is.na(company_name)){
    dt$company <- company_name
    if (dim(dt)[1] == 0){
      dt <- data.frame("created_at" = dt_orig$created_at[1] , language = as.character(NA),
                       grouping_variable = as.integer(NA),
                       "N" = as.integer(NA), "company" = company_name, 
                       "retweets_count_filter"  = as.integer(NA),
                       "likes_count_filter" = as.integer(NA), "tweet_length_filter" = as.integer(NA))
      
      names(dt)[names(dt) == "grouping_variable"] <- grouping_variable
      
      
      return(dt)
      
    }
  } 
  
  
  ##### ontrol for empty df when there are no tweets for filters
  if (dim(dt)[1] == 0){
    dt <- data.frame("created_at" = dt_orig$created_at[1], grouping_variable = as.integer(NA),
                     "N" = as.integer(NA), "retweets_count_filter"  = as.integer(NA),
                     "likes_count_filter" = as.integer(NA), "tweet_length_filter" = as.integer(NA))
    
    names(dt)[names(dt) == "grouping_variable"] <- grouping_variable
    return(dt)
    
  }
  
  # add filters
  dt$retweets_count_filter <- retweets_filter
  dt$likes_count_filter <- likes_filter
  dt$tweet_length_filter <- length_filter
  

  
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
sum_stats_creator <- function(df_all, retweets_filter, likes_filter, length_filter, company_name = NA,
                              db_wd = db_wd){
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
  
  
  
  
  
  
  
  
 
  # add used filters
  dt$retweets_count <- retweets_filter
  dt$likes_count <- likes_filter
  dt$tweet_length <- length_filter
  
  
  # if its a file from a company folder add the company name as column
  if (!is.na(company_name)){
    dt$company <- company_name
    
    if (dim(dt)[1] == 0){
      df_empty <- data.frame(rep(NA,44)) %>% t() %>% data.frame()
      names(df_empty) <- names(dt)
      df_empty$created_at <- as.character(df_all$created_at[1])
      #reset rownames
      rownames(df_empty) <- NULL
      return(df_empty)
    }
    
  } 
  
  
  ### convert created_at to string for sql
  dt$created_at <- as.character(dt$created_at)
  
  
  
  
  
  
  ##################################################################
  
  
  return(dt)
  
  
}








all_together_putter <- function(folders, likes_list, retweets_list, long_list,
                                source_main, dest_main,db_wd)
for (folder in folders){
  
 
  
  
  if (grepl("Companies", folder)){
    #### list all company folders
    company_folders <- list.files(file.path(source_main, folder))
    #### go thru each company folder
    #company_folders <- "Linde"
    for (comp_folder in company_folders){
      
      #### set destination
      dest <- file.path(dest_main, folder, comp_folder)
      
      ### go thru all filter possiblities
      for (retweets_filter in retweets_list){
        for(likes_filter in likes_list){
          for(length_filter in long_list){
            
            ### check file addon for length filter
            if (length_filter == 81){
              long_name <- "long_only"
            } else{
              long_name <- "all"
            }
           
            #### get last updated date for this paritucalr filter option in the company folder
            last_update <- last_update_finder(dest = dest, likes_filter, retweets_filter, 
                                           long_name)
            #### find all files that still need to be updated
            files_missing <- missing_files_finder(source_main = source_main,
                                                  folder_all = file.path(folder, comp_folder),
                                                  last_update)
            
            source <- file.path(source_main, folder, comp_folder)
            
            
            #### start compuation for each file
            file_looper(files_missing = files_missing, 
                        retweets_filter, likes_filter, length_filter, 
                        folder = comp_folder, source = source,
                        folder_dest = dest,
                        lang = "companies",
                        long_name = long_name,
                        db_wd)
            
          }
        }
      }
      
    }
    
  } else {
    
  #### set destination  
  dest <- file.path(dest_main, folder)
  #### get language add on for sql upload
  lang <- tolower(strsplit(folder, "[_]")[[1]][1])
    
  ##### go thru all filters
  for (retweets_filter in retweets_list){
    for(likes_filter in likes_list){
      for(length_filter in long_list){
        
        ### check file addon for length filter
        if (length_filter == 81){
          long_name <- "long_only"
        } else{
          long_name <- "all"
        }
        
        #### get last updated date for this paritucalr filter option in the company folder
        
        last_update <- last_update_finder(dest = dest, likes_filter, retweets_filter, 
                                          long_name)
        #### find all files that still need to be updated
        files_missing <- missing_files_finder(source_main = source_main,
                                              folder_all = folder,
                                              last_update)
        
        
        
        source <- file.path(source_main, folder)
        
        
        file_looper(files_missing = files_missing, 
                    retweets_filter, likes_filter, length_filter, 
                    folder = folder, source = source,
                    folder_dest = dest,
                    lang = lang, long_name = long_name,
                    db_wd)
        
      }
    }
  }
    
    
    
    
  }
  
  
  
}




likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)

source_main <- "sentiment_daily"
dest_main <- "plot_data"

folders <- c("En_NoFilter", "De_NoFilter", "Companies")
#folders <- "De_NoFilter"
#folders <- c("De_NoFilter", "Companies")

######## find last available date at source (sentiment)
#### last available date at source



####### call function

all_together_putter(folders, likes_list, retweets_list, long_list,
                                source_main, dest_main,
                    db_wd)
