library(tidyverse)

library(jsonlite)
setwd(r"(C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\NoFilter)")

library(tm)

library(tidytext)


#install.packages('rJava')
library('rJava')

library(qdap)

library(textclean)

#### read in data
tweets_raw <- stream_in(file("En_NoFilter_2020-03-29.json"))

#a <- head(tweets_raw, 1000)

# select only relevant columns and change column names so one can keep meta data when turning data into to corpus
tweets <- tweets_raw %>% select("doc_id" = id, "text" =  tweet, date,
                        replies_count, retweets_count, 
                        likes_count, retweet)


### convert all tweets to lower case
tweets$text <- tolower(tweets$text)

#a <- head(tweets, 1000)
#remove urls
tweets$text <- qdapRegex::rm_twitter_url(tweets$text)


####### Texclean functions
tweets$text <- replace_abbreviation(tweets$text) #Mr. = Mister
tweets$text <- replace_contraction(tweets$text) # it's = it is
tweets$text <- replace_internet_slang(tweets$text) #lol = laughing out loud
tweets$text <- replace_emoticon(tweets$text)
tweets$text <- replace_emoji(tweets$text) #replaces emojis with text representations

tweets$text <- replace_emoji_identifier(tweets$text) #replaces with a unique identifier that corresponds to lexicon::hash_sentiment_emoji
tweets$text <- replace_kern(tweets$text) # A L L becomes ALL
tweets$text <- replace_non_ascii(tweets$text) #removes chracter strings with non-ASCII chracters
tweets$text <- replace_tag(tweets$text) #removes twitter handles
tweets$text <- replace_word_elongation(tweets$text) #noooooooooooo becomes no
tweets$text <- replace_rating(tweets$text) #0/10 becomes terrible, 5 stars becomes best
tweets$text <- replace_url(tweets$text) #removes urls from text
tweets$text <- replace_white(tweets$text) #removes escaped chars -> I go \r to the \t  next line becomes I go to the next line
tweets$text <- replace_grade(tweets$text) # C+ becomes slighlty above average
tweets$text <- replace_html(tweets$text) #removes html markup: &euro becomes euro
tweets$text <- replace_email(tweets$text) #remove email adresses
tweets$text <- add_comma_space(tweets$text) #adds space after comma so later one,two,three does not become onetwothree

#remove twitter handles
tweets$text <- gsub("@\\w+", "", tweets$text)

#remove special , note: this also removes emojis
#tweets$tweet <- gsub("[^A-Za-z]", " ", tweets$tweet)

# Get rid of hashtags
tweets$text <- str_replace_all(tweets$text,"#[a-z,A-Z]*","")
# Get rid of references to other screennames
#tweets$tweet <- str_replace_all(tweets$tweet,"@[a-z,A-Z]*","") 
#get rid of unnecessary spaces
#tweets$text <- str_replace_all(tweets$text," "," ")




#set the schema:docs
docs <- tm::DataframeSource(tweets)




#clean_corpus function from datacamp
clean_corpus <- function(corpus){
  #corpus <- tm_map(corpus,  content_transformer(replace_abbreviation))
  corpus <- tm_map(corpus, removePunctuation)
  
  corpus <- tm_map(corpus, removeNumbers)
  corpus <- tm_map(corpus,
                   content_transformer(tolower))
  corpus <- tm_map(corpus, removeWords,
                   c(stopwords("en"), "amp"))
  corpus <- tm_map(corpus, stripWhitespace)
  corpus <- tm_map(corpus,  content_transformer(replace_abbreviation))
  return(corpus)
}

text_corpus <- clean_corpus(VCorpus(docs))


content(text_corpus[[10]])
#for standard meta data (including id)
meta(text_corpus[[1]])

#for all added meta data
meta(text_corpus[1])

dtm <- DocumentTermMatrix(text_corpus)
#remove sparse words
dtm <- removeSparseTerms(dtm, 0.99)
dtm_m <- as.matrix(dtm)

#check matrix
dtm_m[1:5, 1:10]

rm(docs, dtm, text_corpus, tweets_raw, clean_corpus)