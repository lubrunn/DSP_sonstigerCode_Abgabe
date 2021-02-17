options(scipen=999)
source("text_to_dtm.R")
library(networkD3)
library(igraph)
library(glue)
library(rlist)



tdm <- dtm_m %>% t()
# change it to a Boolean matrix
tdm[tdm>=1] <- 1
# transform into a term-term adjacency matrix
termMatrix <- tdm %*% t(tdm)
# inspect terms numbered 5 to 10
termMatrix[5:10,5:10]


# build a graph from the above matrix
g <- graph.adjacency(termMatrix, weighted=T, mode = "undirected")
# remove loops
g <- simplify(g)
# set labels and degrees of vertices
V(g)$label <- V(g)$name
V(g)$degree <- degree(g)

# set seed to make the layout reproducible
set.seed(3952)
layout1 <- layout.fruchterman.reingold(g)

plot(g, layout=layout1)


V(g)$label.cex <- 2.2 * V(g)$degree / max(V(g)$degree)+ .2
V(g)$label.color <- rgb(0, 0, .2, .8)
V(g)$frame.color <- NA
egam <- (log(E(g)$weight)+.4) / max(log(E(g)$weight)+.4)
E(g)$color <- rgb(.5, .5, 0, egam)
E(g)$width <- egam
# plot the graph in layout1
plot(g, layout=layout1)









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


ngram_network_plot(tweets, 4, 5)







#######################
### skipgram
skip.window <- 2

skip.gram.words <- tweets %>% 
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

