library(tidyverse)
setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")

folders <- list.files("cleaned")


likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)



#### for testing
folder <- folders[2]
# read data
files <- list.files(file.path("cleaned", folder))
files <- files[1:10]
file <- files[1]
retweets <- 0
likes <- 0
longs <- 0



df_all <- NULL
for (file in files){
df <- readr::read_csv(file.path("cleaned", folder ,file),
               col_types = cols_only(doc_id = "c",text = "c",
                                     created_at = "c",
                                     retweets_count = "i",
                                     likes_count = "i", tweet_length = "i",
                                     language = "c")) 
if(is.null(df_all)){
  df_all <- df
} else {
df_all <- rbind(df_all, df)
}
}



df_all$date <- as.Date(df_all$created_at, "%Y-%m-%d")

# histo
df_all %>% filter(
  likes_count >= likes &
    retweets_count >= retweets &
    tweet_length >= longs,
  date >= "2018-11-30" & date <= "2019-12-07") %>%
  ggplot() +
  geom_histogram(aes(retweets_count))



# for retweets hist
df_bins_rt <- df_all %>% filter(
  likes_count >= likes &
  retweets_count >= retweets &
  tweet_length >= longs) %>%
  group_by(date,language, retweets_count) %>%
  summarise(n = n())  %>%
  pivot_wider(names_from = retweets_count, values_from = n) %>%
  mutate(retweets_count = retweets,
         likes_count = likes,
         tweet_length = longs)%>%
  ungroup()

# for likes histo
df_bins_likes <- df_all %>% filter(
  likes_count >= likes &
  retweets_count >= retweets &
  #long_tweet == long
  tweet_length >= longs) %>%
  group_by(date,language, likes_count) %>%
  summarise(n = n()) %>%
  pivot_wider(names_from = likes_count,values_from = n) %>%
  mutate(retweets_count = retweets,
         likes_count = likes,
         tweet_length = longs)%>%
  ungroup()

# for long histo
df_bins_long <- df_all %>% filter(
  likes_count >= likes &
  retweets_count >= retweets &
  #long_tweet == long
  tweet_length >= longs) %>%
  group_by(date,language, tweet_length) %>%
  summarise(n = n())  %>%
  pivot_wider(names_from = tweet_length,values_from =  n) %>%
  mutate(retweets_count = retweets,
         likes_count = likes,
         tweet_length = longs)%>%
  ungroup()


# get data for time series of means and counts for retweets, likes, length_tweet and number of tweets
df_sum_stats <- df_all %>% filter(
  likes_count >= likes &
  retweets_count >= retweets &
  #long_tweet == long
  tweet_length >= longs) %>%
  group_by(date,language) %>%
  summarise(mean_rt = mean(retweets_count),
            mean_likes = mean(likes_count),
            mean_length = mean(tweet_length),
            count_tweetts = n())  %>%
  mutate(retweets_count = retweets,
         likes_count = likes,
         tweet_length = longs) %>%
  ungroup()




# plot histo in app
df_bins_long %>%
  filter(date >= "2018-11-30" & date <= "2019-12-07" &
         language == "de" &
           likes_count >= likes &
           retweets_count >= retweets &
           #long_tweet == long
           tweet_length >= longs) %>% 
  select(-c(date, language, retweets_count, likes_count, tweet_length)) %>%



  colSums(na.rm = T) %>% data.frame() %>% rownames_to_column() %>%
  rename(bins = rowname, n = ".") %>%
  mutate(bin = cut_interval(bins, n = 200))
ggplot(aes(bins, n)) +
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