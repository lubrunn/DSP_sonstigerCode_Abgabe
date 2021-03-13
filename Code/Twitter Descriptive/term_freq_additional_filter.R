library(data.table)
library(tidyverse)
library(glue)


### this is simply for easier switching between vpcl and local
vpc = FALSE

# read in data
if (vpc == T) {
  setwd("/home/lukasbrunner/share/onedrive_new/Data/Twitter")
} else {
  setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
}


path <- "term_freq/Companies"
source <- "uni_appended"
dest <- "uni_appended_cleaned"
files <- list.files(file.path(path, source))


for (file in files){
  # read in file
  if (!file.exists(file.path(path, dest ,file))){
  df <- fread(file.path(path, source, file))
  
  # remove where n smaller than 6
  df <- df %>% filter(N > 1) %>% 
    select(date_variable, language_variable, word, N, emo)
  
  
  # save
  print(glue("saving {file}"))
  fwrite(df, file.path(path, dest ,file))
  } else {
    print(glue("{file} already exists"))
  }
  
  
  
}
