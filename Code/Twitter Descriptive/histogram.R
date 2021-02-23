library(tidyverse)
setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")

folders <- list.files("cleaned")


likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)



#### for testing
folder <- folders[3]
file <- files[1]
retweets <- 0
likes <- 0
longs <- 0

# read data
files <- list.files(source)

df <- rbind(df, df)

df <- readr::read_csv(file.path(source,file),
               col_types = cols_only(doc_id = "c",text = "c",
                                     created_at = "c",
                                     retweets_count = "i",
                                     likes_count = "i", tweet_length = "i")) 

df$date <- as.Date(df$created_at)

# for retweets hist
df_bins_rt <- df %>% filter(
  likes_count >= likes &
  retweets_count >= retweets &
  tweet_length >= longs) %>%
  group_by(date, retweets_count) %>%
  summarise(n = n())  %>%
  pivot_wider(names_from = retweets_count, values_from = n)

# for likes histo
df_bins_likes <- df %>% filter(
  likes_count >= likes &
  retweets_count >= retweets &
  #long_tweet == long
  tweet_length >= longs) %>%
  group_by(date, likes_count) %>%
  summarise(n = n()) %>%
  pivot_wider(names_from = likes_count, n)

# for long histo
df_bins_long <- df %>% filter(
  likes_count >= likes &
  retweets_count >= retweets &
  #long_tweet == long
  tweet_length >= longs) %>%
  group_by(date, tweet_length) %>%
  summarise(n = n())  %>%
  pivot_wider(tweet_length, n)


# get data for time series of means and counts for retweets, likes, length_tweet and number of tweets
df_sum_stats <- df %>% filter(
  likes_count >= likes &
  retweets_count >= retweets &
  #long_tweet == long
  tweet_length >= longs) %>%
  group_by(date) %>%
  summarise(mean_rt = mean(retweets_count),
            mean_likes = mean(likes_count),
            mean_length = mean(tweet_length),
            count_tweetts = n())  %>%
  mutate(retweets_count = retweets,
         likes_count = likes,
         tweet_length = longs)




# plot
df %>%
ggplot(aes(Var1, Freq)) +
  geom_col()

for (folder in folders){
  if (grepl("Companies", folder)) {
    source_main <- file.path("cleaned", folder)
    company_folders <- list.files(source_main)
    
    #create companies folder if doesnt exist
    dir.create(file.path("histo", folder), showWarnings = FALSE)
    
    for (company_folder in company_folders){
      source <- file.path("cleaned", folder, company_folder)
      dest <- file.path("histo", folder, company_folder)
      # if folder doesnt exist, create it
      dir.create(dest, showWarnings = FALSE)
      # run function
      #term_freq_computer(company_folder)
    }
  } else if (grepl("NoFilter", folder)) {
    source <- file.path("cleaned", folder)
    dest <- file.path("histo", folder)
    # if folder doesnt exist, create it
    dir.create(dest, showWarnings = FALSE)
    
    # call function for each nofilter folder
    #term_freq_computer(folder)
  }
  
}