get_Yahoo_update <- function(country) {
  
  if (!require("openxlsx")) install.packages("openxlsx")
  library(openxlsx)
  if (!require("XML")) install.packages("XML")
  library(XML)
  if (!require("glue")) install.packages("glue")
  library(glue)
  if (!require("tidyverse")) install.packages("tidyverse")
  library(tidyverse)
  if (!require("magrittr")) install.packages("magrittr")
  library(magrittr)
  if (!require("httr")) install.packages("httr")
  library(httr)
  if (!require("rvest")) install.packages("rvest")
  library(rvest)
  if (!require("stringr")) install.packages("stringr")
  library(stringr)
  if (!require("dplyr")) install.packages("dplyr")
  library(dplyr)
  if (!require("tm")) install.packages("tm")
  library(tm)
  if (!require("xml2")) install.packages("xml2")
  library(xml2)
  if (!require("anytime")) install.packages("anytime")
  library(anytime)
  if (!require("lubridate")) install.packages("lubridate")
  library(lubridate)
  

  
  # create key for referencing
  country_key <- list("Germany" = "GDAXI","USA" = "DJI")
  index <- country_key[[country]] 
  
  # sleep
  testit <- function(x)
  {
    p1 <- proc.time()
    Sys.sleep(x)
    proc.time() - p1 
  }
  
  # load the file with all the symbols
  df_index <- read_csv(paste0(glue("{country}"),"/",glue("{country}"),"_Index_Components",".csv"))
  #store symbols in dataframe
  symbol = df_index$Symbol
  
  for (k in symbol){
    
    data <- read_csv(paste0(glue("{country}"),"/",glue("{country}"),"_",k,".csv")) # paste new path of respective directory
    
    # get the most recent date from the dataframe
    last_date <- gsub(",", "", data$Date[1], fixed = TRUE)
    # prepare fo conversion to date
    last_date <- gsub(" ", "", last_date, fixed = TRUE)
    # convert to date
    last_date <- as.Date(last_date, "%b %d %Y")
    #create a vector of the most recent date of the dataframe until today
    help <- seq(last_date,Sys.Date(), by = "days") 
    # convert to format used in Yahoo
    dates <- as.numeric(as.POSIXct(help))
    
    
    print(glue("Started fetching stock data for {k}"))
    # create empty list for data
    datalist <- list()
    # load the data with the symbol = k and the range of required dates
    url <- paste("https://finance.yahoo.com/quote/", k, "/history?period1=",dates[1],"&period2=",dates[length(dates)],"&interval=1d&filter=history&frequency=1d&includeAdjustedClose=true",sep = "")
    webpage <- readLines(url,warn=FALSE)
    html <- htmlTreeParse(webpage, useInternalNodes = TRUE, asText = TRUE)
    nodes <- getNodeSet(html, "//table")
    datalist[[k]] <- readHTMLTable(nodes[[1]])
    testit(10)
    # create data frame from readHTMLTable object
    df_stock <- as.data.frame(do.call(rbind, datalist))
    df_stock <- apply(df_stock,2,as.character)
    
    print(glue("Finished fetching stock data for {k}"))
    
    # combine the missing dates to the loaded data set 
    data <- rbind(df_stock,data)
    # delete duplicate values
    data <- data[!duplicated(data$Date), ]
    # overwrite the old data set with the complete data set for today
    write.csv(data,paste0(glue("{country}"),"/",glue("{country}"),"_",glue("{k}"),".csv"),row.names = F )
    
  }
  # same procedure for the index
  for (i in index) {
    
    data <- read_csv(paste0(glue("{country}"),"/",glue("{country}"),"_",i,".csv")) 
    
    last_date <- gsub(" ", "", data$Date[1], fixed = TRUE)
    last_date <- as.Date(last_date, "%d %b %Y")
    help <- seq(last_date,Sys.Date(), by = "days") # missing dates up to today
    dates <- as.numeric(as.POSIXct(help))
    
    print(glue("Started fetching data for {i}"))
    datalist <- list()
    url <- paste("https://au.finance.yahoo.com/quote/%5E",i,"/history?period1=",dates[1],"&period2=", dates[length(dates)],"&interval=1d&filter=history&frequency=1d&includeAdjustedClose=true",sep = "")
    webpage <- readLines(url,warn=FALSE)
    html <- htmlTreeParse(webpage, useInternalNodes = TRUE, asText = TRUE)
    nodes <- getNodeSet(html, "//table")
    datalist[[i]] <- readHTMLTable(nodes[[1]])
    testit(10)
    
    index_hist <- as.data.frame(do.call(rbind, datalist))
    index_hist <- apply(index_hist,2,as.character)
    
    print(glue("Finished fetching data for {i}."))
    
    data <- rbind(index_hist,data)
    data <- data[!duplicated(data$Date), ]
    write.csv(data,paste0(glue("{country}"),"/",glue("{country}"),"_",glue("{i}"),".csv"),row.names = F )
  }
}






