if(!require("corpus")) install.packages("corpus")
if(!require("hunspell")) install.packages("hunspell")
# install.packages("stopwords")

library(tidyverse)

library(jsonlite)




library(tidytext)


#install.packages('rJava')
library('rJava')

library(qdap)

library(textclean)


library(hunspell)

#### read in data
# setwd("C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/raw_test")
# filename <- "De_NoFilter_min_retweets_2/De_NoFilter_min_retweets_2_2018-11-30.json"
# test_data_nof_1 <- jsonlite::stream_in(file(filename))
# filename <- "De_NoFilter_min_retweets_2/De_NoFilter_min_retweets_2_2018-12-01.json"
# test_data_nof_2 <- jsonlite::stream_in(file(filename))
# 
# test_data_nofilter <- rbind(test_data_nof_1, test_data_nof_2)
# test_data_nofilter$search_term <- ""
# 
# filename <- "Companies_de/3M_de/3M_2018-11-30_de.json"
# test_data1 <- jsonlite::stream_in(file(filename))
# filename <- "Companies_de/3M_de/3M_2018-12-01_de.json"
# test_data2 <- jsonlite::stream_in(file(filename))
# filename <- "Companies_de/adidas_de/adidas_2018-11-30_de.json"
# test_data3 <- jsonlite::stream_in(file(filename))
# filename <- "Companies_de/adidas_de/adidas_2018-12-01_de.json"
# test_data4 <- jsonlite::stream_in(file(filename))
# 
# # add search term column
# test_data1$search_term <- "3M"
# test_data2$search_term <- "3m"
# test_data3$search_term <- "adidas"
# test_data4$search_term <- "adidas"
# 
# test_data_comp <- rbind(test_data1, test_data2, test_data3, test_data4)


# # add to df to one
# tweets_raw <- rbind(test_data_comp, test_data_nofilter)
# rm(test_data_nof_1, test_data_nof_2,
#    test_data1, test_data2, test_data3, test_data4,
#    filename, test_data_nofilter, test_data_comp)

# only one file
 
tweets_raw <- stream_in(file(r"(C:\Users\lukas\OneDrive - UT Cloud\DSP_test_data\raw_test\En_NoFilter\En_NoFilter_2020-04-01.json)"))

#a <- head(tweets_raw, 1000)

# select only relevant columns and change column names so one can keep meta data when turning data into to corpus
tweets <- tweets_raw %>% select("doc_id" = id, "text" =  tweet, created_at, 
                                user_id, username, hashtags,
                                place, language, replies_count, 
                                retweets_count, likes_count)

### remove tweets that are not in correct language
tweets <- tweets %>% filter(language == "en")

### remove duplicates
tweet_u <- tweets[duplicated(tweets$doc_id), ]

# testing with single tweet
#tweets <- tweets[1,]
# tweets$text <- "Mr. Jones &amp; Jones Jones don't don't can't shouldn't haven't @twitter_user123 it's so soooooooooooo rate T H I S movie 0/10 VeRy BAD ???? :D lol and stopwords i could have really done it myself, one,two,three"

tweets$text <- text_tokens(tweets$text)

# function that removes consecutive duplicates
dup_remover <- function(string){
  
  string <- paste(rle(unlist(string))$values, collapse = " ")
  return(string)
}

tweets$text <- sapply(tweets$text, dup_remover)




###
tweets$text <- replace_kern(tweets$text) # A L L becomes ALL


### convert all tweets to lower case
tweets$text <- tolower(tweets$text)


#a <- head(tweets, 1000)
#remove urls
tweets$text <- qdapRegex::rm_twitter_url(tweets$text)



####### Texclean functions
# replace special apostrophe with normal apostrophe (otherwise replace_contractions
# does not work for these cases)
tweets$text <- gsub("’", "'", tweets$text)
#Mr. = Mister
tweets$text <- replace_abbreviation(tweets$text)  
# it's = it is
tweets$text <- replace_contraction(tweets$text) 

# replace haven't because replace_contractions does not
tweets$text <- gsub("haven't", "have not", tweets$text)
#noooooooooooo becomes no
tweets$text <- replace_word_elongation(tweets$text) 
#remove email adresses
tweets$text <- replace_email(tweets$text) 
#replaces emoticons
tweets$text <- replace_emoticon(tweets$text) 
#removes html markup: &euro becomes euro
tweets$text <- replace_html(tweets$text) 
# C+ becomes slighlty above average
tweets$text <- replace_grade(tweets$text) 
#lol = laughing out loud
tweets$text <- replace_internet_slang(tweets$text) 
#replaces emojis with text representations
tweets$text <- replace_emoji(tweets$text) 
#replaces with a unique identifier that corresponds to lexicon::hash_sentiment_emoji
tweets$text <- replace_emoji_identifier(tweets$text) 
#removes chracter strings with non-ASCII chracters
tweets$text <- replace_non_ascii(tweets$text) 
#removes twitter handles
tweets$text <- replace_tag(tweets$text) 
#0/10 becomes terrible, 5 stars becomes best
tweets$text <- replace_rating(tweets$text) 
#removes urls from text
tweets$text <- replace_url(tweets$text) 
#removes escaped chars -> I go \r to the \t  next line becomes I go to the next line
tweets$text <- replace_white(tweets$text) 
### convert all tweets to lower case
tweets$text <- tolower(tweets$text)


#adds space after comma so later one,two,three does not become onetwothree
tweets$text <- add_comma_space(tweets$text) 

# remove twitter handles
# tweets$text <- gsub("@\\w+", "", tweets$text)

# Get rid of hashtags
tweets$text <- str_replace_all(tweets$text,"#[a-z,A-Z]*","")

#remove special , note: this also removes emojis
tweets$text <- gsub("[^A-Za-z]", " ", tweets$text)


# Get rid of references to other screennames
#tweets$tweet <- str_replace_all(tweets$tweet,"@[a-z,A-Z]*","") 

#get rid of unnecessary white spaces
tweets$text <- stringr::str_squish(tweets$text)

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
tweets$text <- text_tokens(tweets$text, stemmer = stem_hunspell)




# collapse text column list to one string again
tweets <-tweets %>% rowwise() %>%
  mutate(text = paste(text, collapse=' ')) %>%
  ungroup()


## same for hashtags
# collapse text column list to one string again
tweets <-tweets %>% rowwise() %>%
  mutate(hashtags = paste(hashtags, collapse=' ')) %>%
  ungroup()


###### place column contains lists
# move coordinates into two lat/long columns
tweets <- unnest_wider(tweets, place) %>%
  select(-c("...1", "type")) %>%
  mutate_all(list(~na_if(.,"NULL"))) %>%
  unnest_wider(coordinates) %>%
  rename( "lat" = "...1", "long" = "...2" )



# remove stopwords, remove face because it appears very often thru conversion of emojis/emoticons to text 
# e.g. :D becomes lauging face, :) = smiling face --> so a lot of face words get created
tweets$text <- removeWords(tweets$text,c(tm::stopwords("SMART"),
                                         stopwords::stopwords("en", "snowball"),
                                         stopwords::stopwords("en", "nltk"),
                                         "face",
                                         "amp",
                                         "make"))

# remove whitespace again
#get rid of unnecessary white spaces
tweets$text <- stringr::str_squish(tweets$text)


# save created at as date instead of datetime
# tweets$created_at <- as.character(as.Date(tweets$created_at))

# check how much data can be saved by removing columns
tweets_orig <- tweets


# tweets <- tweets_orig %>% select(
#   doc_id, text, created_at, language,
#   retweets_count, likes_count
# )

#######################################
#### save cleaned file
######################################
# parquetfile
path2 = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2020-04-01_cleaned.parquet"
arrow::write_parquet(tweets, path2)


# 1st feather format
path = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2018-12-07_cleaned.feather"
feather::write_feather(tweets, path)

# different feather format
path1 = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2018-12-07_cleaned2.feather"
arrow::write_feather(tweets, path1)



# parquet file with two tweet dfs
tweets2 <- rbind(tweets, tweets)
path22 = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2018-12-07_cleaned32.parquet"
arrow::write_parquet(tweets2, path22)

# with 80k tweets
tweets3 <- rbind(tweets2, tweets2)
path23 = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2018-12-07_cleaned33.parquet"
arrow::write_parquet(tweets3, path23)

# with 160k tweets
tweets4 <- rbind(tweets3, tweets3)
path24 = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2018-12-07_cleaned34.parquet"
arrow::write_parquet(tweets4, path24)


#160 mio tweets
tweets6 <- purrr::map_dfr(seq_len(1000), ~tweets4)
path25 = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2018-12-07_cleaned35.parquet"
arrow::write_parquet(tweets6, path25)


# save as csv as reference
path3 = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2018-12-07_cleaned4.csv"
write.csv(tweets, path3)








