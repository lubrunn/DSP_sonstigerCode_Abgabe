source("Text_Cleaning.R")

# Sum rows and sort by frequency
term_frequency <- colSums(dtm_m)
term_frequency <- sort(term_frequency,
                       decreasing = TRUE)
# Create a barplot
barplot(term_frequency[1:10],
        col = "tan",
        las = 2)
