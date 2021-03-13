#install.packages("RSQLite")
path = "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2018-12-07_cleaned.feather"
tweets <- feather::read_feather(path)

library(DBI)
library(dplyr)
library(RSQLite)
options(scipen=999) # remove scientifc not


setwd("C:/Users/lukas/Documents/SQLiteStudio/databases")
con <- DBI::dbConnect(RSQLite::SQLite(), "test.db")


DBI::dbListTables(con)

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
df_need <- DBI::dbGetQuery(con, 'SELECT * FROM pairwise_count WHERE "date" > :x and "weight" > :y', 
                      params = list(x = "2018-11-29",
                                    y = 50))
print(Sys.time() -  time1)


#disconnect
DBI::dbDisconnect(con)





old_wd <- getwd()
setwd("C:/Users/lukas/OneDrive - UT Cloud/Data")
con <- DBI::dbConnect(RSQLite::SQLite(), "SQLiteStudio/databases/test.db")
time1 <- Sys.time()
df_need <- DBI::dbGetQuery(con, "SELECT * FROM sum_stats_de_all WHERE created_at > '2018-11-30' and created_at < '2021-02-11'")
print(Sys.time() -  time1)

df_need %>%
  ggplot() +
  geom_histogram(aes(retweets_count))
Sys.time() - time1
setwd(old_wd)


####################### upload data
## test uploading to sql
old_wd <- getwd()
setwd("C:/Users/lukas/Documents/SQLiteStudio/databases")
con <- DBI::dbConnect(RSQLite::SQLite(), "test.db")

RSQLite::dbWriteTable(
  con,
  "test_term_freq",
  df_all_,
  overwrite = T)

DBI::dbDisconnect(con)
setwd(old_wd)






con <- DBI::dbConnect(RSQLite::SQLite(), "C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases/test.db")
time1 <- Sys.time()
df_need <- DBI::dbGetQuery(con, "select avg(retweets_count), date from cleaned_en where date >= '2018-11-30' and date <= '2021-01-10'
group by date")
print(Sys.time() -  time1)

df_need %>%
  ggplot() +
  geom_histogram(aes(retweets_count))
Sys.time() - time1
setwd(old_wd)





time1 <- Sys.time()
con <- DBI::dbConnect(RSQLite::SQLite(), "C:/Users/lukas/Documents/SQLiteStudio/databases/test-DESKTOP-RLA70GR.db")

df_need <- DBI::dbGetQuery(con, "select * from cleaned_en where username = 'realDonaldTrump'")

Sys.time() - time1





con <- DBI::dbConnect(RSQLite::SQLite(), "C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases/clean_database.db",
                      encoding = 'UTF-8')

df_need <- DBI::dbGetQuery(con, "select distinct(company) from sum_stats_companies")



a <- "Deutsche BÃ¶rse"
b <- "MÃ¼nchener RÃ¼ck"

c <- df_need$company[20]

iconv(a, "UTF-8", "WINDOWS-1252")
iconv(c, "UTF-8", "WINDOWS-1252")






iconv(df_need$company[20], "UTF-8", "WINDOWS-1252")

lapply(df_need$company, iconv,from = "UTF-8", to = "WINDOWS-1252")
