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





likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)


files <- list.files(file.path("cleaned", folder))
#### for testing
folder <- folders[3]
file <- files[4]
retweets <- 0
likes <- 0
longs <- 0


df <- read_csv(file.path("cleaned",folder, file),
               col_types = cols(.default = "c",text = "c",
                                created_at = "c",
                                retweets_count = "i",
                                long = "i", lat = "i",
                                likes_count = "i", tweet_length = "i"))

df_all <- rbind(df, df2, df3, df4)



################################################################################
################################################################################
'
This function takes one already appended file and computes the term frequencies
per day accroding to given filters

'
term_freq_computer <- function(source, file, dest){
  # read data
  df <- read_csv(file.path(source,file),
                 col_types = cols_only(doc_id = "c",text = "c",
                                       created_at = "c",
                                       retweets_count = "i",
                                       likes_count = "i", tweet_length = "i")) 
  
  
  
  
  
  # remove words that dont at least appear in 1% of tweets
  # for this compute number of tweets per day and from this take
  # average in order to approximate how many times each word should appear
  num_tweets <- df %>% filter(
    likes_count >= likes &
      retweets_count >= retweets &
      #long_tweet == long
      tweet_length >= longs)%>%
    group_by(date) %>%
    summarise(n = tweets_amnt) %>%
    ungroup() 
  
  threshold <- round(0.01 *  mean(threshold$tweets_amnt))
  
  # compute term frequencies for the entire day
  term_frequency <-  df %>% 
    tidytext::unnest_tokens(word, text) %>%
    group_by(date, language, word) %>%
    summarise(n = n()) %>%
    filter(n > threshold) %>%
    pivot_wider(names_from = word, values_from = n) %>%
    ungroup() %>%
    replace(is.na(.), 0) %>%
    left_join(num_tweets, by = "date")
  
  
  # save df
  print("Saving file")
  if (longs == 81){
    long_name <- "long_only"
  } else{
    long_name <- "all"
  }
  filename_new <- glue("term_freq_{folder}_rt_{retweets}_li_{likes}_lo_{long_name}.csv")
  dest_path <- file.path(dest, filename_new)
  write_csv(term_frequency, dest_path)
}









# define the function which computes word frequencies per day for each filter combination
 
  
 files <- list.files(source)
  
  
  
 
for (file in files){
    
}
          
        





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






















