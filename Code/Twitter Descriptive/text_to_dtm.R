library(corpus)
library(dplyr)
library(tm)
library(glue)

#################################################################################
#################################################################################

'
Here we compute term frequencies per day in order to increase execution speed in the app.
We preprocess for every possible combination the user will be able to choose.
We then aggregate each data for the live filtering for the date range. For the
other filter methods (retweets etc.) each filter has its own file (or its all
in sql table if we have enough time to upload it all)
'




#################################################################################
#################################################################################

setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
######## read in cleaned data
###
folders <- c("En_NoFilter_all.csv", "De_NoFilter_all.csv", "Companies")


retweets <- 0
likes <- 0
longs <- 0


likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)

folder <- "En_NoFilter"
files <- list.files(file.path("cleaned", folder))
#### for testing
folder <- folders[2]
file <- files[4]



df <- vroom(file.path("pre_cleaned",folder, files[1])),
               col_types = cols(.default = "c",text = "c",
                                created_at = "c",
                                retweets_count = "i",
                                long = "i", lat = "i",
                                likes_count = "i", tweet_length = "i"))




################################################################################
################################################################################
'
This function takes one already appended file and computes the term frequencies
per day accroding to given filters

'
term_freq_computer <- function(source, file, dest){
  # read data
  time1 <- Sys.time()
  df <- read_csv(file.path(source,file),
                 col_types = cols_only(doc_id = "c",text = "c",
                                       date = "c",
                                       retweets_count = "i",
                                       likes_count = "i", tweet_length = "i")) 
  
  
  
  df$date <- as.Date(df$created_at, "%Y-%m-%d")
  
  # remove words that dont at least appear in 1% of tweets
  # for this compute number of tweets per day and from this take
  # average in order to approximate how many times each word should appear
  num_tweets <- df %>% filter(
    likes_count >= likes &
      retweets_count >= retweets &
      #long_tweet == long
      tweet_length >= longs)%>%
    group_by(date) %>%
    summarise(tweets_amnt = n()) %>%
    ungroup() 
  
  threshold_single <- round(0.01 *  mean(num_tweets$tweets_amnt))
  threshold_pairs <- round(0.001 *  mean(num_tweets$tweets_amnt))
  
  
  # compute term frequencies for the entire day
  term_frequency <-  df %>% 
    tidytext::unnest_tokens(word, text) %>%
    group_by(date, language, word) %>%
    summarise(n = n()) %>%
    filter(n > threshold_single) %>%
    pivot_wider(names_from = word, values_from = n) %>%
    ungroup() %>%
    replace(is.na(.), 0) %>%
    left_join(num_tweets, by = "date") %>%
    mutate(retweets_count = retweets,
           likes_count = likes,
           tweet_length = longs) 
  
  
  ####### now for word pairs
  # put every single word into new column, so one row per word in tweet
  pairs_df <- df %>%
    unnest_tokens(word, text) %>%
    group_by(date, language) %>%
    # show all pairs out of all pairs per tweet
    # feel so forgoten that --> feel so, feel forgotten, feel that, so feel, so forgotten, so that etc.
    widyr::pairwise_count(word, doc_id, sort = T) %>%
    rename("weight" = n) %>%
    filter(weight > threshold_pairs)
  
  
  #remove rows that are the same but item1 and item2 are reversed
  pairs_df <- pairs_df[!duplicated(t(apply(pairs_df,1,sort))),]
  
  # collapse both words
  pairs_df$pairs <- paste(pairs_df$item1,pairs_df$item2, sep = ", ")
  pairs_df <-  pairs_df %>% select(pairs, n = weight) %>%
    pivot_wider(names_from = pairs, values_from = n) %>%
    ungroup %>%
    replace(is.na(.), 0) %>%
    mutate(retweets_count = retweets,
           likes_count = likes,
           tweet_length = longs) %>%
  
  
  
  # save df
  print("Saving file")
  if (longs == 81){
    long_name <- "long_only"
  } else{
    long_name <- "all"
  }
  
  filename_new_single <- glue("term_freq_{folder}_rt_{retweets}_li_{likes}_lo_{long_name}.csv")
  filename_new_pairs <- glue("term_freq_{folder}_rt_{retweets}_li_{likes}_lo_{long_name}.csv")
  
  dest_path_single <- file.path(dest, filename_new_single)
  dest_path_pairs <- file.path(dest, filename_new_pairs)
  
  
  vroom_wrtite(term_frequency, dest_path_single, delim = ",")
  vroom_wrtite(pairs_df, dest_path_pairs, delim = ",")
  
  print(Sys.time()- time1)
}









# define the function which computes word frequencies per day for each filter combination
 
  

          
        





for (retweets in retweets_list){
  for (likes in likes_list){
    for (longs in long_list){


        for (folder in folders){
          if (folder == "Companies") {
            source_main <- "cleaned/appended/Companies"
            company_folders <- list.files(source_main)
            
            for (file in company_folders){
              
              dest <- file.path("term_freq/Companies")
              print(glue("Working on {file} for retweets: {retweets}, likes: {likes}, long:{long}"))
              time1 <- Sys.time()
              term_freq_computer(source = source_main, 
                                 file = file, 
                                 dest = dest)
              print(Sys.time() - time1)
            }
          
            
            } else if (grepl("NoFilter", folder)) {
            
            source <- file.path("cleaned", "appended", folder)
            dest <- "term_freq"
            
            
            # call function for each nofilter folder
            print(glue("Working on {file} for retweets: {retweets}, likes: {likes}, long:{long}"))
            time1 <- Sys.time()
            term_freq_computer(source = source, 
                               file = folder, 
                               dest = dest)
            
            print(Sys.time() - time1)
          }
          
        }
    }
  }
}






















