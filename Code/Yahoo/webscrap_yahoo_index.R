# adjusted from comment here https://stackoverflow.com/questions/40245464/web-scraping-of-key-stats-in-yahoo-finance-with-r

library(XML)
library(glue)
library(tidyverse)
library(tm)



#stopwords for cleaning
stopwords <- c("AG","SE","Aktiengesellschaft","Kommanditgesellschaft auf Aktien",
               "plc","Aktiengesellschaft in München","KGaA","AG & Co. KGaA",
               "SE & Co. KGaA","Inc","Co",", inc", "SA","Ltd","Limited","PLC","Plc",
               "(Holdings)","Societe en commandite par actions","(publ)","SCA","SAIC","Holding",
               "SAB","de","CV","S A B","C V", "Company", "Group", "The", "Corporation",
               "Incorporated", "HBC", "NV", "plc", "International")

country_key <- list("Germany" = "GDAXI","USA" = "DJI","England" = "FTSE")

country <- list("Germany", "USA", "England")

#list of indeces
indeces <- list("GDAXI", "DJI", "FTSE")
#waiting time inbetween index scraping in order to avoid overloading website (and getting blocked)
sleep_time <- 60
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
#indexlist <- cbind(mget(indeces))
#index_df <- do.call(rbind, indexlist)
index_df <- do.call(rbind, list(GDAXI, DJI, FTSE))
# move index to first column
index_df <- index_df[, c(ncol(index_df), 1:ncol(index_df)-1)]
index_df[c("Last Price","Volume")] <- as.numeric(c(as.character(index_df$`Last Price`), gsub(",", "", index_df$Volume)))
#index_df[c("Last Price","Volume")] <- sapply(index_df[c("Last Price","Volume")], as.numeric)

index_df["market_cap"] <- index_df$`Last Price` * index_df$Volume
index_df <- index_df %>% arrange(Index, desc(market_cap))




index_df$`Company Name` <- removeWords(index_df$`Company Name`,stopwords)
index_df$`Company Name` <- str_remove(index_df$`Company Name`, "[.]")
index_df$`Company Name` <- str_remove(index_df$`Company Name`, "[.]")
index_df$`Company Name` <- str_remove(index_df$`Company Name`, "[.]")
index_df$`Company Name` <- str_remove(index_df$`Company Name`, "[.]")
index_df$`Company Name` <- str_remove(index_df$`Company Name`, "[,]")
index_df$`Company Name` <- str_remove(index_df$`Company Name`, "[,]")
index_df$`Company Name` <- str_remove(index_df$`Company Name`, "\\(")
index_df$`Company Name` <- str_remove(index_df$`Company Name`, "\\)")
index_df$`Company Name` <- str_remove(index_df$`Company Name`, "[&]")
index_df$`Company Name` <- trimws(index_df$`Company Name`) #remove trailing and leading whitespace
#manuelle adjustments
index_df$`Company Name`[index_df$`Company Name` == "MULTI-UNITS LUXEMBOURG - Lyxor Euro Government Bond DR UCITS ETF - Acc"] <- "Lyxor"
index_df$`Company Name`[index_df$`Company Name` == "Bayerische Motoren Werke"] <- "BMW"
index_df$`Company Name`[index_df$`Company Name` == "International Business Machines"] <- "IBM"	
index_df$`Company Name`[index_df$`Company Name` == "Verizon Communications"] <- "Verizon"	
index_df$`Company Name`[index_df$`Company Name` == "Royal Dutch Shell"] <- "Shell"	
index_df$`Company Name`[index_df$`Company Name` == "Cisco Systems"] <- "Cisco"	
index_df$`Company Name`[index_df$`Company Name` == "JPMorgan Chase"] <- "JPMorgan"	
index_df$`Company Name`[index_df$`Company Name` == "salesforcecom"] <- "salesforce"	
index_df$`Company Name`[index_df$`Company Name` == "Walgreens Boots Alliance"] <- "Walgreens"	
index_df$`Company Name`[index_df$`Company Name` == "Infineon Technologies"] <- "Infineon"	
index_df$`Company Name`[index_df$`Company Name` == "Rentokil Initial"] <- "Rentokil"	
index_df$`Company Name`[index_df$`Company Name` == "salesforcecom"] <- "salesforce"	



name_df <- index_df[,c("Index", "Symbol", "Company Name")]
write.csv(name_df, "C:/Users/lukas/Documents/Uni/Data Science Project/Python/Stock/data/company_names.csv", row.names = F)
