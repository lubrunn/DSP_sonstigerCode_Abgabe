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
setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter/cleaned/En_NoFilter")
df <- readr::read_csv("En_NoFilter_2018-11-30.csv", col_types = cols(.default = "c", lat = "d", long = "d",
                                       retweets_count = "i", replies_count = "i",
                                       likes_count = "i", tweet_length = "i"))

time1 <- Sys.time()
# put every single word into new column, so one row per word in tweet
tweets_section_words <- df %>%
  tidytext::unnest_tokens(word, text)

# show all pairs out of all pairs per tweet
# feel so forgoten that --> feel so, feel forgotten, feel that, so feel, so forgotten, so that etc.
word_pairs <- tweets_section_words %>%
  widyr::pairwise_count(word, doc_id, sort = T) %>%
  rename("weight" = n)

# date of tweets
date <- as.Date(df$created_at[1], "%Y-%m-%d")

# already filter out pairs that only appear 20 times or less in order to reduce size of df
word_pairs <- word_pairs  %>%
  filter(weight > 50) %>%
  mutate(date = as.character(date)) %>%
  select(item1, item2, weight, date)


print(Sys.time() - time1)



threshold <- 20
network <- word_pairs %>%
  filter(weight > threshold) %>%
  graph_from_data_frame(directed = FALSE)

# Store the degree.
V(network)$degree <- strength(graph = network)
# Compute the weight shares.
E(network)$width <- E(network)$weight/max(E(network)$weight)

# Create networkD3 object.
network.D3 <- igraph_to_networkD3(g = network)
# Define node size.
network.D3$nodes <- network.D3$nodes %>% mutate(Degree = (1E-2)*V(network)$degree)
# Degine color group (I will explore this feature later).
network.D3$nodes <- network.D3$nodes %>% mutate(Group = 1)
# Define edges width. 
network.D3$links$Width <- 10*E(network)$width

# adjust nodesize
deg <- degree(network, mode="all")
#network.D3$nodes$size <- deg * 3


forceNetwork(
  Links = network.D3$links, 
  Nodes = network.D3$nodes, 
  Source = 'source', 
  Target = 'target',
  NodeID = 'name',
  Group = 'Group', 
  opacity = 0.9,
  Value = 'Width',
  Nodesize = 'Degree', 
  # We input a JavaScript function.
  linkWidth = JS("function(d) { return Math.sqrt(d.value); }"), 
  fontSize = 12,
  zoom = TRUE, 
  opacityNoHover = 1
)

# maximum strings length
max(nchar(network_df$item2))



# load data in sql
time <- Sys.time()
setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases")
con <- DBI::dbConnect(RSQLite::SQLite(), "test.db")


time1 <- Sys.time()
DBI::dbSendQuery(con, 'INSERT INTO pairwise_count (date, item1, item2, weight) VALUES (:date, :item1, :item2, :weight);', network_df)
print(Sys.time() - time)
print(Sys.time() - time1)


DBI::dbDisconnect(con)


##############################
########## single words
##############################
### upload to sql
# check how long longest tweet
# max(nchar(tweets_section_words$tweet))
# time <- Sys.time()
# setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases")
# con <- DBI::dbConnect(RSQLite::SQLite(), "test.db")
# 
# 
# time1 <- Sys.time()
# DBI::dbSendQuery(con, 'INSERT INTO pairwise_count_word (id, word, tweet) VALUES (:id, :word, :tweet);', tweets_section_words)
# print(Sys.time() - time)
# 
# 
# 
# DBI::dbDisconnect(con)




time1 <- Sys.time()


df_orig <- df
df <- df_orig

df <- head(df_orig, 1000)
#####################################################################
###################### for specific terms ###########################
#####################################################################

'
here show words that frequently appear together within tweets containing specific terms

'


###############################################
######################### Pre #################
###############################################
# first tokenize tweets
tweets_section_words <- df %>%
  select(doc_id, text, created_at) %>%
  tidytext::unnest_tokens(word, text) %>%
  left_join(subset(df, select = c(doc_id, text))) 

# filter out uncommon words
tweets_section_words_filt <- tweets_section_words %>%
  group_by(word) %>%
  filter(n() >= 75) %>%
  ungroup()



###################################################
######################## live #####################
###################################################
# controllable
tomatch <- c()
threshold <- 0
min_corr <- 0.2

# filter out words for tweets in tomatch list
# also filter for word frew within this filtered df
word_cors_pre <- tweets_section_words_filt %>%
  # if list provided to specify tweets to look at then extract only those tweets
  { if (!is.null(tomatch)) filter(., grepl(paste(tomatch, collapse="|"), text)) else . } %>%
  
  group_by(word) %>%
  filter(n() >= threshold)


###############################################

word_cors <- word_cors_pre %>%
  widyr::pairwise_cor(word, doc_id, sort = TRUE) 


network_pre <-  word_cors %>%
  #filter(item1 %in% c("covid", "trump", "china")) %>%
  filter(correlation > 0) %>% # fix in order to avoid overcrowed plot
  filter(correlation > min_corr) # optional


network <- network_pre %>%
  graph_from_data_frame(directed = FALSE)



# Store the degree.
V(network)$degree <- strength(graph = network)


# Create networkD3 object.
network.D3 <- igraph_to_networkD3(g = network)
# Define node size.
network.D3$nodes <- network.D3$nodes %>% mutate(Degree = (1E-2)*V(network)$degree)
# Degine color group (I will explore this feature later).
network.D3$nodes <- network.D3$nodes %>% mutate(Group = 1)


deg <- degree(network, mode="all")
network.D3$nodes$size <- deg * 3




# adjust colors of nodes, first is rest, second is main node for word (with group 2)
ColourScale <- 'd3.scaleOrdinal()
            .range(["#ff2a00" ,"#694489"]);'

# doc: https://www.rdocumentation.org/packages/networkD3/versions/0.4/topics/forceNetwork
forceNetwork(
  Links = network.D3$links, 
  Nodes = network.D3$nodes, 
  Source = 'source', 
  Target = 'target',
  NodeID = 'name',
  Group = 'Group', 
  opacity = 0.8,
  #Value = 'Width',
  #Nodesize = 'Degree', 
  Nodesize = "size", # size of nodes, is column name or column number of network.D3$nodes df
  radiusCalculation = JS("Math.sqrt(d.nodesize)+2"), # radius of nodes (not sure whats difference to nodesize but has different effect)
  # We input a JavaScript function.
  #linkWidth = JS("function(d) { return Math.sqrt(d.value); }"), 
  linkWidth = 1, # width of the linkgs
  fontSize = 30, # font size of words
  zoom = TRUE, 
  opacityNoHover = 100,
  linkDistance = 100, # length of links
  charge =  -70, # the more negative the furher away nodes,
  linkColour = "red", #color of links
  bounded = F, # if T plot is limited and can not extend outside of box
  # colourScale = JS("d3.scaleOrdinal(d3.schemeCategory10);")# change color scheme
  colourScale = JS(ColourScale)
)







####### term freq plots

'
here show words that frequently appear together with words of interest
e.g.
tweets:
1. this is a tweet about trump and ivanka
2. this is also a tweet about trump and his daughter


--> process here:
all possible bigrams:
1.  this is, is this, ..., trump and, trump ivanka,...., ivnaka trump
2. ...

- keep only bigrams with trump in place 1 of bigram
- compute correlation of appearances of bigrams were trump is in place 1
- plot according to coor

  

'

######### controls
number_words <- 20000

# here only combinations were words of interest appear in item1
# so bigrams without words are ommitted --> in network plot they are kept

word_cors %>%
  filter(item1 %in% tomatch) %>%
  group_by(item1) %>%
  top_n(number_words) %>%
  ungroup() %>%
  mutate(item2 = reorder(item2, correlation)) %>%
  ggplot(aes(item2, correlation)) +
  geom_bar(stat = "identity") +
  facet_wrap(~ item1, scales = "free") +
  coord_flip()

