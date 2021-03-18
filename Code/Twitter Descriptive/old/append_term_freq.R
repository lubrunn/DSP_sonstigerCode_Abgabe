#################################################################################
#################################################################################
############################# packages ##########################################
library(tidyverse)

library(vroom)
library(glue)




################################################################################
### this is simply for easier switching between vpcl and local
vpc = FALSE

# read in data
if (vpc == T) {
  setwd("/home/lukasbrunner/share/onedrive_new/Data/Twitter")
} else {
  setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
}




# which folders should be appended
source_main <- "term_freq"

# list all folders in source main
folders <- list.files(source_main)

folders <- folders[3]
folder <- folders[1]

files <- list.files(file.path(source_main, folder))[1:500]
df_all <- NULL
for (file in files){
  print(glue("Woking on {file}"))
df <- vroom::vroom(file.path(source_main, folder, file), delim = ",")

if(is.null(df_all)){
  df_all <- df
} else{
df_all <- bind_rows(df_all, df)
}

}


df_all_ <- df_all %>%
  mutate(
    across(-c(date_variable, language_variable), ~replace_na(.x, 0)),
  )


# format ate to string
df_all_$date_variable <- as.character(df_all_$date_variable)



