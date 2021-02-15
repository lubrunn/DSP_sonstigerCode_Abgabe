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
                         c(stopwords("SMART"), "amp"))
        corpus <- tm_map(corpus, stripWhitespace)
        corpus <- tm_map(corpus,  content_transformer(replace_abbreviation))
        return(corpus)
}

text_corpus <- clean_corpus(VCorpus(docs))



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

rm(docs, dtm, text_corpus, tweets_raw, clean_corpus)