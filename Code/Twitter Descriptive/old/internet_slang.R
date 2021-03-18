slang_words_df <- lexicon::hash_internet_slang


# add words to df

# create new small df with new words
new_words <- data.frame()
names(new_words) <- names(slang_words_df)


slang_words_df <- rbind(slang_words_df, new_words)