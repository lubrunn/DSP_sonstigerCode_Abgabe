library(corpus)
library(dplyr)
library(tm)
library(glue)
library(vroom)
library(tidyr)

#################################################################################
#################################################################################

'
Here we compute term frequencies per day in order to increase execution speed in the app.
We preprocess for every possible combination the user will be able to choose.
We then aggregate each data for the live filtering for the date range. For the
other filter methods (retweets etc.) each filter has its own file (or its all
in sql table if we have enough time to upload it all)
'




################################################################################
################################################################################
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
################################################################################
################################################################################


# testing




#### for testing
# df <- vroom(file.path("cleaned/appended/En_NoFilter_701_813_lessCols.csv"),
#                col_types = cols(.default = "c",text = "c",
#                                 date = "c",
#                                 retweets_count = "i",
#                                 
#                                 likes_count = "i", tweet_length = "i"),
#             delim = ",")


################################################################################
term_freq_calc1 <- function(df,threshold_single, retweets_filter, likes_filter, length_filter){
  print("Trying unnest_tokens")
  time1 <- Sys.time()
  term_frequency <- df %>% filter(
    likes_count >= likes_filter &
      retweets_count >= retweets_filter &
      #long_tweet == long
      tweet_length >= length_filter)%>%

    tidytext::unnest_tokens(word, text, to_lower = F) %>%
    group_by(date_variable, language_variable, word) %>%
    summarise(n = n())  %>%
    filter(n > threshold_single) %>%
    pivot_wider(names_from = word, values_from = n)  %>%
    ungroup() %>%
    #replace_na(list(0)) %>%
    #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
    mutate(
      #across(-c(date_variable, language_variable), ~replace_na(.x, 0)),
      retweets_count = retweets_filter,
           likes_count = likes_filter,
           tweet_length = length_filter
           )
  
  # term_frequency <- df %>%
  #   
  #   filter(
  #     likes_count >= likes_filter &
  #       retweets_count >= retweets_filter &
  #       #long_tweet == long
  #       tweet_length >= length_filter
  #   ) %>%
  #   
  #   unnest_tokens(word, text, to_lower = F) 
  
  return(term_frequency)
  Sys.time() - time1
}




###### new
term_freq_calc2 <- function(df,threshold_single, retweets_filter, likes_filter, length_filter){
  time1 <- Sys.time()
  print("Trying separate_rows")
  term_frequency2 <- df %>% filter(
    likes_count >= likes_filter &
      retweets_count >= retweets_filter &
      #long_tweet == long
      tweet_length >= length_filter)%>%
    
    separate_rows(text, sep = ' ') %>%
    group_by(date_variable, language_variable, text) %>%
    summarise(n = n())   %>% 
    filter(n > threshold_single) %>%
    pivot_wider(names_from = text, values_from = n)  %>%
    ungroup() %>%
    #replace_na(list(0)) %>%
    #left_join(num_tweets, by = c("date_variable","language_variable")) %>%
    mutate(
      #across(-c(date_variable, language_variable), ~replace_na(.x, 0)),
      retweets_count = retweets_filter,
           likes_count = likes_filter,
           tweet_length = length_filter,
           ) 
  return(term_frequency2)
  Sys.time() - time1
}

################################################################################
################################################################################
'
This function takes one already appended file and computes the term frequencies
per day accroding to given filters

'
term_freq_computer <- function(df, file, dest, filename_old,
                               likes_filter,
                               retweets_filter,
                               length_filter,
                               long_name){
  # read data
  time2 <- Sys.time()
  
  # drop if tweet text ist missing
  df <- df %>% tidyr::drop_na("text")
  
  # remove words that dont at least appear in 1% of tweets
  # for this compute number of tweets per day and from this take
  # average in order to approximate how many times each word should appear
  
  
  num_tweets <- df %>% filter(
    likes_count >= likes_filter &
      retweets_count >= retweets_filter &

      tweet_length >= length_filter)%>%
    group_by(date_variable, language_variable) %>%
    summarise(tweets_amnt = n()) %>%
    ungroup()
  # Sys.time() - time1
  
  # 1 percent of average number of tweets per day
  threshold_single <- round(0.01 *  mean(num_tweets$tweets_amnt))
  #threshold_pairs <- round(0.001 *  mean(num_tweets$tweets_amnt))
  
  
   
  

  
  selector<-function(df,threshold_single, retweets_filter, likes_filter, length_filter){
    
    term_frequency1 <- try(term_freq_calc1(df,threshold_single, retweets_filter, likes_filter, length_filter))
    if(is(term_frequency1, "try-error")) {
    term_frequency1 <- term_freq_calc2(df,threshold_single, retweets_filter, likes_filter, length_filter)
    }
     return(term_frequency1)
  }
  
  
  ###### to alternatives for term_freq computation because first is very quick but throws
  # random non reproduciable errors at times, other funciton is more consistent but takes
  # twice as long
  print("Started computing frequencies")
  term_frequency <- selector(df,threshold_single, retweets_filter, likes_filter, length_filter)
  print("Finshed computing frequenies")
  
  
  
  
  # # turn into datatable
  # term_frequency <- data.table::as.data.table(term_frequency)
  # # aggregate
  # term_frequency <- term_frequency[,.(.N), by = c("date_variable","language_variable", "word")]
  # # filter
  # term_frequency <- term_frequency[N > threshold_single & !is.na(word),]
  # # spread
  # term_frequency  <- dcast(term_frequency, ... ~ word , value.var = "N")
  # 
  # 
  # 
  # 
  # term_frequency$retweets_count <- retweets_filter
  # term_frequency$likes_count <- likes_filter
  # term_frequency$tweet_length <- length_filter
  
  
  
  
  
  
  
  
  
  
  
  # save df
  
  
  
  
  filename_new_single <- glue("term_freq_{filename_old}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
  #filename_new_pairs <- glue("pair_count_{folder}_rt_{retweets}_li_{likes}_lo_{long_name}.csv")
  
  dest_path_single <- file.path(dest, filename_new_single)
  #dest_path_pairs <- file.path(dest, filename_new_pairs)
  
  
  vroom_write(term_frequency, dest_path_single, delim = ",")
  #vroom_write(pairs_df, dest_path_pairs, delim = ",")
  
  print(glue("Entire term freq computation took {Sys.time()- time2}"))
}









# define the function which computes word frequencies per day for each filter combination





compute_all_freq <- function(source_main, folders, retweets_list, likes_list, long_list){
for (folder in folders){
  
    files <- list.files(file.path(source_main,folder))
    
    for (file in files){
      
      if (grepl("NoFilter", folder)){
      df <- vroom::vroom(file.path(source_main,folder, file),
                         col_types = cols_only(doc_id = "c",text = "c",
                                               created_at = "c",
                                               retweets_count = "i",
                                               likes_count = "i", tweet_length = "i",
                                               language = "c")) 
      
      df$date <- as.Date(df$created_at, "%Y-%m-%d")
      
      
      print("Loaded data, renaming variables")
      # rename variables so no problems
      df <- df %>% rename(date_variable = date, 
                          language_variable = language)
      
      } else if(folder == "Companies"){
        
        df <- vroom::vroom(file.path(source_main,folder, file),
                           col_types = cols_only(doc_id = "c",text = "c",
                                                 company = "c",
                                                 created_at = "c",
                                                 retweets_count = "i",
                                                 likes_count = "i", tweet_length = "i",
                                                 language = "c")) 
        
        df$date <- as.Date(df$created_at, "%Y-%m-%d")
        
        
        print("Loaded data, renaming variables")
        # rename variables so no problems
        df <- df %>% rename(date_variable = date, 
                            language_variable = language,
                            company_variable = company)
        
        
      }
      
      for (retweets_filter in retweets_list){
        
        for (likes_filter in likes_list){
          
          for (length_filter in long_list){
            
            
            # for naming files
            print("Saving file")
            if (length_filter == 81){
              long_name <- "long_only"
            } else{
              long_name <- "all"
            }
            
            
              
            if(folder == "Companies"){
              
              
              
                # destination for file to be saved
                dest <- file.path("term_freq/Companies")
                # filename of old file without the csv
                filename_old <- strsplit(file, "[.]")[[1]][1]
                
                
                print(glue("Working on {file} for retweets: {retweets_filter}, likes: {likes_filter}, long:{length_filter}"))
                # check if file already exists at destination, otherwise compute it
                if (file.exists(file.path(dest,glue("term_freq_{filename_old}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")))){
                  time1 <- Sys.time()
                  term_freq_computer(source = source_main, 
                                     file = file, 
                                     dest = dest)
                  print(Sys.time() - time1)
                  
                } else{
                  print(glue("File term_freq_{filename_old}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv already exists at {dest}"))
                }
              
            }
             else if (grepl("NoFilter", folder)) {
              
              source <- file.path(source_main, folder)
              dest <- file.path("term_freq", folder)
              
              
              # check if file exists at destination
              
              filename_old <- strsplit(file, "[.]")[[1]][1]
              
              if (!file.exists(file.path(dest,glue("term_freq_{filename_old}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")))){
                
                
                
                # call function
                # call function for each nofilter folder
                time1 <- Sys.time()
                print(glue("Working on {file} for retweets: {retweets_filter}, likes: {likes_filter}, long:{length_filter}"))
                term_freq_computer(df, 
                                   file = file, 
                                   dest = dest,
                                   filename_old,
                                   likes_filter,
                                   retweets_filter,
                                   length_filter,
                                   long_name = long_name)
                print(glue("Process for {file} took {Sys.time() - time1}"))
                
              } else{
                print(glue("File term_freq_{filename_old}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv already exists at {dest}"))
              }
              
              
            } # if nofilter folder
            
            
            
            # loops
            
          }
        }
      }
    }
  }
}
















# for testing
# retweets_filter <- 200
# likes_filter <- 200
# length_filter <- 0



likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)

source_main_NoFilter <- "cleaned"
spurce_main_comp <- "cleaned/appended"
folders_NoFilter <- c("En_NoFilter", "De_NoFilter")
folders_comp <- "Companies



"
folders <- "En_NoFilter"
folder <- folders[1]

file <- files[1]



################################################################################
################################ Call function #################################
# For NoFilter
compute_all_freq(source_main = source_main_NoFilter, folders = folders_NoFilter[1], 
                 retweets_list, likes_list, long_list)




# for companies
compute_all_freq(source_main = source_main_comp, folders = folders_comp, 
                 retweets_list, likes_list, long_list)





