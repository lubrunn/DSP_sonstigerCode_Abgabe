



# network plot

sent_to_network_plot <- function(df, threshold){
  
  
  
  '
gives nice overview of all possible word combinations in a day
bigramm:
  shows only word combinations moving forward
here:
  shows all bigrams from a sentence --> backwards and skipping words

example: "I am lukas and like R"
bigram:
  "I am", "am lukas", "lukas and" etc.
herre:
  "I am", "I lukas", ... , "I R", "am I", "am lukas", etc.
  
pro bigram:
  - uebersichtlicher da weniger
pro here:
  - mehr connections, man sieht connection in beide Richtungen und sieht auch Beziehungen von Woertern die nicht direkt nacheinander kommen
con bigram:
  - nur consecutive bigram und nicht backwards --> missing info
con here:
  - kann unübersichtlich werden, wenn man es nicht richtig einstellt --> mehr requirements an User oder preprocess
  
'
# put every single word into new column, so one row per word in tweet
tweets_section_words <- df %>%
  unnest_tokens(word, text)

# show all pairs out of all pairs per tweet
# feel so forgoten that --> feel so, feel forgotten, feel that, so feel, so forgotten, so that etc.
word_pairs <- tweets_section_words %>%
  widyr::pairwise_count(word, doc_id, sort = T) %>%
  rename("weight" = n)

  
  
network_df <- word_pairs  %>%
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
}

sent_to_network_plot(tweets, 20)






################################################
################ network plot for specific word
###############################################

word_network_plot <- function(df, threshold, word){


  
  
  # put every single word into new column, so one row per word in tweet
  tweets_section_words <- df %>%
    filter(grepl(word, text)) %>% # here added filter to only get sentences where word appears
    unnest_tokens(word, text)
  
  # show all pairs out of all pairs per tweet
  # feel so forgoten that --> feel so, feel forgotten, feel that, so feel, so forgotten, so that etc.
  word_pairs <- tweets_section_words %>%
    widyr::pairwise_count(word, doc_id, sort = T) %>%
    rename("weight" = n)
  
  
  
  
  
  # set threshold --> only select word combinations that appear more than
  # threshold times
  
  
  network <-  word_pairs %>%
    filter(item2 != word, weight > threshold) %>%
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
  network.D3$nodes$size2 <- network.D3$nodes$size^2
  
  #### assign searched word to differenct group
  network.D3$nodes[network.D3$nodes$name == word,"Group"] <- 2
  
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
    Value = 'Width',
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
  
}

word_network_plot(tweets, 2, "covid")





###############################
###### correlations
###############################

'
compared two bigram plots

- show words by correlation --> how often do they appear together compared to alone
- before when filtering for freq we just got words that appear often anyway
- here now get words that really appear often together independent of their total frequency

- advantage :
  - shows more words
  - better connections
  - better overview
  - can also only look at single words easily

- disadvantage:
  - very large for small filters
  
'
tweets_section_words <- tweets %>%
  unnest_tokens(word, text)


word_cors <- tweets_section_words %>%
  group_by(word) %>%
  filter(n() >= 10) %>% # only keep words that appear at least 20 times
  widyr::pairwise_cor(word, doc_id, sort = TRUE)


# show words used with trump
word_cors %>%
  filter(item1 == "trump")

# most frequently used word with certain words in list
word_cors %>%
  filter(item1 %in% c("covid", "trump", "china")) %>%
  group_by(item1) %>%
  top_n(6) %>%
  ungroup() %>%
  mutate(item2 = reorder(item2, correlation)) %>%
  ggplot(aes(item2, correlation)) +
  geom_bar(stat = "identity") +
  facet_wrap(~ item1, scales = "free") +
  coord_flip()



network <-  word_cors %>%
  filter(correlation > 0.15) %>% #filter out words wih too low correlation
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



#################################################################
########## same but for only certain terms  #####################
#################################################################

'
here show only bigrams with words of interest
e.g. tweet: covid has taken a toll
show : covid has, covid taken, covid toll etc. but not: has taken, taken a etc.

- good for getting overview what people tweet with regard to term of interest
- bad for going deeper because gets crowed around term of interest

'
tweets_section_words <- tweets %>%
  unnest_tokens(word, text)


word_cors <- tweets_section_words %>%
  group_by(word) %>%
   filter(n() >= 20) %>%
  widyr::pairwise_cor(word, doc_id, sort = TRUE)

word_cors_b <- word_cors %>% filter(item1 == "covid")



network <-  word_cors %>%
  filter(item1 %in% c("covid", "trump", "china") |
           item2 %in%  c("covid", "trump", "china")) %>%
  filter(correlation > 0.05) %>%
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







##############################################
####### only tweets with word in them but then all connections for these tweets
# e.g. tweet: "trump ate big bag of chips" --> trum ate, trum big etc. but also big bag, bag chips etc.
################################################
' 
this is a nice way to get an overview of tweets involving certain terms
- goes deeper than just showing combinations with search term and is not so crowded around word of interest
- hard to track which word belong to which search term



'

tomatch <- c("trump", "covid", "russia")

# tweets_section_words_a <- tweets %>%
#   filter(grepl(paste(tomatch, collapse="|"), text)) %>%
#   unnest_tokens(word, text)


tweets_section_words_b <- tweets %>%
  unnest_tokens(word, text) %>%
  left_join(subset(tweets, select = c(doc_id, text))) %>%
filter(grepl(paste(tomatch, collapse="|"), text))


# problem thru duplcate id
# find out which rows in one but no the other
# id_a <- unique(tweets_section_words_a$doc_id)
# id_b <- unique(tweets_section_words_b$doc_id)
# 
# conc <- rbind(tweets_section_words_a, subset(tweets_section_words_b,select =  -text))
# a <- conc[!(duplicated(conc) | duplicated(conc, fromLast = TRUE)), ]
# 
# 
# b <- tweets_section_words_b %>% filter(doc_id %in% a$doc_id)


word_cors <- tweets_section_words %>%
  group_by(word) %>%
  filter(n() >= 5) %>%
  widyr::pairwise_cor(word, doc_id, sort = TRUE)





network <-  word_cors %>%
  #filter(item1 %in% c("covid", "trump", "china")) %>%
  filter(correlation > 0.2) %>%
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







  