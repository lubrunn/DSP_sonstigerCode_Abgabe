path <- "C:/Users/lukas/OneDrive - UT Cloud/DSP_test_data/cleaned/En_NoFilter_2018-12-07_cleaned35.parquet"
time1 <- Sys.time()
tweets_read_test <- arrow::read_parquet(path)
print(Sys.time()- time1)

gc()

# test filtering time
tweets_read_test <- data.table::data.table(tweets_read_test)


tweets_read_test$language <- NULL

object.size(tweets_read_test)
