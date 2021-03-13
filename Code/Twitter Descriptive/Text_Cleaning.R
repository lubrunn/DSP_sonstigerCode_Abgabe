library(dplyr)
library(tidytext)
library(textclean)
library(readr)
library(corpus)
library(stringr)
library(tm)

#################################################################################
#################################################################################

'
Here we clean the tweets
Rough Overview of steps:
  - replace emojis, emoticons with text
  - replace ratings with text
  - remove hashtags, handles, urls, email adresses,
  - remove extra whitespace
  - stem tweets 
  - remove stopwords
  - save 1 File per day per Main Folder

'




#################################################################################
#################################################################################


### this is simply for easier switching between vpcl and local
vpc = FALSE

# read in data
if (vpc == T) {
  setwd("/home/lukasbrunner/share/onedrive_new/Data/Twitter")
} else {
  setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
}

path_source <- "pre_cleaned"
path_dest <- "cleaned"



################################################################################
############################## Functions #######################################
################################################################################



# function that removes consecutive duplicates
dup_remover <- function(string){
  
  string <- paste(rle(unlist(string))$values, collapse = " ")
  return(string)
}

# stemming function, we use snowball now instead because although hunspell is better it takes
# very long (5min) per file --> 5 * 820 days * 2 main folders = 5+ days just for stemming
# snowball takes just few seconds in comparison, so we have a trade off where we prefer speed
# also hunspell throws c++ errors every once in a while completely randomly which increases
# time and mistake potential, hence we use snowball instead


# stem_hunspell <- function(term) {
#   # look up the term in the dictionary
#   stems <- hunspell::hunspell_stem(term)[[1]]
#   
#   if (length(stems) == 0) { # if there are no stems, use the original term
#     stem <- term
#   } else { # if there are multiple stems, use the last one
#     stem <- stems[[length(stems)]]
#   }
#   
#   stem
# }







####################################
##### Cleaning Function for english tweets
####################################

df_cleaner_english <- function(df){
print("Started Cleaning english tweets")
time1 <- Sys.time()
# select only relevant columns and change column names so one can keep meta data when turning data into to corpus
tweets <- df %>% rename("doc_id" = id, "text" =  tweet)


# tokenize words in order to filter out consecutive duplicates (assumption that they are from people accidentatly typing same same word twice)
tweets$text <- corpus::text_tokens(tweets$text)
# apply the duplicate remover function (only consecutive duplicates are removed)
tweets$text <- sapply(tweets$text, dup_remover)



## apply several functions from textcleaner package and other cleaning steps which are specifically made for messy text
# A L L becomes ALL
tweets$text <- replace_kern(tweets$text) 

### convert all tweets to lower case
tweets$text <- tolower(tweets$text)

####### Texclean functions
# replace special apostrophe with normal apostrophe (otherwise replace_contractions
# does not work for these cases)
tweets$text <- gsub("’", "'", tweets$text)


 # it's = it is
tweets$text <- replace_contraction(tweets$text)


# replace haven't because replace_contractions does not
tweets$text <- gsub("haven't", "have not", tweets$text)

#noooooooooooo becomes no
tweets$text <- replace_word_elongation(tweets$text) 

#remove email adresses
tweets$text <- replace_email(tweets$text) 


#replaces emoticons (emojis already replaced with python because quicker)
tweets$text <- replace_emoticon(tweets$text) 


#removes html markup: &euro becomes euro
tweets$text <- replace_html(tweets$text) 

# C+ becomes slightly above average
tweets$text <- replace_grade(tweets$text) 

#lol = laughing out loud --> lexical based --> not ideal but could not find better lexicon, most other lexicons were to aggressive and made things worse, hence we choose
# this middle ground
tweets$text <- replace_internet_slang(tweets$text)


#removes character strings with non-ASCII characters
tweets$text <- replace_non_ascii(tweets$text) 


#0/10 becomes terrible, 5 stars becomes best
tweets$text <- replace_rating(tweets$text) 

#removes escaped chars -> I go \r to the \t  next line becomes I go to the next line
tweets$text <- replace_white(tweets$text) 

### convert all tweets to lower case again because some replacements are in upper case
tweets$text <- tolower(tweets$text)


#adds space after comma so later one,two,three does not become onetwothree when removing special characters
tweets$text <- add_comma_space(tweets$text) 

# Get rid of hashtags
tweets$text <- stringr::str_replace_all(tweets$text,"#[a-z,A-Z]*","")

#remove special characters and numbers
tweets$text <- gsub("[^A-Za-z]", " ", tweets$text)



print("Finished with text cleaning, moving on to stemming")

######### stemming

# use simple stemming method because otherwise cleaning takes too long
#  hunspell -> with min per file --> 5 * 800 (files) * 2 foldersr = 5.5 days just for nofilter folders, without comapnies
# snwoball takes few seconds in comparison
tweets$text <- text_tokens(tweets$text, stemmer = "en")

    

# collapse text column list to one string again
tweets <-tweets %>% rowwise() %>%
  mutate(text = paste(text, collapse=' ')) %>%
  ungroup()


################

## spread hashtags (are in lists)
# collapse text column list to one string again
tweets <-tweets %>% rowwise() %>%
  mutate(hashtags = paste(hashtags, collapse=' ')) %>%
  ungroup()



#####################
##### stopword removal
######################
print("Removing stopwords")
# remove stopwords, remove face because it appears very often thru conversion of emojis/emoticons to text 
# e.g. :D becomes lauging face, :) = smiling face --> so a lot of face words get created
tweets$text <- tm::removeWords(tweets$text,c(tm::stopwords("SMART"),
                                         stopwords::stopwords("en", "snowball"),
                                         stopwords::stopwords("en", "nltk"),
                                         "face", #from emoji and emoticon replacement a lot of face terms
                                         "amp", #from html just in case function did not work
                                         "make", # personal choice 
                                         "gt")) #from html just in case function did not work

# remove whitespace again
#get rid of unnecessary white spaces
tweets$text <- stringr::str_squish(tweets$text)

########################
tweets <- tweets %>% tidyr::drop_na("text")


# include dummy term when tweet longer than median
tweets$long_tweet <- ifelse(tweets$tweet_length > 80, 1, 0)



print(glue("The process took {Sys.time() - time1}"))
return(tweets)
}





###########################################
######## Cleaning Function for german tweets
###########################################

df_cleaner_german <- function(df){
  print("Started Cleaning german tweets")
  time1 <- Sys.time()
  # select only relevant columns and change column names so one can keep meta data when turning data into to corpus
  tweets <- df %>% rename("doc_id" = id, "text" =  tweet)
  
  
  # tokenize words in order to filter out consecutive duplicates (assumption that they are from people accidentatly typing same same word twice)
  tweets$text <- corpus::text_tokens(tweets$text)
  # apply the duplicate remover function (only consecutive duplicates are removed)
  tweets$text <- sapply(tweets$text, dup_remover)
  
  
  
  ## apply several functions from textcleaner package and other cleaning steps which are specifically made for messy text
  # A L L becomes ALL
  tweets$text <- replace_kern(tweets$text) 
  
  ### convert all tweets to lower case
  tweets$text <- tolower(tweets$text)
  
  ####### Texclean functions
  # replace special apostrophe with normal apostrophe (otherwise replace_contractions
  # does not work for these cases)
  tweets$text <- gsub("’", "'", tweets$text)
  
  
  
  
  
  
  
  #noooooooooooo becomes no
  tweets$text <- replace_word_elongation(tweets$text) 
  
  #remove email adresses
  tweets$text <- replace_email(tweets$text) 
  
  
  #removes html markup: &euro becomes euro
  tweets$text <- replace_html(tweets$text) 
  
  
  
  
  #lol = laughing out loud --> lexical based --> not ideal but could not find better lexicon, most other lexicons were to aggressive and made things worse, hence we choose
  # this middle ground
  tweets$text <- replace_internet_slang(tweets$text)
  
  # replace emoticons --> translation to english but we think its better than dropping them
  tweets$text <- replace_emoticon(tweets$text) 
  
  
  #removes character strings with non-ASCII characters
  tweets$text <- replace_non_ascii(tweets$text) 
  
  
  #0/10 becomes terrible, 5 stars becomes best
   
  
  #removes escaped chars -> I go \r to the \t  next line becomes I go to the next line
  tweets$text <- replace_white(tweets$text) 
  
  ### convert all tweets to lower case again because some replacements are in upper case
  tweets$text <- tolower(tweets$text)
  
  
  #adds space after comma so later one,two,three does not become onetwothree when removing special characters
  tweets$text <- add_comma_space(tweets$text) 
  
  # Get rid of hashtags
  tweets$text <- stringr::str_replace_all(tweets$text,"#[a-z,A-Z]*","")
  
  # remove umlaute and scharfes s
  tweets$text <- stringi::stri_replace_all_fixed(
    tweets$text, 
    c("ä", "ö", "ü", "Ä", "Ö", "Ü", "ß"), 
    c("ae", "oe", "ue", "Ae", "Oe", "Ue", "ss"), 
    vectorize_all = F
  )
  
  #remove special characters and numbers
  tweets$text <- gsub("[^A-Za-z]", " ", tweets$text)
  
 
  
  print("Finished with text cleaning, moving on to stemming")

  ######### stemming
  tweets$text <-  text_tokens(tweets$text, stemmer = "de")

  # collapse text column list to one string again
  tweets <-tweets %>% rowwise() %>%
    mutate(text = paste(text, collapse=' ')) %>%
    ungroup()
  
  
  ################
  
  ## spread hashtags (are in lists)
  # collapse text column list to one string again
  tweets <-tweets %>% rowwise() %>%
    mutate(hashtags = paste(hashtags, collapse=' ')) %>%
    ungroup()
  
  
  
  #####################
  ##### stopword removal
  ######################
  print("Removing stopwords")
  # remove stopwords, remove face because it appears very often thru conversion of emojis/emoticons to text 
  # e.g. :D becomes lauging face, :) = smiling face --> so a lot of face words get created
  tweets$text <- tm::removeWords(tweets$text,c(
                                           stopwords::stopwords("de", "snowball"),
                                           stopwords::stopwords("de", "nltk"),
                                           #"face", #from emoji and emoticon replacement a lot of face terms
                                           "amp", #from html just in case function did not work
                                           #"make", # personal choice 
                                           "gt")) #from html just in case function did not work
  
  # remove whitespace again
  #get rid of unnecessary white spaces
  tweets$text <- stringr::str_squish(tweets$text)
  
  ########################
  tweets <- tweets %>% tidyr::drop_na("text")
  
  # include dummy term when tweet longer than median
  tweets$long_tweet <- ifelse(tweets$tweet_length > 80, 1, 0)
  
  
  
  print(glue("The process took {Sys.time() - time1}"))
  return(tweets)
  
  
  
  
}









################################################################################
############################### Process ########################################
################################################################################


# list all folders
folders <- list.files(path_source)

# select subset of folder



# go thru all main folders 
for (folder in folders){
  if (folder %in% c("De_NoFilter", "En_NoFilter")){
    # for nofilter folders find source and destination and check which files are missing
    files_source <- list.files(file.path(path_source, folder))
    files_dest <- list.files(file.path(path_dest, folder))
    files <- setdiff(files_source, files_dest)
    
    # for every missing file
    for (file in files){
      print(glue("Started working on {file}."))
      # load the data
      df <- readr::read_csv(file.path(path_source,folder, file),
                            col_types = cols(.default = "c", lat = "d", long = "d",
                                             retweets_count = "i", replies_count = "i",
                                             likes_count = "i", tweet_length = "i"))
      
      # clean dataframe
      if (folder == "En_NoFilter"){
        df <- try(df_cleaner_english(df))
        if(inherits(df, "try-error"))
        {
          next
        }
      } else if (folder == "De_NoFilter"){
        df <- try(df_cleaner_german(df))
        if(inherits(df, "try-error"))
        {
          next
        }
      }
    
      if (dim(df)[1] > 0){
    # save df
    path_save <- file.path(path_dest, folder, file)
    readr::write_csv(df, path_save)
    print("File saved, moving on to next file.")
      }
    }
    
  } else if (folder == "Companies2"){
    # for all company folders go one level deeper
    subfolders <- list.files(file.path(path_source, folder))
    
    
    for (subfolder in subfolders){
      
      
      # if subfolder does not exist at destination create it
      dir.create(file.path(path_dest, folder, subfolder), showWarnings = FALSE)
      
      # find files that are in source but not in destination i.e. find files that still need to be cleaned
      files_source <- list.files(file.path(path_source, folder, subfolder))
      files_dest <- list.files(file.path(path_dest, folder, subfolder))
      # files in source but not in destination
      files <- setdiff(files_source, files_dest)
      
      # for every missing file
      for (file in files){
        print(glue("Started working on {file}."))
        # load data
        df <- readr::read_csv(file.path(path_source,folder,subfolder, file),
                              col_types = cols(.default = "c", lat = "d", long = "d",
                                               retweets_count = "i", replies_count = "i",
                                               likes_count = "i", tweet_length = "i"))
        
        #separete german and englisch tweets
        df_de <- df %>% filter(language == "de")
        df_en <- df %>% filter(language == "en")
        
        # clean dataframes
        if (dim(df_de)[1] > 0){
          df_de <- try(df_cleaner_german(df_de))
          if(inherits(df_de, "try-error"))
          {
            print("Error in cleaning german dataframe")
            next
          }
          }
        if (dim(df_en)[1] > 0){
          df_en <- try(df_cleaner_english(df_en))
          if(inherits(df_en, "try-error"))
          {
            print("Error in cleaning english dataframe")
            next
          }
        }
        
        
        if (dim(df_de)[1] > 0 & dim(df_en)[1] > 0){
        #put data back togethter (we store company data together because there arent as many tweets in the company files)
        df <- rbind(df_de, df_en)
        } else if (dim(df_de)[1] > 0 & dim(df_en)[1] == 0){
          df <- df_de
        } else if (dim(df_de)[1] == 0 & dim(df_en)[1] > 0){
        df <- df_en
          }
        
        # save df
        path_save = file.path(path_dest, folder, subfolder, file)
        readr::write_csv(df, path_save)
        print("File saved, moving on to next file.")
      }
    }
  }
}


