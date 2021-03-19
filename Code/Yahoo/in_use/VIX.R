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
library(imputeTS)








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



df <- as.data.frame(df_stock)
df <- df[c(1,5)]
names(df)[2] <- "VIX"

df$Date <- as.Date(df$Date, "%d %b %Y")
df = df %>% map_df(rev)



#impute weekends
df["Date"]  <-  as.Date(df$Date,"%d.%m.%y")

date_vector <- as.data.frame(seq(min(df$Date), max(df$Date), by="days"))
colnames(date_vector)[1]<-"Date"

final <- left_join(date_vector,df)

final["VIX"] <- as.numeric(final$VIX)
final["VIX"] <- sapply(final["VIX"],na_kalman)

#final <- final %>% filter(row_number() <= n()-3)

write.csv(final,paste0("/home/kai-moritzbrehm/share/Lukas_TRUE/Data/Twitter/sentiment/Model/new_controls/VIX.csv"),row.names = F )


