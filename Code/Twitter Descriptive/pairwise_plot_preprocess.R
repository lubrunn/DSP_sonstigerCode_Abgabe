# preprocess pairwise plot

time1 <- Sys.time()
# put every single word into new column, so one row per word in tweet
tweets_section_words <- df %>%
  tidytext::unnest_tokens(word, text)

# show all pairs out of all pairs per tweet
# feel so forgoten that --> feel so, feel forgotten, feel that, so feel, so forgotten, so that etc.
word_pairs <- tweets_section_words %>%
  widyr::pairwise_count(word, doc_id, sort = T) %>%
  rename("weight" = n)

# date of tweets
date <- as.Date(df$created_at[1], "%Y-%m-%d")

# already filter out pairs that only appear 20 times or less in order to reduce size of df
network_df <- word_pairs  %>%
  filter(weight > 20) %>%
  mutate(date = as.character(date)) %>%
  select(date, item1, item2, weight)


print(Sys.time() - time1)

# maximum strings length
max(nchar(network_df$item2))



# load data in sql
time <- Sys.time()
setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases")
con <- DBI::dbConnect(RSQLite::SQLite(), "test.db")


time1 <- Sys.time()
DBI::dbSendQuery(con, 'INSERT INTO pairwise_count (date, item1, item2, weight) VALUES (:date, :item1, :item2, :weight);', network_df)
print(Sys.time() - time)
print(Sys.time() - time1)


DBI::dbDisconnect(con)





time1 <- Sys.time()
tomatch <- c("trump", "covid", "russia")
###################### for specific terms
tweets_section_words <- df %>%
  unnest_tokens(word, text) %>%
  left_join(subset(df, select = c(doc_id, text))) %>%
  select(doc_id, word, text)


print(Sys.time() - time1)



word_cors <- tweets_section_words %>%
  filter(grepl(paste(tomatch, collapse="|"), text)) %>%
  group_by(word) %>%
  filter(n() >= 5) %>%
  widyr::pairwise_cor(word, doc_id, sort = TRUE)





network <-  word_cors %>%
  #filter(item1 %in% c("covid", "trump", "china")) %>%
  filter(correlation > 0.2)

network <- network %>%
  graph_from_data_frame(directed = FALSE)

