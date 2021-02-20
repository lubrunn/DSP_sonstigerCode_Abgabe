#install.packages("RSQLite")
path = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2018-12-07_cleaned.feather"
tweets <- feather::read_feather(path)

library(DBI)
library(dplyr)
library(RSQLite)
options(scipen=999) # remove scientifc not


setwd("C:/Users/lukas/Documents/SQLiteStudio/databases")
con <- DBI::dbConnect(RSQLite::SQLite(), "test.db")


dbListTables(con)

time1 <- Sys.time()
db_test <- dbReadTable(con, "test_table2")
print(Sys.time() - time1)

# send lines to db
# single row
dbSendQuery(con, 'INSERT INTO test_table (doc_id, text, created_at, language, retweets_count, likes_count) VALUES (?, ?, ?, ?, ?, ?);', list(2, "tweet text 2", '2013-01-01 22:00:00', "en", 5, 10))

# entire df
# remove duplicates from tweet df
tweets_unique <- unique(tweets)
dbSendQuery(con, 'INSERT INTO test_table (doc_id, text, created_at, language, retweets_count, likes_count) VALUES (:doc_id, :text, :created_at, :language, :retweets_count, :likes_count);', tweets)

# insert 20 Mio rows into database
tweets_intodb <- purrr::map_dfr(seq_len(1000), ~tweets)

# save df as csv
#write.csv(tweets_intodb, "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/tweets_intodb.csv",
#          row.names = F)
# send to db
time1 <- Sys.time()
dbSendQuery(con, 'INSERT INTO test_table (doc_id, text, created_at, language, retweets_count, likes_count) VALUES (:doc_id, :text, :created_at, :language, :retweets_count, :likes_count);', tweets_intodb)
print(Sys.time() - time1)



### querry from db
time1 <- Sys.time()
df_need <- dbGetQuery(con, 'SELECT * FROM test_table2 WHERE "retweets_count" > :x', 
                      params = list(x = 1))
print(Sys.time() -  time1)


#disconnect
dbDisconnect(con)
