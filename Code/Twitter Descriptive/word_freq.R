source("text_to_dtm.R")

# Sum rows and sort by frequency

term_frequency <- colSums(dtm_m)


# only for already filtered tweets
# term_frequency <- colSums(dtm_m_filt)


word_count <- data.frame("n" = term_frequency) %>% rownames_to_column("word")
word_count %>%
  top_n(20) %>% 
  arrange(desc(n)) %>%
ggplot(aes(x = word, y = n)) +
  geom_col() +
  coord_flip()


