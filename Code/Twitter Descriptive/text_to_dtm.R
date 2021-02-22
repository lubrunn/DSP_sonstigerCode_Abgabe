library(corpus)
library(dplyr)
library(tm)
library(glue)


setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
######## read in cleaned data
###
folders <- list.files("cleaned")


likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,1)



#### for testing
folder <- folders[3]
file <- files[1]
retweets <- 0
likes <- 5
long <- 0



term_freq_computer <- function(folder) {  
  
  files <- list.files(source)
  
  
  
  # loop for likes filter
  for (likes in likes_list){
    # loop for retweets
    for (retweets in retweets_list){
      #loop for long dummy
      for (long in long_list){
        #loop over each file
        for (file in files){
          time1 <- Sys.time()
          df <- read_csv(file.path(source,file),
                         col_types = cols_only(doc_id = "c",text = "c",
                                               created_at = "c",
                                               retweets_count = "i",
                                               likes_count = "i", long_tweet = "i")) 
        
        
        df <- df %>% filter(
          likes_count >= likes,
          retweets_count >= retweets,
          #long_tweet == long
          long_tweet >= long
        )
        
        
        # remove words that dont at least appear in 1% of tweets
        threshold <- 0.01 * dim(df)[1]
        
        # compute term frequencies for the entire day
        term_frequency_n <-  df %>% 
          tidytext::unnest_tokens(word, text) %>%
          count(word) %>% 
          filter(n > threshold) %>%
          arrange(word) %>%
          t() %>% data.frame() %>%
          janitor::row_to_names(row_number = 1) 
        
        # convert to numeric
        term_frequency_n <- sapply(term_frequency_n, as.numeric) %>% data.frame()
        
        # store number of tweets to created term frequencies
        term_frequency_n$num_tweets <- dim(df)[1]
        
        
        
        # add column with date
        term_frequency_n$date <- stringr::str_extract(file, "[0-9]{4}-[0-9]{2}-[0-9]{2}")
        
        # append to df
        if  (!exists("term_frequency")) {
          term_frequency <- term_frequency_n
        } else {
          term_frequency <- dplyr::bind_rows(term_frequency, term_frequency_n)
        }
        print(Sys.time() - time1)
        }
        # save df
        filename_new <- glue("term_freq_{folder}_rt_{retweets}_li_{likes}_lo_{long}")
        dest_path <- file.path(dest, filename_new)
        write.csv(term_frequency, dest_path)
        
        
    }
  }
  }
}








for (folder in folders){
  if (grepl("Companies", folder)) {
    source_main <- file.path("cleaned", folder)
    company_folders <- list.files(source_main)
    
    for (company_folder in company_folders){
      source <- file.path("cleaned", folder, company_folder)
      dest <- file.path("term_freq", folder, company_folder)
      # if folder doesnt exist, create it
      dir.create(dest, showWarnings = FALSE)
      term_freq_computer(company_folder)
    }
  } else if (grepl("NoFilter", folder)) {
    source <- file.path("cleaned", folder)
    dest <- file.path("term_freq", folder)
    # if folder doesnt exist, create it
    dir.create(dest, showWarnings = FALSE)
    
    # call function for each nofilter folder
    term_freq_computer(folder)
  }
  
}






















