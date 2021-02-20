library(corpus)
library(tidyverse)
library(tm)

######## read in cleaned data



# path = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2018-12-07_cleaned.feather"


# tweets_f1 <- feather::read_feather(path)
# 
# 
# path1 = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2018-12-07_cleaned2.feather"
# tweets_f2 <- arrow::read_feather(path1)

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
