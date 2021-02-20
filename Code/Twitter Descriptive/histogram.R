library(ggplot2)




tweets_n <- tweets %>%
  filter(retweets_count < quantile(retweets_count, 0.99))

  
as.data.frame(table(cut(tweets_n$retweets_count, breaks=seq(0,max(tweets_n$retweets_count), by=2)))) %>%
  ggplot(aes(Var1, Freq)) +
  geom_col()
