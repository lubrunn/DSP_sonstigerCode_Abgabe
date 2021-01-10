source("Text_Cleaning.R")
library(wordcloud)

#Sum columns and sort by frequency
term_frequency <- colSums(dtm_m)
word_freqs <- data.frame(term = names(term_frequency),
                         num = term_frequency)
# Make word cloud
wordcloud(word_freqs$term, word_freqs$num,
          max.words = 100, colors = "red")
