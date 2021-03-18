
df <- data.table::fread("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/sentiment/Shiny_files_companies/appended_files/3M.csv")


df_orig <- df
df_all <- df_orig

retweets_filter = 0
likes_filter = 0
length_filter = 0

dt <- df_all[retweets_count >= retweets_filter &
               likes_count >= likes_filter &
               tweet_length >= length_filter,
             .(.N,
               
               
               mean_rt = mean(retweets_count),
               mean_likes = mean(likes_count),
               mean_length = mean(tweet_length),
               
               mean_sentiment = mean(sentiment),
               # mean_sentiment_rt = mean(sentiment_rt),
               # mean_sentiment_likes = mean(sentiment_likes),
               # mean_sentiment_tweet_length = mean(sentiment_length),
               
               
               median_rt = as.numeric(median(retweets_count)),
               median_likes = as.numeric(median(likes_count)),
               median_length = as.numeric(median(tweet_length)),
               median_sentiment = as.numeric(median(sentiment)),
               
               # median_sentiment_rt = as.numeric(median(sentiment_rt)),
               # median_sentiment_likes = as.numeric(median(sentiment_likes)),
               # median_sentiment_tweet_length = as.numeric(median(sentiment_length)),
               
               std_rt = sd(retweets_count),
               std_likes = sd(likes_count),
               std_length = sd(tweet_length),
               std_sentiment = sd(sentiment),
               # std_sentiment_rt = sd(sentiment_rt),
               # std_sentiment_likes = sd(sentiment_likes),
               # std_sentiment_tweet_length = sd(sentiment_length),
               
               
               ##### min
               min_rt = min(retweets_count),
               min_likes = min(likes_count),
               min_length = min(tweet_length),
               min_sentiment = min(sentiment),
               # min_sentiment_rt = min(sentiment_rt),
               # min_sentiment_likes = min(sentiment_likes),
               # min_sentiment_tweet_length = min(sentiment_length),
               
               ##### max
               max_rt = max(retweets_count),
               max_likes = max(likes_count),
               max_length = max(tweet_length),
               
               max_sentiment = max(sentiment),
               # max_sentiment_rt = max(sentiment_rt),
               # max_sentiment_likes = max(sentiment_likes),
               # max_sentiment_tweet_length = max(sentiment_length),
               
               
               ## 25th quantile
               q25_rt = quantile(retweets_count, 0.25),
               q25_likes = quantile(likes_count, 0.25),
               q25_length = quantile(tweet_length, 0.25),
               
               q25_sentiment = quantile(sentiment, 0.25),
               # q25_sentiment_rt = quantile(sentiment_rt, 0.25),
               # q25_sentiment_likes = quantile(sentiment_likes, 0.25),
               # q25_sentiment_tweet_length = quantile(sentiment_length, 0.25),
               
               ### 75 quantile
               q75_rt = quantile(retweets_count, 0.75),
               q75_likes = quantile(likes_count, 0.75),
               q75_length = quantile(tweet_length, 0.75),
               
               q75_sentiment = quantile(sentiment, 0.75),
               # q75_sentiment_rt = quantile(sentiment_rt, 0.75),
               # q75_sentiment_likes = quantile(sentiment_likes, 0.75),
               # q75_sentiment_tweet_length = quantile(sentiment_length, 0.75)
               
               
               ######## weighted metrics
               mean_sentiment_rt = weighted.mean(sentiment,retweets_count),
               mean_sentiment_likes = weighted.mean(sentiment,likes_count),
               mean_sentiment_length = weighted.mean(sentiment,tweet_length),
               
               median_sentiment_rt = matrixStats::weightedMedian(sentiment, retweets_count),
               median_sentiment_likes = matrixStats::weightedMedian(sentiment, likes_count),
               median_sentiment_length = matrixStats::weightedMedian(sentiment, tweet_length),
               
               std_sentiment_rt = sqrt(Hmisc::wtd.var(sentiment, retweets_count)),
               std_sentiment_likes = sqrt(Hmisc::wtd.var(sentiment, likes_count)),
               std_sentiment_length = sqrt(Hmisc::wtd.var(sentiment, tweet_length))
             ), by = c("created_at", "language")]


df_all$retweets_count <- as.numeric(df_all$retweets_count)

dt2 <- df_all[,lapply(.SD,weighted.mean,w=as.numeric(retweets_count)),by= c("created_at", "language")]

dt2 <- df_all[,lapply(.SD,weighted.mean,w=tweet_length), 
          by = c("created_at", "language"), .SDcols = c("sentiment")]



dt = head(df, 2)

df_nona <- dt

df_nona[is.na(df_nona)] <- 0

df <- dt2 %>% filter(created_at == "2018-12-07" & language == "de")


mean(df$retweets_count)

sum(df$retweets_count)

mean(df$sentiment)


# funcktioniert für length weighted mean
dt_senti_len = df_all[,lapply(.SD, weighted.mean,w=rt), 
          by = c("created_at", "language"), .SDcols = c("sentiment")]


# median weighted

dt3 <- df_all[,lapply(.SD,matrixStats::weightedMedian,w=tweet_length), 
          by = c("created_at", "language"), .SDcols = c("sentiment")]



library(Hmisc)
# sd weighted
df_all[,lapply(.SD,wtd.var,w=tweet_length), 
          by = c("created_at", "language"), .SDcols = c("sentiment")]


# merge back together
merge(dt,dt2,by= c("created_at", "language"))



df_all[,.(mean_sentiment_rt = weighted.mean(sentiment,retweets_count),
             mean_sentiment_likes = weighted.mean(sentiment,likes_count),
             mean_sentiment_length = weighted.mean(sentiment,tweet_length),
          
            median_sentiment_rt = matrixStats::weightedMedian(sentiment, retweets_count),
          median_sentiment_likes = matrixStats::weightedMedian(sentiment, likes_count),
          median_sentiment_length = matrixStats::weightedMedian(sentiment, tweet_length),
          
          sd_sentiment_rt = sqrt(wtd.var(sentiment, retweets_count)),
          sd_sentiment_likes = sqrt(wtd.var(sentiment, likes_count)),
          sd_sentiment_length = sqrt(wtd.var(sentiment, tweet_length))
            
               
               
               
               ),by=c("created_at", "language")]






df_all[,lapply(.SD, weighted.mean,w=retweets_count), 
       by = c("created_at", "language"), .SDcols = c("sentiment")]










dt <- df_all[retweets_count >= retweets_filter &
           likes_count >= likes_filter &
           tweet_length >= length_filter &
             retweets_count < quantile(df_all$retweets_count, 0.99),
         .(.N), by = c("created_at", "retweets_count")]

quantile(df_all$retweets_count, 0.99)


dt[, C := cut_interval(retweets_count, 1500), by = created_at]
dt

