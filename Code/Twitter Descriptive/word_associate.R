source("Text_Cleaning.R")

#take smaller sample of twitter data
tweets_small <- sample_n(tweets, 10000) #always get error when I select less than 10000
text <- tweets_small$text
word_associate(text,
               match.string = c("covid"),
               stopwords = c(Top200Words, "amp"),
               network.plot = TRUE,
               wordcloud = T,
               cloud.colors = c("gray85", "darkred"))
title(main = "Covid-19 Tweet Associations")



library(networkD3)

# Create fake data
src <- c("A", "A", "A", "A", "B", "B", "C", "C", "D")
target <- c("B", "C", "D", "J", "E", "F", "G", "H", "I")
networkData <- data.frame(src, target)

# Plot
simpleNetwork(networkData)


dtm_df <- data.frame(dtm_m)
simpleNetwork(dtm_df)
