setwd("C:/Users/simon/Desktop/WS_20_21/DS_12/Yahoo")

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
library(lubridate)

#"2020-01-01" format


get_Yahoo_update <- function(country) {
 
  testit <- function(x)
  {
    p1 <- proc.time()
    Sys.sleep(x)
    proc.time() - p1 
  }
  
  country_key <- list("Germany" = "GDAXI","USA" = "DJI","Spain"="IBEX","Switzerland"="SSMI",
                      "Australia"="AXAT","Brasil"="BVSP","Ireland"="ISEQ","Austria"="ATX",
                      "Singapore"="STI%3FP%3D%5ESTI","India"="NSEI","France"="FCHI","Sweden"="OMX",
                      "Argentina"="MERV","Hong Kong"="HSI","Mexico"="MXX")



  indeces <- country_key[[country]] 
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
    
    print(glue("Finished fetching data for {s}"))

  }  
  
  symbol = df$Symbol
    
  for (k in symbol){
    data <- read_csv(paste0(glue("{country}"),"_",k,".csv")) # paste new path of respective directory
    
    last_date <- gsub(",", "", data$Date[1], fixed = TRUE)
    last_date <- gsub(" ", "", last_date, fixed = TRUE)
    last_date <- as.Date(last_date, "%b %d %Y")
    help <- seq(last_date,Sys.Date(), by = "days") # missing dates up to today
    dates <- as.numeric(as.POSIXct(help))
      
    
    print(glue("Started fetching stock data for {k}"))
    datalist <- list()
    url <- paste("https://finance.yahoo.com/quote/", k, "/history?period1=",dates[1],"&period2=",dates[length(dates)],"&interval=1d&filter=history&frequency=1d&includeAdjustedClose=true",sep = "")
    webpage <- readLines(url)
    html <- htmlTreeParse(webpage, useInternalNodes = TRUE, asText = TRUE)
    nodes <- getNodeSet(html, "//table")
    datalist[[k]] <- readHTMLTable(nodes[[1]])
    testit(10)
      
    df_stock <- as.data.frame(do.call(rbind, datalist))
    df_stock <- apply(df_stock,2,as.character)
  
    print(glue("Finished fetching stock data for {k}"))
      
      
    data <- rbind(df_stock,data)
    data <- data[!duplicated(data), ]
      
    write.csv(data,paste0(  glue("{country}"),"_",glue("{k}"),".csv"),row.names = F )
  
  }
  
  for (i in indeces) {
    
    data <- read_csv(paste0(glue("{country}"),"_",i,".csv")) # paste new path of respective directory
    
    last_date <- gsub(" ", "", data$Date[1], fixed = TRUE)
    last_date <- as.Date(last_date, "%d %b %Y")
    help <- seq(last_date,Sys.Date(), by = "days") # missing dates up to today
    dates <- as.numeric(as.POSIXct(help))
    
    print(glue("Started fetching data for {i}"))
    datalist <- list()
    url <- paste("https://au.finance.yahoo.com/quote/%5E",i,"/history?period1=",dates[1],"&period2=", dates[length(dates)],"&interval=1d&filter=history&frequency=1d&includeAdjustedClose=true",sep = "")
    webpage <- readLines(url)
    html <- htmlTreeParse(webpage, useInternalNodes = TRUE, asText = TRUE)
    nodes <- getNodeSet(html, "//table")
    datalist[[i]] <- readHTMLTable(nodes[[1]])
    testit(10)
    
    index_hist <- as.data.frame(do.call(rbind, datalist))
    index_hist <- apply(index_hist,2,as.character)
    
    print(glue("Finished fetching data for {i}."))
  }
    data <- rbind(index_hist,data)
    data <- data[!duplicated(data), ]
    write.csv(data,paste0(glue("{country}"),"_",glue("{i}"),".csv"),row.names = F )
  
}


get_Yahoo_update("Germany")
