library(corpus)
library(dplyr)
library(tm)
library(glue)


setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
######## read in cleaned data
###
folders <- list.files("cleaned")


likes_list <- c(0, 50, 100, 200)
retweets_list <- c(0, 50, 100, 200)
long_list <- c(0,1)

abc <- function(x){
  print(x * i)
}

#### for testing
folder <- folders[4]
file <- files[1]
retweets <- 10
likes <- 100
long <- 80

for (folder in folders){
  if (grepl("Companies", folder)) {
    source_main <- file.path("cleaned", folder)
    company_folders <- list.files(source)
    
    for (company_folder in company_folders){
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
          df <- read_csv(file.path(source,file),
                         col_types = cols_only(id = "c",tweet = "c",
                                               created_at = "c",
                                               retweets_count = "i",
                                               likes_count = "i", tweet_length = "i")) %>%
            rename(doc_id = id, text = tweet)
        
        
        df <- df %>% filter(
          likes_count >= likes,
          retweets_count >= retweets,
          #long_tweet == long
          tweet_length >= long
        )
        
        #set the schema:docs
        docs <- tm::DataframeSource(df)
        # convert to corpus
        text_corpus <- VCorpus(docs)
        
        dtm <- DocumentTermMatrix(text_corpus)
        #remove sparse words
        dtm <- removeSparseTerms(dtm, 0.99)
        # convert to matrix
        dtm_m <- as.matrix(dtm)
        
        # compute term frequencies for the entire day
        term_frequency_n <- colSums(dtm_m) %>% t() %>% data.frame()
        
        # add column with date
        term_frequency_n$date <- str_extract(file, "[0-9]{4}-[0-9]{2}-[0-9]{2}")
        
        # append to df
        if  (!exists("term_frequency")) {
          term_frequency <- term_frequency_n
        } else {
          term_frequency <- dplyr::bind_rows(term_frequency, term_frequency_n)
        }
        
        }
        # save df
        filename_new <- glue("term_freq_{folder}_rt_{retweets}_li_{likes}_lo_{long}")
        dest_path <- file.path(dest, filename_new)
        write.csv(df, dest_path)
    }
  }
  }
}



# parquet file
path2 = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2020-04-01_cleaned.parquet"
tweets <- arrow::read_parquet(path2)


#set the schema:docs
docs <- tm::DataframeSource(tweets)




#clean_corpus function from datacamp
# no need already cleaned previously
# clean_corpus <- function(corpus){
#         
#         
#         corpus <- tm_map(corpus, removeNumbers)
#         
#         corpus <- tm_map(corpus, removeWords,
#                          c(stopwords("SMART"), "amp"))
#         
#         return(corpus)
# }

text_corpus <- VCorpus(docs)






content(text_corpus[[1]])
#for standard meta data (including id)
meta(text_corpus[[1]])

#for all added meta data
meta(text_corpus[1])

dtm <- DocumentTermMatrix(text_corpus)
#remove sparse words
dtm <- removeSparseTerms(dtm, 0.99)
dtm_m <- as.matrix(dtm)

#check matrix
dtm_m[1,]



###########################################
## filter on meta data e.g. retweets_count
###########################################
meta_data <- meta(text_corpus)

# only keep values in dtm where retweets_count > 2
dtm_m_filt <- dtm_m[meta_data$retweets_count > 1,]
