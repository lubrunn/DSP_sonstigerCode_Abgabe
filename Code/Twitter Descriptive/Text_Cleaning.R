if(!require("corpus")) install.packages("corpus")
if(!require("hunspell")) install.packages("hunspell")
# install.packages("stopwords")

#library(tidyverse)

library(dplyr)




library(tidytext)


#install.packages('rJava')
#library('rJava')

#library(qdap)

library(textclean)


library(hunspell)
library(readr)
library(corpus)


# read in data
setwd("/home/lukasbrunner/share/onedrive/Data/Twitter")
# tweets_raw <- stream_in(file(r"(C:\Users\lukas\OneDrive - UT Cloud\DSP_test_data\raw_test\En_NoFilter\En_NoFilter_2020-04-01.json)"))

path <- "raw_csv/En_NoFilter"


time1 <- Sys.time()
files <- list.files(path)
file <- files[1]
tweets_raw <- readr::read_csv(file.path(path,file),
                              col_types = cols(.default = "c", lat = "d", long = "d",
                                               retweets_count = "i", replies_count = "i",
                                               likes_count = "i", tweet_length = "i"))

#a <- head(tweets_raw, 1000)


# select only relevant columns and change column names so one can keep meta data when turning data into to corpus
tweets <- tweets_raw %>% rename("doc_id" = id, "text" =  tweet)



# testing with single tweet
#tweets <- tweets[1,]
# tweets$text <- "Mr. Jones &amp; Jones Jones don't don't can't shouldn't haven't @twitter_user123 it's so soooooooooooo rate T H I S movie 0/10 VeRy BAD ???? :D lol and stopwords i could have really done it myself, one,two,three"

tweets$text <- corpus::text_tokens(tweets$text)

# function that removes consecutive duplicates
dup_remover <- function(string){
  
  string <- paste(rle(unlist(string))$values, collapse = " ")
  return(string)
}

tweets$text <- sapply(tweets$text, dup_remover)




###
tweets$text <- replace_kern(tweets$text) # A L L becomes ALL


### convert all tweets to lower case
time2 <- Sys.time()
tweets$text <- tolower(tweets$text)
print(Sys.time() - time2)

#a <- head(tweets, 1000)




####### Texclean functions
# replace special apostrophe with normal apostrophe (otherwise replace_contractions
# does not work for these cases)
tweets$text <- gsub("’", "'", tweets$text)
#Mr. = Mister
# tweets$text <- qdap::replace_abbreviation(tweets$text)  
# it's = it is
time2 <- Sys.time()
tweets$text <- replace_contraction(tweets$text)
print(Sys.time() - time2)

# replace haven't because replace_contractions does not
tweets$text <- gsub("haven't", "have not", tweets$text)
#noooooooooooo becomes no
time2 <- Sys.time()
tweets$text <- replace_word_elongation(tweets$text) 
print(Sys.time() - time2)
#remove email adresses
time2 <- Sys.time()
tweets$text <- replace_email(tweets$text) 
print(Sys.time() - time2)

#replaces emoticons
time2 <- Sys.time()
tweets$text <- replace_emoticon(tweets$text) 
print(Sys.time() - time2)

#removes html markup: &euro becomes euro
time2 <- Sys.time()
tweets$text <- replace_html(tweets$text) 
print(Sys.time() - time2)
# C+ becomes slighlty above average
tweets$text <- replace_grade(tweets$text) 
#lol = laughing out loud
time2 <- Sys.time()
tweets$text <- replace_internet_slang(tweets$text)
print(Sys.time() - time2)




#replaces with a unique identifier that corresponds to lexicon::hash_sentiment_emoji
# already done in python
# tweets$text <- replace_emoji_identifier(tweets$text) 
#removes chracter strings with non-ASCII chracters
time2 <- Sys.time()
tweets$text <- replace_non_ascii(tweets$text) 
print(Sys.time() - time2)

#removes twitter handles, already done in python
# tweets$text <- replace_tag(tweets$text) 

#0/10 becomes terrible, 5 stars becomes best
tweets$text <- replace_rating(tweets$text) 

#removes urls from text already done in python
# tweets$text <- replace_url(tweets$text) 
#removes escaped chars -> I go \r to the \t  next line becomes I go to the next line
tweets$text <- replace_white(tweets$text) 
### convert all tweets to lower case
tweets$text <- tolower(tweets$text)


#adds space after comma so later one,two,three does not become onetwothree
tweets$text <- add_comma_space(tweets$text) 



# Get rid of hashtags
time2 <- Sys.time()
tweets$text <- stringr::str_replace_all(tweets$text,"#[a-z,A-Z]*","")
print(Sys.time() - time2)


#remove special , note: this also removes emojis
tweets$text <- gsub("[^A-Za-z]", " ", tweets$text)



######### stemming
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




## spread hashtags
# collapse text column list to one string again
tweets <-tweets %>% rowwise() %>%
  mutate(hashtags = paste(hashtags, collapse=' ')) %>%
  ungroup()






# remove stopwords, remove face because it appears very often thru conversion of emojis/emoticons to text 
# e.g. :D becomes lauging face, :) = smiling face --> so a lot of face words get created
tweets$text <- removeWords(tweets$text,c(tm::stopwords("SMART"),
                                         stopwords::stopwords("en", "snowball"),
                                         stopwords::stopwords("en", "nltk"),
                                         "face",
                                         "amp",
                                         "make",
                                         "gt"))

# remove whitespace again
#get rid of unnecessary white spaces
tweets$text <- stringr::str_squish(tweets$text)


# include dummy term when tweet longer than median
tweets$long_tweet <- ifelse(tweets$text_length > 80, 1, 0)

print(glue("The process took {Sys.time() - time1}"))
# save created at as date instead of datetime
# tweets$created_at <- as.character(as.Date(tweets$created_at))






#######################################
#### save cleaned file
######################################
# parquetfile
path_save = "C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/text_cleaned/En_NoFilter/En_NoFilter_2020-04-01_cleaned.csv"
readr::write_csv(tweets, path_save)


