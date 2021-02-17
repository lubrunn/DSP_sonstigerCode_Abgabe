source("text_to_dtm.R")
library(wordcloud)

#Sum columns and sort by frequency
term_frequency <- colSums(dtm_m)
word_freqs <- data.frame(term = names(term_frequency),
                         num = term_frequency)
# Make word cloud
wordcloud(word_freqs$term, word_freqs$num,
          max.words = 100, colors = "red")


#### different wordcloud
# devtools::install_github("lchiffon/wordcloud2")


library(wordcloud2)
term_frequency_df <- data.frame("freq" = term_frequency) %>% rownames_to_column(var = "word")

wordcloud2(term_frequency_df, size = 1,shape = 'star',
           color = "random-light", backgroundColor = "grey")
a <- demoFreq
