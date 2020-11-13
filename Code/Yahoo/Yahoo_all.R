setwd("C:/Users/simon/Desktop/WS_20_21/DS_12/Yahoo")
install.packages("openxlsx") 
library(openxlsx)
install.packages("XML") 
library(XML)
install.packages("glue") 
library(glue)
install.packages("tidyverse") 
library(tidyverse)
install.packages("magrittr") 
library(magrittr)
install.packages("httr") 
library(httr)
install.packages("rvest") 
library(rvest)
install.packages("stringr") 
library(stringr)
install.packages("dplyr") 
library(dplyr)
install.packages("tm") 
library(tm)
install.packages("xml2") 
library(xml2)
install.packages("anytime") 
library(anytime)

#"2020-01-01" format

get_Yahoo_Financials <- function(country,date) {

  #dictionary
  country_key <- list("Germany" = "GDAXI","USA" = "DJI","Spain"="IBEX","Switzerland"="SSMI",
            "Australia"="AXAT","Brasil"="BVSP","Ireland"="ISEQ","Austria"="ATX",
            "Singapore"="STI%3FP%3D%5ESTI","India"="NSEI","France"="FCHI","Sweden"="OMX",
            "Argentina"="MERV","Hong Kong"="HSI","Mexico"="MXX")
  
  #stopwords for cleaning
  stopwords <- c("AG","SE","Aktiengesellschaft","Kommanditgesellschaft auf Aktien",
                 "plc","Aktiengesellschaft in München","KGaA","AG & Co. KGaA",
                 "SE & Co. KGaA","Inc","Co",", inc", "SA","Ltd","Limited","PLC","Plc")
  
  testit <- function(x)
  {
    p1 <- proc.time()
    Sys.sleep(x)
    proc.time() - p1 
  }
  
  #list of indeces
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
    testit(3)
  
  
      symbol = df$Symbol
  
      final_list <- list()
  
      for(b in symbol){ 
        print(glue("Started fetching branch for {b}"))
        url <- paste("https://de.finance.yahoo.com/quote/",b,"/profile?p=",b,sep="")
        html <- read_html(url)
        
        text_raw <- html %>% html_nodes(xpath='//*[contains(concat( " ", @class, " " ), concat( " ", "Mb(25px)", " " ))]') 
        
        if (length(text_raw) == 0){
          sector <- "NA"
          branch <- "NA"
        
        }  else {
          text_clean <- xml_children(text_raw)[[2]] %>% html_text()
          
          #strip text around ":"
          location <- gregexpr(":",text_clean)[[1]]
          sector <- substr(text_clean,location[1]+2,location[2]-8)
          branch <- substr(text_clean,location[2]+2, location[3]-20)
        
        }
        #append sector and branch to stock
        final_list[[b]] <- as.list(c(sector,branch))
        print(glue("Finished fetching branch for {b}"))
        
        testit(5) # sleep for 5 seconds
        
      }
      #create dataframe out of list
      final_df <- as.data.frame(do.call(rbind, final_list),row.names = df$Symbol)
      colnames(final_df) <- c("sector", "branch")
      
      final_df <- tibble::rownames_to_column(final_df, "Symbol")
      
      #merge components of Index with sector & branch
      merge_Comp_Sec <- merge(df,final_df)
      
      #cleaning process of company name for twitter search (could be optimized)
      merge_Comp_Sec$`Company Name` <- removeWords(merge_Comp_Sec$`Company Name`,stopwords)
      merge_Comp_Sec$`Company Name` <- str_remove(merge_Comp_Sec$`Company Name`, "[.]")
      merge_Comp_Sec$`Company Name` <- str_remove(merge_Comp_Sec$`Company Name`, "[.]")
      merge_Comp_Sec$`Company Name` <- str_remove(merge_Comp_Sec$`Company Name`, "[.]")
      merge_Comp_Sec$`Company Name` <- str_remove(merge_Comp_Sec$`Company Name`, "[,]")
      merge_Comp_Sec$`Company Name` <- str_remove(merge_Comp_Sec$`Company Name`, "[,]")
      merge_Comp_Sec$`Company Name` <- str_remove(merge_Comp_Sec$`Company Name`, "[&]")
      
      #create csv 
      merge_Comp_Sec <- apply(merge_Comp_Sec,2,as.character)
      write.csv(merge_Comp_Sec,paste0("Germany","_","Index_Components",".csv") ,row.names = F)
      
      lastdate <- as.Date(date)
      help <- rev(seq(lastdate,Sys.Date(), by = "days"))
      dates <- as.numeric(as.POSIXct(c(help[seq(1,length(help),135)],lastdate)))
      
      for (i in indeces) {
        print(glue("Started fetching data for {i}"))
        datalist <- list()
        for (j in 1:(length(dates) - 1)) {
          url <- paste("https://au.finance.yahoo.com/quote/%5E",i,"/history?period1=",dates[j + 1],"&period2=", dates[j],"&interval=1d&filter=history&frequency=1d&includeAdjustedClose=true",sep = "")
          webpage <- readLines(url)
          html <- htmlTreeParse(webpage, useInternalNodes = TRUE, asText = TRUE)
          nodes <- getNodeSet(html, "//table")
          datalist[[j]] <- readHTMLTable(nodes[[1]])
          testit(5)
        }
        index_hist <- as.data.frame(do.call(rbind, datalist))
        print(glue("Finished fetching data for {i}."))
      }
     
      index_hist <- apply(index_hist,2,as.character)
      write.csv(index_hist,paste0(glue("{country}"),"_",glue("{i}"),".csv") ,row.names = F)
      
  
  
      # create date structure for historic data of stock
      lastdate <- as.Date(date)
      help <- rev(seq(lastdate,Sys.Date(), by = "days"))
      dates <- as.numeric(as.POSIXct(c(help[seq(1,length(help),135)],lastdate)))
      
      
      for (ii in symbol) {
        print(glue("Started fetching stock data for {ii}"))
        datalist <- list()
        for (j in 1:(length(dates) - 1)) {
          url <- paste("https://finance.yahoo.com/quote/", ii, "/history?period1=",dates[j + 1],"&period2=",dates[j],"&interval=1d&filter=history&frequency=1d&includeAdjustedClose=true",sep = "")
          webpage <- readLines(url)
          html <- htmlTreeParse(webpage, useInternalNodes = TRUE, asText = TRUE)
          nodes <- getNodeSet(html, "//table")
          datalist[[j]] <- readHTMLTable(nodes[[1]])
          testit(5)
        }
        df_stock <- as.data.frame(do.call(rbind, datalist))
        
        #csv  
        df_stock <- apply(df_stock,2,as.character)
        write.csv(df_stock,paste0(glue("{country}"),"_",glue("{ii}"),".csv"),row.names = F )
        
        print(glue("Finished fetching stock data for {ii}"))
        testit(5)
      }
  
  }

}

get_Yahoo_Financials("Germany","2020-01-01")



