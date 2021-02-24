setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases")
time1 <- Sys.time()
con <- DBI::dbConnect(RSQLite::SQLite(), "test.db")

df_need <- DBI::dbGetQuery(con, "select retweets_count, count(*) as n from test_table2 where likes_count >= :x and retweets_count >= :x2 
and text like '%trump%'
group by retweets_count", 
                           params = list(x = 0,
                                         x2 = 0))

#disconnect
DBI::dbDisconnect(con)

# plot
df_need %>%
ggplot(aes(n)) +
  geom_histogram(bins = 100)

print(Sys.time() - time1)





time1 <- Sys.time()
con <- DBI::dbConnect(RSQLite::SQLite(), "test.db")

df_need <- DBI::dbGetQuery(con, "select created_at, avg(sentiment) mean_sentiment from sentiment_en
sentiment_en  where 
username like 'realdonaldtrump'
group by created_at")
#, 
 #                          params = list(x = 0,
  #                                       x2 = 0))

#disconnect
DBI::dbDisconnect(con)
print(Sys.time() - time1)
# plot
df_need %>%
  ggplot(aes(1:721, mean_sentiment)) +
  geom_line()
