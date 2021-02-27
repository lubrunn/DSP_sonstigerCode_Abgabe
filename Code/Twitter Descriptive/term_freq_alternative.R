string_error <- "current state affair chump"


error_row <- df %>% filter(str_detect(text, string_error))

b <- df %>% filter(date_variable == "2018-11-30")

threshold_single <- 830


####### old

















b %>% group_by(date_variable) %>%
table(unlist(strsplit(tolower(text), " ")))


b %>%
  separate_rows(text, sep = ' ') %>%
  group_by(date_variable, language_variable, text) %>%
  summarise(n = n()) 



b %>% filter(
  likes_count >= likes_filter &
    retweets_count >= retweets_filter &
    #long_tweet == long
    tweet_length >= length_filter)%>%
  
  tidytext::unnest_tokens(word, text) %>%
  group_by(date_variable, language_variable, word) %>%
  summarise(n = n())








select<-function(){
  
  term_frequency1 <- try(if (a <- NULL) print("aha"))
  term_frequency2 <- 2
  
  if(is(term_frequency1, "try-error")) term_frequency2 else term_frequency1
}


###### to alternatives for term_freq computation because first is very quick but throws
# random non reproduciable errors at times, other funciton is more consistent but takes
# twice as long
termfrequency <- select()
