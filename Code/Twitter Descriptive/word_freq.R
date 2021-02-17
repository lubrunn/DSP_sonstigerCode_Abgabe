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


