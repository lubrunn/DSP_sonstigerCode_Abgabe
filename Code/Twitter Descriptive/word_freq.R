source("text_to_dtm.R")

# Sum rows and sort by frequency
term_frequency <- colSums(dtm_m_filt)
term_frequency <- sort(term_frequency,
                       decreasing = TRUE)
# Create a barplot
barplot(term_frequency[1:10],
        las = 2,
        col = "white",
        main = "Word Frequencies")

word_count <- data.frame("n" = term_frequency) %>% rownames_to_column("word")
word_count %>%
  top_n(10) %>% 
  arrange(desc(n)) %>%
ggplot(aes(x = word, y = n)) +
  geom_col() +
  coord_flip()


