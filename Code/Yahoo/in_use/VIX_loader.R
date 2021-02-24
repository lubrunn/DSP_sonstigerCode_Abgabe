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



#csv  
write.csv(df_stock,paste0("C:/Users/simon/OneDrive - UT Cloud/Eigene Dateien/Data/Twitter/sentiment/Model/VIX.csv"),row.names = F )
  

# Data cleaning
# collect dataframes for control dataset

#######controls
#VIX

df <- read.csv("C:/Users/simon/OneDrive - UT Cloud/Eigene Dateien/Data/Twitter/sentiment/Model/VIX.csv")
names(df)
df <- df %>% subset(select = c(Date,Close.))
names(df)[2] <- "VIX"

df$Date <- as.Date(df$Date, "%d %b %Y")
df = df %>% map_df(rev)

#remove strings
#df = as.data.frame(sapply(df, function(x) gsub("\"", "", x)))
#names(df)
#df <- df %>% subset(select = -c(Eroeffnung,Hoch,Tief,Performance,Volumen,Umsatz,Abstand.Hoch.Tief))
#names(df)[2] <-  "Close"
#names(df)[1] <-  "Date"


#impute weekends
df["Date"]  <-  as.Date(df$Date,"%d.%m.%y")
df["Close"] <- as.numeric(gsub(",",".",df$Close))

date_vector <- as.data.frame(seq(min(df$Date), max(df$Date), by="days"))
colnames(date_vector)[1]<-"Date"

final <- left_join(date_vector,df)

final["VIX"] <- sapply(final["VIX"],na_kalman)

final <- final %>% filter(row_number() <= n()-3)

#Goolge trends
df <- read.csv("C:/Users/simon/OneDrive - UT Cloud/Eigene Dateien/Data/Twitter/sentiment/Model/COVID_trends_US.csv")

final = cbind(final,df["coronavirus"])

#financial distress
df <- read.csv("C:/Users/simon/OneDrive - UT Cloud/Eigene Dateien/Data/Twitter/sentiment/Model/OFR.csv")
names(df)
df = df %>% subset(select = c(Date,OFR.FSI,Credit,Volatility,Safe.assets,Equity.valuation))


df["Date"]  <-  as.Date(df$Date,"%d/%m/%Y")

date_vector <- as.data.frame(seq(min(df$Date), max(df$Date), by="days"))

colnames(date_vector)[1]<-"Date"

df <- left_join(date_vector,df)

df[c("OFR.FSI","Credit","Volatility","Safe.assets","Equity.valuation")] <- sapply(df[c("OFR.FSI","Credit","Volatility","Safe.assets","Equity.valuation")],na_kalman)

final = cbind(final,df[c("OFR.FSI","Credit","Volatility","Safe.assets","Equity.valuation")])

#names(final)[2] <- "VIX"

#economic uncertainty
df <- read.csv("C:/Users/simon/OneDrive - UT Cloud/Eigene Dateien/Data/Twitter/sentiment/Model/Market_uncertainty_global.csv")

final = cbind(final,df["WLEMUINDXD"])


write.csv(final,"C:/Users/simon/OneDrive - UT Cloud/Eigene Dateien/Data/Twitter/sentiment/Model/controls_US.csv",row.names = F )






