library(dplyr)
library(readr)
library(networkD3)
library(igraph)
library(glue)
library(ggplot2)


################################
##################### pre

##############################
# preprocess pairwise plot
setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")


source = "cleaned"
dest = "network_plot"



#####################################################################
###################### Correlation plot #############################
#####################################################################

'
here show words that frequently appear together within tweets containing specific terms

'


###############################################
######################### Pre #################
###############################################
folders <- list.files(source)
folder <- folders[3]


files <- list.files(file.path(source, folder))
filename <- files[1]

time1 <- Sys.time()


# load df
if (folder == "Companies"){
  subfolders <- list.files(source, )
  path_source <- file.path(source, folder, subfolder, filename)
} else {
  path_source <- file.path(source, folder, filename)
  
}




df_transformer <- function(df, path_source, path_dest){

df_orig <- readr::read_csv(path_source, col_types = cols_only(doc_id = "c", text = "c",
                                                      created_at = "c",
                      likes_count = "i", retweets_count = "i", long_tweet = "i"))
# first tokenize tweets

df <- df_orig %>%
  select(doc_id, text, created_at) %>%
  tidytext::unnest_tokens(word, text) %>%
  left_join(subset(df_orig, select = c(doc_id, text, retweets_count, likes_count, long_tweet))) 

# filter out uncommon words
df <- df %>%
  group_by(word) %>%
  filter(n() >= 50) %>%
  ungroup()

df_new <- df_orig %>% filter(doc_id %in% df$doc_id) 


 
 # save df
  path_save <- file.path(path_dest, filename)
  readr::write_csv(df, path_save)

}

print(Sys.time() - time1)





