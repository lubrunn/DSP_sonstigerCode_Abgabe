setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases")
time1 <- Sys.time()
con <- DBI::dbConnect(RSQLite::SQLite(), "test.db")

df_need <- DBI::dbGetQuery(con, "select retweets_count, count(*) as n from test_table2 where likes_count >= :x and retweets_count >= :x2 
and text like '%trump%'
group by retweets_count", 
                           params = list(x = 5,
                                         x2 = 10))

#disconnect
DBI::dbDisconnect(con)

# plot
df_need %>%
ggplot(aes(n)) +
  geom_histogram(bins = 500)

print(Sys.time() - time1)