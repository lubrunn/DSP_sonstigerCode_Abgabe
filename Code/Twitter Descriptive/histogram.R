library(tidyverse)
setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")

folders <- list.files("cleaned")


likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)



#### for testing
folder <- folders[3]
# read data
files <- list.files(file.path("cleaned", folder))
files <- files[1:10]
file <- files[1]
retweets <- 0
likes <- 0
longs <- 0





#################################################################################
#################################################################################
#################################################################################
#################################################################################


'
 function that aggreagtes data on a daily basis based on several filter
 this will be used to create histograms for retweets, likes and tweet length
 this is done for preprocessing because live computation may take very long otherwise
 depending on chosen filter, e.g. for filter that take out a lot of data (e.g. retweets > 200)
 the live computation would be somewhat fast enough but for broad filter (retweets  >0)
 computation would take up to 1 minute per histogram
'
hist_data_creator <- function(df, retweets_filter, likes_filter, length_filter, grouping_variable, file){
# for retweets hist
df <- df_all %>% filter(
  # filter out accoring to loop
  likes_count >= likes_filter &
  retweets_count >= retweets_filter &
  tweet_length >= length_filter) %>%
  # count number of tweets per bin in likes, length, retweets
  # for company file
  { if (file == "Companies_all.csv") group_by(company, date,language, 
                                        .data[[grouping_variable]]) else group_by(date,language, 
                                                                                  .data[[grouping_variable]])  } %>%
 
  summarise(n = n())  %>%
  # spread dataframe
  pivot_wider(names_from = .data[[grouping_variable]], values_from = n) %>%
  # add values that were used to filter for later filtering
  mutate(retweets_count = retweets,
         likes_count = likes,
         tweet_length = longs,
         # count number of tweets that are part of one aggregated day
         tweet_number = sum(c_across(-c("retweets_count",
                                        "likes_count", 
                                        "tweet_length")), na.rm = T))%>%
  ungroup() %>%
  replace(is.na(.), 0) 
return(df)
}

#################################################################################
#################################################################################
'
function that aggregates by day and language and takes the means of likes,
retweets and tweet_length --> will be used for plotting time series of
the means according to several filters
'
sum_stats_creator <- function(df_all, retweets_filter, likes_filter, length_filter){
  df <- df_all %>% filter(
    likes_count >= likes_filter &
      retweets_count >= retweets_filter &
      #long_tweet == long
      tweet_length >= length_filter) %>%
    { if (file == "Companies_all.csv") group_by(company, date,language) else group_by(date,language)  } %>%
    summarise(mean_rt = mean(retweets_count),
              mean_likes = mean(likes_count),
              mean_length = mean(tweet_length),
              std_rt = std(retweets_count),
              std_links = std(likes_count),
              std_length = std(tweet_length),
              count_tweeets = n())  %>%
    mutate(retweets_count = retweets,
           likes_count = likes,
           tweet_length = longs) %>%
    ungroup()
  return(df)
  
}

# function that applies functions to appended df and saves them
data_wrangler_and_saver <- function(df_all, retweets, likes, longs, folder){

  
##############################################################################  
# call function that creates histograms for all three grouping variables
# for retweets
df_bins_rt <- hist_data_creator(df_all,retweets_filter =  retweets,
                                likes_filter = likes,
                                length_filter = longs,
                                grouping_variable = "retweets_count")
# for likes
df_bins_likes <- hist_data_creator(df_all, retweets, likes, longs, "likes_count")
# for tweet length
df_bins_long <- hist_data_creator(df_all, retweets, likes, longs, "tweet_length")


###############################################################################
# call function that computes means by day and language of all variables
df_sum_stats_n <- sum_stats_creator(df_all,retweets, likes, longs)
###############################################################################

# check which name to five file
if (longs == 81){
  long_name <- "long_only"
} else{
  long_name <- "all"
}


# filesnames
filename_rt <- glue("histo_rt_{folder}_rt_{retweets}_li_{likes}_lo_{long_name}.csv")
filename_likes <- glue("histo_likes_{folder}_rt_{retweets}_li_{likes}_lo_{long_name}.csv")
filename_long <- glue("histo_long_{folder}_rt_{retweets}_li_{likes}_lo_{long_name}.csv")
filename_sum <- glue("sum_stats_{folder}_rt_{retweets}_li_{likes}_lo_{long_name}.csv")


##### save files
print(glue("Saving files for {folder}, rt: {retweets}, likes: {likes}, length:{longs}"))
write_csv(df_bins_rt, file.path("plot_data", folder ,filename_rt))
write_csv(df_bins_likes, file.path("plot_data", folder ,filename_likes))
write_csv(df_bins_long, file.path("plot_data", folder ,filename_long))
write_csv(df_sum_stats, file.path("plot_data", folder ,filename_sum))

}




#################################################################################
#################################################################################
################################################################################
################################################################################
'
now we run the functions for each combination of filters we will later offer
in the shiny app, we then have 1 csv file per filtering method, we might append
this files again and store them in one big database, however keeping them
separately would also work. The idea is tha we only have to read in the least
amount of data needed at a time. This way we can vastly increase execution
speed and reduce live computing
'

source <- "cleaned/appended"
histO_cleaner <<- function(source){

  for (retweets in retweets_list){
    for(likes in likes_list){
      for(longs in long_list){
        for (folder in folders){
          # read all dfs (one per day)
          df <- readr::read_csv(file.path(source ,glue("{folder}_all.csv")),
                                col_types = cols_only(
                                  created_at = "c",
                                  retweets_count = "i",
                                  likes_count = "i", tweet_length = "i",
                                  language = "c")) 
          
          # call function that wrangles df and saves it
          data_wrangler_and_saver(df, retweets, likes, longs)
        } 
      }
    }
  }
}
