options(scipen=999)
source("text_to_dtm.R")
library(networkD3)
library(igraph)
library(glue)
library(rlist)
library(tidytext)



tdm <- dtm_m %>% t()
# change it to a Boolean matrix
tdm[tdm>=1] <- 1
# transform into a term-term adjacency matrix
termMatrix <- tdm %*% t(tdm)
# inspect terms numbered 5 to 10
termMatrix[5:10,5:10]


# build a graph from the above matrix
g <- graph.adjacency(termMatrix, weighted=T, mode = "directed")
# remove loops
g <- simplify(g)
# set labels and degrees of vertices
V(g)$label <- V(g)$name
V(g)$degree <- degree(g)

# set seed to make the layout reproducible
set.seed(3952)
layout1 <- layout.fruchterman.reingold(g)

plot(g, layout=layout1)


# V(g)$label.cex <- 2.2 * V(g)$degree / max(V(g)$degree)+ .2
# V(g)$label.color <- rgb(0, 0, .2, .8)
# V(g)$frame.color <- NA
# egam <- (log(E(g)$weight)+.4) / max(log(E(g)$weight)+.4)
# E(g)$color <- rgb(.5, .5, 0, egam)
# E(g)$width <- egam
# # plot the graph in layout1
# plot(g, layout=layout1)

network <- g
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






#########################
####### ngram
ngram_network_plot <- function(df, n, threshold){


  bi.gram.words <- df %>% 
    unnest_tokens(
      input = text, 
      output = ngram, 
      token = 'ngrams', 
      n = n
    ) %>% 
    filter(! is.na(ngram))
  
  # list of words to split into
  
  split_cols <- c()
  for (i in 1:n){
    word <- glue("word{i}")
    split_cols <- list.append(split_cols, word)
  }
  
  bi.gram.words %<>% 
    separate(col = ngram, into = split_cols, sep = ' ') %>% 
    filter(! is.na(.))
  
  
  # count number of times 4 words occur together
  bi.gram.count <- bi.gram.words %>%
    select(split_cols) %>%
    group_by_all() %>%
    summarise(n = n())  %>%
    arrange(desc(n)) %>%
    # We rename the weight column so that the 
    # associated network gets the weights (see below).
    rename(weight = n)
  
  
  
  
  
  
  # set threshold --> only select word combinations that appear more than
  # threshold times
 
  
  
  
  
  
  network <-  bi.gram.count %>%
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
  
}


ngram_network_plot(tweets, n = 2, 20)



######################################
######### try out area
#######################################
df <- tweets
n <- 2
threshold <- 100
bi.gram.words <- df %>% 
  unnest_tokens(
    input = text, 
    output = ngram, 
    token = 'ngrams', 
    n = n
  ) %>% 
  filter(! is.na(ngram))

# list of words to split into

split_cols <- c()
for (i in 1:n){
  word <- glue("word{i}")
  split_cols <- list.append(split_cols, word)
}

bi.gram.words %<>% 
  separate(col = ngram, into = split_cols, sep = ' ') %>% 
  filter(! is.na(.))


# drop rows where one word appears multiple times
unique_words <- bi.gram.words %>%
  select(split_cols) %>%
  unite(words_all, sep = ", ") %>%
  apply(1,function(x) n_distinct(as.list(strsplit(as.character(x), ",")[[1]]))) == length(split_cols)

# filter out and keep only unique combinations
bi.gram.words <- bi.gram.words[unique_words,]
       
       
     
# count number of times 4 words occur together
bi.gram.count <- bi.gram.words %>%
  select(split_cols) %>%
  group_by_all() %>%
  summarise(n = n())  %>%
  arrange(desc(n)) %>%
  # We rename the weight column so that the 
  # associated network gets the weights (see below).
  rename(weight = n)






# set threshold --> only select word combinations that appear more than
# threshold times

# test what happens if you removve all words after words 3
bi.gram.count <- bi.gram.count %>%
  select(word1, word2, weight)


network_df2 <-  bi.gram.count %>%
  filter(weight > threshold)

network <-  bi.gram.count %>%
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



#######################
### skipgram
skip.window <- 3

skip.gram.words <- tweets_small %>% 
  unnest_tokens(
    input = text, 
    output = skipgram, 
    token = 'skip_ngrams', 
    n = skip.window
  ) %>% 
  filter(! is.na(skipgram))




skip.gram.words$num_words <- skip.gram.words$skipgram %>% 
  map_int(.f = ~ ngram::wordcount(.x))

skip.gram.words %<>% filter(num_words == 2) %>% select(- num_words)

skip.gram.words %<>% 
  separate(col = skipgram, into = c('word1', 'word2'), sep = ' ') %>% 
  
  filter(! is.na(word1)) %>% 
  filter(! is.na(word2)) 

skip.gram.count <- skip.gram.words  %>% 
  count(word1, word2, sort = TRUE) %>% 
  rename(weight = n)



threshold <- 20

network <-  skip.gram.count %>%
  filter(weight > threshold) %>%
  graph_from_data_frame(directed = FALSE)

# Select biggest connected component.  
V(network)$cluster <- clusters(graph = network)$membership

cc.network <- induced_subgraph(
  graph = network,
  vids = which(V(network)$cluster == which.max(clusters(graph = network)$csize))
)

# Store the degree.
V(cc.network)$degree <- strength(graph = cc.network)
# Compute the weight shares.
E(cc.network)$width <- E(cc.network)$weight/max(E(cc.network)$weight)

# Create networkD3 object.
network.D3 <- igraph_to_networkD3(g = cc.network)
# Define node size.
network.D3$nodes <- network.D3$nodes %>% mutate(Degree = (1E-2)*V(cc.network)$degree)
# Degine color group (I will explore this feature later).
network.D3$nodes <- network.D3$nodes %>% mutate(Group = 1)
# Define edges width. 
network.D3$links$Width <- 10*E(cc.network)$width

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











################################################
################ network plot for specific word
###############################################

word_network_plot <- function(df, n, threshold, word){
  
  
  bi.gram.words <- df %>% 
    filter(grepl(word, text)) %>%
    unnest_tokens(
      input = text, 
      output = ngram, 
      token = 'ngrams', 
      n = n
    ) %>% 
    filter(! is.na(ngram))
  
  # list of words to split into
  
  split_cols <- c()
  for (i in 1:n){
    word_col <- glue("word{i}")
    split_cols <- list.append(split_cols, word_col)
  }
  
  bi.gram.words %<>% 
    separate(col = ngram, into = split_cols, sep = ' ') %>% 
    filter(! is.na(.))
  
  
  # count number of times 4 words occur together
  bi.gram.count <- bi.gram.words %>%
    select(split_cols) %>%
    group_by_all() %>%
    summarise(n = n())  %>%
    arrange(desc(n)) %>%
    # We rename the weight column so that the 
    # associated network gets the weights (see below).
    rename(weight = n)
  
  
  
  
  
  
  # set threshold --> only select word combinations that appear more than
  # threshold times
  
  
  network <-  bi.gram.count %>%
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
  
  deg <- degree(network, mode="all")
  network.D3$nodes$size <- deg * 3
  network.D3$nodes$size2 <- sqrt((deg * 3)^3)
  network.D3$nodes$size2 <- deg * 10
  network.D3$nodes$size2 <- network.D3$nodes$size^3
  
  #### assign searched word to differenct group
  network.D3$nodes[network.D3$nodes$name == word,"Group"] <- 10
  
  # adjust colors of nodes, first is rest, second is main node for word (with group 2)
  ColourScale <- 'd3.scaleOrdinal()
            .range([ "#694489", "#ff2a00"]);'
  
  # doc: https://www.rdocumentation.org/packages/networkD3/versions/0.4/topics/forceNetwork
  forceNetwork(
    Links = network.D3$links, 
    Nodes = network.D3$nodes, 
    Source = 'source', 
    Target = 'target',
    NodeID = 'name',
    Group = 'Group', 
    opacity = 0.8,
    Value = 'Width',
    #Nodesize = 'Degree', 
    Nodesize = "size2", # size of nodes, is column name or column number of network.D3$nodes df
    radiusCalculation = JS("Math.sqrt(d.nodesize)-2"), # radius of nodes (not sure whats difference to nodesize but has different effect)
    # We input a JavaScript function.
    #linkWidth = JS("function(d) { return Math.sqrt(d.value); }"), 
    linkWidth = 4, # width of the linkgs
    fontSize = 30, # font size of words
    zoom = TRUE, 
    opacityNoHover = 100,
    linkDistance = 50, # length of links
    charge =  -70, # the more negative the furher away nodes,
    linkColour = "red", #color of links
    bounded = T, # if T plot is limited and can not extend outside of box
    # colourScale = JS("d3.scaleOrdinal(d3.schemeCategory10);")# change color scheme
    colourScale = JS(ColourScale)
  )
  
}

word_network_plot(tweets, 3, 3, "covid")
