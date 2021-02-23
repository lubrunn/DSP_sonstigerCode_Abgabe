if(!require("corpus")) install.packages("corpus")
if(!require("hunspell")) install.packages("hunspell")
# install.packages("stopwords")

library(dplyr)
library(qdap)
library(readr)




# read in data
setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
# tweets_raw <- stream_in(file(r"(C:\Users\lukas\OneDrive - UT Cloud\DSP_test_data\raw_test\En_NoFilter\En_NoFilter_2020-04-01.json)"))

path <- "raw_csv/En_NoFilter"


time1 <- Sys.time()
files <- list.files(path)
file <- files[1]
tweets_raw <- read_csv(file.path(path,file),
                       col_types = cols(.default = "c", lat = "d", long = "d",
                                        retweets_count = "i", replies_count = "i",
                                        likes_count = "i", tweet_length = "i"))


#Mr. = Mister
time2 <- Sys.time()
tweets$text <- replace_abbreviation(tweets$text)  
print(Sys.time() - time2)