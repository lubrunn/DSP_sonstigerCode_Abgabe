library(dplyr)
library(tidytext)
library(textclean)
library(hunspell)
library(readr)
library(corpus)

vpc = FALSE

# read in data
if (vpc == T) {
  setwd("/home/lukasbrunner/share/onedrive/Data/Twitter")
} else {
  setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
}

path_source <- "pre_cleaned"
path_dest <- "text_cleaned"





folders <- list.files(path_source)

file <- files[1]
tweets_raw <- readr::read_csv(file.path(path,file),
                              col_types = cols(.default = "c", lat = "d", long = "d",
                                               retweets_count = "i", replies_count = "i",
                                               likes_count = "i", tweet_length = "i"))

#a <- head(tweets_raw, 1000)

# function that removes consecutive duplicates
dup_remover <- function(string){
  
  string <- paste(rle(unlist(string))$values, collapse = " ")
  return(string)
}

# stemming function
stem_hunspell <- function(term) {
  # look up the term in the dictionary
  stems <- hunspell::hunspell_stem(term)[[1]]
  
  if (length(stems) == 0) { # if there are no stems, use the original term
    stem <- term
  } else { # if there are multiple stems, use the last one
    stem <- stems[[length(stems)]]
  }
  
  stem
}


df_cleaner <- function(df){
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

#remove special characters
tweets$text <- gsub("[^A-Za-z]", " ", tweets$text)


######### stemming

# check if text column converted to list, then one knows that funciton run without errors
# otherwise c++ error may appear which does not abort function but simply does nothing

# try 5 times
for (i in 1:5){
  if (class(tweets$text) == "character"){
    print(paste0("Attempt",i))
    tweets$text <- text_tokens(tweets$text, stemmer = stem_hunspell)
  }
}

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

# remove stopwords, remove face because it appears very often thru conversion of emojis/emoticons to text 
# e.g. :D becomes lauging face, :) = smiling face --> so a lot of face words get created
tweets$text <- removeWords(tweets$text,c(tm::stopwords("SMART"),
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


# include dummy term when tweet longer than median
tweets$long_tweet <- ifelse(tweets$text_length > 80, 1, 0)



print(glue("The process took {Sys.time() - time1}"))

}







#######################################
#### save cleaned file
######################################
# parquetfile
path_save = "C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/text_cleaned/En_NoFilter/En_NoFilter_2020-04-01_cleaned.csv"
readr::write_csv(tweets, path_save)


