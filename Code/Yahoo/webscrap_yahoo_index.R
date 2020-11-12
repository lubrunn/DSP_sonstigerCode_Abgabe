# adjusted from comment here https://stackoverflow.com/questions/40245464/web-scraping-of-key-stats-in-yahoo-finance-with-r

library(XML)
library(glue)
library(tidyverse)
s = "GDAXI"
#list of indeces
indeces <- c("GDAXI","DJI", "FTSE")
#waiting time inbetween index scraping in order to avoid overloading website (and getting blocked)
sleep_time <- 5
for (s in indeces) {
  print(glue("Started fetching data for {s}")) #glue function simply allows "f-string" like strings
  url <- paste0("https://finance.yahoo.com/quote/%5E",s,"/components?p=%5E", s)
  #url = "https://finance.yahoo.com/quote/%5EGDAXI/components?p=%5EGDAXI"
  webpage <- readLines(url, warn = FALSE)
  html <- htmlTreeParse(webpage, useInternalNodes = TRUE, asText = TRUE)
  tableNodes <- getNodeSet(html, "//table")
  assign(s, tableNodes)
  
  # ASSIGN TO STOCK NAMED DFS
  assign(s, readHTMLTable(tableNodes[[1]], as.data.frame = T))
  
  
  # ADD COLUMN TO IDENTIFY STOCK 
  df <- get(s)
  df['Index'] <- s
  assign(s, df)
  
  print(glue("Finished fetching data for {s}, waiting {sleep_time} seconds for next index."))
  Sys.sleep(sleep_time)
}

# COMBINE ALL STOCK DATA 
indexlist <- cbind(mget(indeces))
index_df <- do.call(rbind, indexlist)
# move index to first column
index_df <- index_df[, c(ncol(index_df), 1:ncol(index_df)-1)]
index_df[c("Last Price","Volume")] <- as.numeric(c(as.character(index_df$`Last Price`), gsub(",", "", index_df$Volume)))
#index_df[c("Last Price","Volume")] <- sapply(index_df[c("Last Price","Volume")], as.numeric)

index_df["market_cap"] <- index_df$`Last Price` * index_df$Volume
index_df <- index_df %>% arrange(Index, desc(market_cap))

