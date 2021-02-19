
# put every single word into new column, so one row per word in tweet
tweets_section_words <- tweets_small%>%
  unnest_tokens(word, text)

# show all pairs out of all pairs per tweet
# feel so forgoten that --> feel so, feel forgotten, feel that, so feel, so forgotten, so that etc.
word_pairs <- tweets_section_words %>%
  widyr::pairwise_count(word, doc_id, sort = T) %>%
  rename("weight" = n)
  


# network plot
threshold <- 0
network_df <-  word_pairs %>%
  filter(weight > threshold)

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
