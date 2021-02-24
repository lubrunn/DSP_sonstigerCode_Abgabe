library(tidyverse)
setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")

folders <- list.files("cleaned")


likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)



#### for testing
folder <- folders[2]
# read data
files <- list.files(file.path("cleaned", folder))
files <- files[1:10]
file <- files[1]
retweets <- 0
likes <- 0
longs <- 0



df_all <- NULL
for (file in files){
df <- readr::read_csv(file.path("cleaned", folder ,file),
               col_types = cols_only(
                                     created_at = "c",
                                     retweets_count = "i",
                                     likes_count = "i", tweet_length = "i",
                                     language = "c")) 
if(is.null(df_all)){
  df_all <- df
} else {
df_all <- rbind(df_all, df)
}
}


# add date column
df_all$date <- as.Date(df_all$created_at, "%Y-%m-%d")


'
 function that aggreagtes data on a daily basis based on several filter
 this will be used to create histograms for retweets, likes and tweet length
 this is done for preprocessing because live computation may take very long otherwise
 depending on chosen filter, e.g. for filter that take out a lot of data (e.g. retweets > 200)
 the live computation would be somewhat fast enough but for broad filter (retweets  >0)
 computation would take up to 1 minute per histogram
'
hist_data_creator <- function(df, retweets_filter, likes_filter, length_filter, grouping_variable){
# for retweets hist
df <- df_all %>% filter(
  # filter out accoring to loop
  likes_count >= likes_filter &
  retweets_count >= retweets_filter &
  tweet_length >= length_filter) %>%
  # count number of tweets per bin in likes, length, retweets
  group_by(date,language, .data[[grouping_variable]]) %>%
  summarise(n = n())  %>%
  # spread dataframe
  pivot_wider(names_from = .data[[grouping_variable]], values_from = n) %>%
  # add values that were used to filter for later filtering
  mutate(retweets_count = retweets,
         likes_count = likes,
         tweet_length = longs,
         # count number of tweets that are part of one aggregated day
         tweet_number = sum(c_across(-c("retweets_count",
                                        "likes_count", "tweet_length")), na.rm = T))%>%
  ungroup()
return(df)
}

'
function that aggregates by day and language and takes the means of likes,
retweets and tweet_length --> will be used for plotting time series of
the means according to several filters
'

sum_stats_creator <- function(df_all, retweets_filter, likes_filter, length_filter){
  df <- df_all %>% filter(
    likes_count >= likes_filter &
      retweets_count >= retweets_filter &
      #long_tweet == long
      tweet_length >= length_filter) %>%
    group_by(date,language) %>%
    summarise(mean_rt = mean(retweets_count),
              mean_likes = mean(likes_count),
              mean_length = mean(tweet_length),
              count_tweeets = n())  %>%
    mutate(retweets_count = retweets,
           likes_count = likes,
           tweet_length = longs) %>%
    ungroup()
  return(df)
  
}

df_bins_rt <- hist_data_creator(df_all,retweets_filter =  retweets,
                                likes_filter = likes,
                                length_filter = longs,
                                grouping_variable = "retweets_count")

df_bins_likes <- hist_data_creator(df_all, retweets, likes, longs, "likes_count")

df_bins_long <- hist_data_creator(df_all, retweets, likes, longs, "tweet_length")




df_sum_stats_n <- sum_stats_creator(df_all,retweets, likes, longs)










for (folder in folders){
  if (grepl("Companies", folder)) {
    source_main <- file.path("cleaned", folder)
    company_folders <- list.files(source_main)
    
    #create companies folder if doesnt exist
    dir.create(file.path("histo", folder), showWarnings = FALSE)
    
    for (company_folder in company_folders){
      source <- file.path("cleaned", folder, company_folder)
      dest <- file.path("histo", folder, company_folder)
      # if folder doesnt exist, create it
      dir.create(dest, showWarnings = FALSE)
      # run function
      #term_freq_computer(company_folder)
    }
  } else if (grepl("NoFilter", folder)) {
    source <- file.path("cleaned", folder)
    dest <- file.path("histo", folder)
    # if folder doesnt exist, create it
    dir.create(dest, showWarnings = FALSE)
    
    # call function for each nofilter folder
    #term_freq_computer(folder)
  }
  
}