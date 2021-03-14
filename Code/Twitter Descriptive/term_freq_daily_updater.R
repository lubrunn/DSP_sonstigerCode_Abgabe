#library(corpus)
library(dplyr)
#library(tm)
library(glue)
library(tidyr)
library(data.table)
library(tidytext)

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
  setwd("/home/lukasbrunner/share/onedrive_new2/Data/Twitter")
} else {
  setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
}
################################################################################
################################################################################
################################################################################
emoji_words <- c(
  "plead","scream", "social media", "steam", "nose" , "box", "circl", "whit",
  "black", "button","exo", "sad",
  "love", "good", "red", "happi","mu",
  "happi","excus","tongu","stick", "tear", "joy", "flag", "skin",  "smile",
  "heart","eye", "index", "medium", "laugh", "loud", "roll", "floor","mark", "exclam",
  "hand", "clap","dollar",
  "hot", "light","blow", "kiss","amulet", "head", "tree","speaker","symbol","money","point",
  "grin","bicep","flex","note","popper","fist","car","follow","retweet","year","ago",
  "social media","woman","voltag","star","ball","camera","man","ass","video","cake","cool",
  "fac","smil","see","evil","party","sweat","thumb","big","the","crying","fing",
  "crossed","god","watch","leaf","food","arrow", "hugg", "cri", "tone"
  
)

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
  
  
  df <- df %>% 
    filter(
      likes_count >= likes_filter &
        retweets_count >= retweets_filter &
        #long_tweet == long
        tweet_length >= length_filter
    ) %>%
    
    unnest_tokens(word, text, to_lower = F) 
  
  
  
  
  
  return(df)
  Sys.time() - time1
}




###### new
# term_freq_calc2 <- function(df,threshold_single, retweets_filter, likes_filter, length_filter){
#   time1 <- Sys.time()
#   print("Trying separate_rows")
#   df <- df %>% filter(
#     likes_count >= likes_filter &
#       retweets_count >= retweets_filter &
#       #long_tweet == long
#       tweet_length >= length_filter)%>%
#     
#     separate_rows(text, sep = ' ')
#   
#   return(df)
#   Sys.time() - time1
# }

################################################################################
################################################################################
'
This function takes one already appended file and computes the term frequencies
per day accroding to given filters

'
term_freq_computer <- function(df, file, dest, 
                               
                               retweets_filter,
                               likes_filter,
                               length_filter,
                               long_name,
                               filename_new_single,
                               filename_new_bi,
                               min_occ){
  
  
  #### define date and language varaible names
  if (grepl("NoFilter", filename_new_bi)){
    date_variable <- "date"
    language_variable <- "language"
  } else {
    date_variable <- "date_variable"
    language_variable <- "language_variable"
  }
  
  # drop if tweet text ist missing
  df <- df %>% tidyr::drop_na("text")
  
  # remove words that dont at least appear in 1% of tweets
  # for this compute number of tweets per day and from this take
  # average in order to approximate how many times each word should appear
  
  
  # Sys.time() - time1
  
  # 1 percent of average number of tweets per day, but at least 5 times
  threshold_single <- max(round(0.01 *  dim(df)[1]), min_occ)
  threshold_pairs <- max(round(0.001 * dim(df)[1]), min_occ)
  
  
  
  
  
  
  # selector<-function(df,threshold_single, retweets_filter, likes_filter, length_filter){
  #   
  #   df <- try(term_freq_calc1(df,threshold_single, retweets_filter, likes_filter, length_filter))
  #   if(is(df, "try-error")) {
  #     df <- term_freq_calc2(df,threshold_single, retweets_filter, likes_filter, length_filter)
  #   }
  #   return(df)
  # }
  # 
  # 
  # ###### to alternatives for term_freq computation because first is very quick but throws
  # # random non reproduciable errors at times, other funciton is more consistent but takes
  # # twice as long
  # print("Started computing frequencies")
  # df <- selector(df,threshold_single, retweets_filter, likes_filter, length_filter)
  # print("Finshed computing frequenies")
  # 
  
  # convert date as string for sql
  # df$date_variable <- as.character(df$date_variable)
  
  df1 <- df %>% 
    filter(
      likes_count >= likes_filter &
        retweets_count >= retweets_filter &
        #long_tweet == long
        tweet_length >= length_filter
    ) %>%
    
    tidytext::unnest_tokens(word, text, to_lower = F) 
  # turn into datatable
  setDT(df1)
  # aggregate
  df1 <- df1[,.(.N), by = c(date_variable,language_variable, "word")]
  # filter
  df1 <- df1[N > threshold_single & !is.na(word)&
               nchar(word) > 1,]
  # spread
  #df_emo1  <- dcast(df1, ... ~ word , value.var = "N")
  
  
  
  
  df1$retweets_count <- retweets_filter
  df1$likes_count <- likes_filter
  df1$tweet_length <- length_filter
  # add boolean whether the text contains some emoji word
  df1[, emo := grepl(paste(emoji_words, collapse = "|"), word)]
  
  
  
  ############################
  ##### bigrams
  df2 <- df %>% 
    filter(
      likes_count >= likes_filter &
        retweets_count >= retweets_filter &
        #long_tweet == long
        tweet_length >= length_filter
    ) %>%
    
    tidytext::unnest_tokens(word, text, token = "ngrams", n = 2) 
  
  # turn into datatable
  setDT(df2)
  # aggregate
  df2 <- df2[,.(.N), by = c(date_variable,language_variable, "word")]
  # filter
  df2 <- df2[N > threshold_pairs & !is.na(word) &
               nchar(word) > 2,]
  
  # add info on used filters for data
  df2$retweets_count <- retweets_filter
  df2$likes_count <- likes_filter
  df2$tweet_length <- length_filter
  
  # add boolean whether the text contains some emoji word
  df2[, emo := grepl(paste(emoji_words, collapse = "|"), word)]
  
  
  
  ###################################
  ######################## saving
  ###################################
  
  
  ### paths to destination
  dest_path_single <- file.path(dest,"uni_appended", filename_new_single)
  dest_path_bi <- file.path(dest,"bi_appended", filename_new_bi)
  
  
  ######################################
  ###### append data to existing df
  
  #### save unigrams
  write.table(df1, dest_path_single, 
              append = T, sep = ",",
              row.names = F, col.names = F)
  
  ### save bigrams
  write.table(df2, dest_path_bi,
              append = T, sep = ",",
              row.names = F, col.names = F)
  
  
  
}









# define the function which computes word frequencies per day for each filter combination


# folder <- folders_NoFilter[1]
# file <- files[1]
# source_main = source_main_NoFilter




######### function to find last update

last_update_finder <- function(dest, likes_filter, retweets_filter, 
                               long_name, subfolder_source){
  
  #### account for diffrent structure in commpaneis folder
  
  
  
  ##### read bigram file
  subfolder <- "bi_appended"
  files <- list.files(file.path(dest,subfolder))
  filename_addon <- glue::glue("{subfolder_source}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
  file <- files[grepl(filename_addon, files)]
  
  #### read in only last line to see what last date was
  l2keep <- 1
  nL <- R.utils::countLines(file.path(dest,subfolder, file))
  last_update_bi <- read.csv(file.path(dest,subfolder, file), header=FALSE, skip=nL-l2keep) %>% select(V1) %>% unlist()
  
  
  
  #### last update uni
  subfolder <- "uni_appended"
  files <- list.files(file.path(dest,subfolder))
  filename_addon <- glue::glue("{subfolder_source}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
  file <- files[grepl(filename_addon, files)]
  
  #### read in only last line to see what last date was
  l2keep <- 1
  nL <- R.utils::countLines(file.path(dest,subfolder, file))
  last_update_uni <- read.csv(file.path(dest,subfolder, file), header=FALSE, skip=nL-l2keep) %>% select(V1) %>% unlist()
  
  ### get minimum of both
  last_update <- min(as.Date(last_update_bi), as.Date(last_update_uni))
  
  return(last_update)
}















########## loop for each file function, loads file and computes term freq for uni and bigrams, then appends results
file_looper <- function(source_main, folder,subfolder_comp, files,
                        retweets_filter, likes_filter, length_filter,
                        long_name, filename_addon){
  for (file in files){
    
    if (grepl("NoFilter", folder)){
      df <- readr::read_csv(file.path(source_main,folder, file),
                            col_types = readr::cols_only(doc_id = "c",text = "c",
                                                         created_at = "c",
                                                         retweets_count = "i",
                                                         likes_count = "i", tweet_length = "i",
                                                         language = "c")) 
      
      df$date <- as.Date(df$created_at, "%Y-%m-%d")
      
      
      print("Loaded data, renaming variables")
      # rename variables so no problems
      df <- df %>% select(date, language, text,
                          retweets_count, likes_count, tweet_length)
      
    } else if(grepl("Companies", folder)){
      
      df <- readr::read_csv(file.path(source_main,folder, subfolder_comp, file),
                            col_types = readr::cols_only(doc_id = "c",text = "c",
                                                         
                                                         created_at = "c",
                                                         retweets_count = "i",
                                                         likes_count = "i", tweet_length = "i",
                                                         language = "c"))
      
      df$created_at <- as.Date(df$created_at, "%Y-%m-%d")
      df$company <- subfolder_comp
      
      
      print("Loaded data, renaming variables")
      # rename variables so no problems
      df <- df %>% rename(date_variable = created_at, 
                          language_variable = language,
                          company_variable = company) %>%
        select(doc_id, company_variable, date_variable, text, 
               retweets_count, likes_count, tweet_length, language_variable)
      
      
    }
    
    
          
          
    
    
    
    
    if(grepl("Companies", folder)){
      
      # destination for file to be saved
      dest <- file.path("term_freq/Companies")
      
      
      
      
      
        
      filename_new_single <- glue("term_freq_{filename_addon_comp}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
      filename_new_bi <- glue("term_freq_{filename_addon_comp}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
      
      
      
      
      
      print(glue("Working on {file} for retweets: {retweets_filter}, likes: {likes_filter}, long:{length_filter}"))
      # check if file already exists at destination, otherwise compute it
      
      time1 <- Sys.time()
      term_freq_computer(df, 
                         file = file, 
                         dest = dest,
                         retweets_filter,
                         likes_filter,
                         length_filter,
                         long_name,
                         filename_new_single,
                         filename_new_bi,
                         min_occ = 2)
      print(Sys.time() - time1)
        
      }
      
    
    else if (grepl("NoFilter", folder)) {
      
      source <- file.path(source_main, folder)
      dest <- file.path("term_freq", folder)
      
      
      # check if file exists at destination
      
      
      filename_new_single <- glue("uni_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
      filename_new_bi <- glue("bi_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}.csv")
      
      
      
      
      # call function
      # call function for each nofilter folder
      time1 <- Sys.time()
      print(glue("Working on {file} for retweets: {retweets_filter}, likes: {likes_filter}, long:{length_filter}"))
      term_freq_computer(df, 
                         file = file, 
                         dest = dest,
                         retweets_filter,
                         likes_filter,
                         length_filter,
                         long_name,
                         filename_new_single,
                         filename_new_bi,
                         min_occ = 5)
      print(glue("Process for {file} took {Sys.time() - time1}"))
      
      
      
    } # if nofilter folder
    
    
    
    # loops
    
  }
}
  










############################################## function to put everything in loop
compute_all_freq <- function(source_main, folders, 
                             retweets_list, likes_list, long_list){
  for (folder in folders){
    for (retweets_filter in retweets_list){
      for(likes_filter in likes_list){
        for(length_filter in long_list){
          
          # for naming files
          print(glue("Working on {folder}, rt: {retweets_filter},likes: {likes_filter}, length: {length_filter}"))
          if (length_filter == 81){
            long_name <- "long_only"
          } else{
            long_name <- "all"
          }
          
          ##### account for deviating company folders name (destinaten != source)
          if (grepl("Companies", folder)){
            dest <- "term_freq/Companies"
            
            subfolders_comp <- list.files(file.path(source_main, folder))
            
            for (subfolder_comp in subfolders_comp){
              print(glue("Working on {subfolder}"))
              #### get last update
              filename_addon_comp <- glue("{subfolder_comp}_all") 
              last_update <- last_update_finder(dest, likes_filter, retweets_filter, long_name,
                                                subfolder_source = filename_addon_comp)
              
              
              #### last available date at source
              ## source
              source <- file.path(source_main, folder, subfolder_comp)
              
              #### get all files at source
              all_files <- list.files(source)
              
              #### find last available date
              last_date_avail <- max(parsedate::parse_date(all_files)) 
              
              ####### find dates that still need to be updated
              #### check if lastupdate actually smaller then last date avail
              if (as.Date(last_update) < as.Date(last_date_avail)) {
                dates_missing <- seq(as.Date(last_update) + lubridate::days(1) , as.Date(last_date_avail), by="days")
              } else {
                ##### if up to date move on to next loop
                print("no missing dates found")
                next 
              }
                                   
               ### only start process for files that are missing
               files_missing <- all_files[grepl(paste(dates_missing,collapse = "|"), all_files)]
               
               
               ##### now start loop for these files
               file_looper(source_main, folder, subfolder_comp, files_missing,
                           retweets_filter, likes_filter, length_filter,
                           long_name, filename_addon_comp)
            }
            
          } else {
            dest <- file.path("term_freq", folder)
            
            
            #### get last update
            last_update <- last_update_finder(dest, likes_filter, retweets_filter, long_name,
                                              subfolder_source = folder)
            #### last available date at source
            ## source
            source <- file.path(source_main, folder)
            
            #### get all files at source
            all_files <- list.files(source)
            
            #### find last available date
            last_date_avail <- max(parsedate::parse_date(all_files)) 
            
            ####### find dates that still need to be updated
            if (as.Date(last_update) < as.Date(last_date_avail)) {
              dates_missing <- seq(as.Date(last_update) + lubridate::days(1) , as.Date(last_date_avail), by="days")
            } else {
              ##### if up to date move on to next loop
              next
            }            
            
            ### only start process for files that are missing
            files_missing <- all_files[grepl(paste(dates_missing,collapse = "|"), all_files)]
            
            
            ##### now start loop for these files
            file_looper(source_main,folder = folder,subfolder = folder,files = files_missing,
                        retweets_filter, likes_filter, length_filter,
                        long_name, filename_addon = folder)
          }
          
          
          
          
          
          
          
          
          
          
        } ##### length loop
      }#### likes loop
    } ###rt loop
  } ### folders loop
}




# for testing
# retweets_filter <- 0
# likes_filter <- 0
# length_filter <- 0



likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)

source_main <- "cleaned"
#source_main_comp <- "cleaned/appended"
folders <- c("En_NoFilter", "De_NoFilter", "Companies2")







################################################################################
################################ Call function #################################
# For NoFilter
compute_all_freq(source_main = source_main, folders = folders, 
                 retweets_list, likes_list, long_list)










