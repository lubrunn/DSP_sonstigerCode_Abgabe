library(openxlsx)
library(XML)
library(glue)
library(tidyverse)
library(magrittr)
library(httr)
library(rvest)
library(stringr)
library(dplyr)
library(tm)
library(xml2)
library(anytime)

testit <- function(x)
{
  p1 <- proc.time()
  Sys.sleep(x)
  proc.time() - p1 
}

# create date structure for historic data of stock

lastdate <- as.Date("2018-11-30")
help <- rev(seq(lastdate,Sys.Date(), by = "days"))
dates <- as.numeric(as.POSIXct(c(help[seq(1,length(help),135)],lastdate)))





datalist <- list()
for (j in 1:(length(dates) - 1)) {
  url <- paste("https://au.finance.yahoo.com/quote/%5E","VIX","/history?period1=",dates[j + 1],"&period2=", dates[j],"&interval=1d&filter=history&frequency=1d&includeAdjustedClose=true",sep = "")
  webpage <- readLines(url)
  html <- htmlTreeParse(webpage, useInternalNodes = TRUE, asText = TRUE)
  nodes <- getNodeSet(html, "//table")
  datalist[[j]] <- readHTMLTable(nodes[[1]])
  testit(2)

}

df_stock <- as.data.frame(do.call(rbind, datalist))
df_stock <- apply(df_stock,2,as.character)



#csv  
write.csv(df_stock,paste0("C:/Users/simon/OneDrive - UT Cloud/Eigene Dateien/Data/Twitter/sentiment/Model/VIX.csv"),row.names = F )
  






