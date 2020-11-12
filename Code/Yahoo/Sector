library(magrittr)
library(httr)
library(rvest)
library(XML)
library(stringr)

testit <- function(x)
{
  p1 <- proc.time()
  Sys.sleep(x)
  proc.time() - p1 
}


symbol = c("SAP.DE","LIN.DE","SIE.DE","ALV.DE","DTE.DE","ADS.DE","DAI.DE","DPW.DE","BAS.DE","BAYN.DE")

final_list <- list()

for(i in symbol){ 
  url <- paste("https://de.finance.yahoo.com/quote/",i,"/profile?p=",i,sep="")
  html <- read_html(url)
 
  text_raw <- html %>% html_nodes(xpath='//*[contains(concat( " ", @class, " " ), concat( " ", "Mb(25px)", " " ))]') 
  
  text_clean <- xml_children(text_raw)[[2]] %>% html_text()
  location <- gregexpr(":",text_clean)[[1]]
  
  sector <- substr(text_clean,location[1]+2,location[2]-8)
  branch <- substr(text_clean,location[2]+2, location[3]-20)

  final_list[[i]] <- as.list(c(sector,branch))
  
  testit(2.5) # sleep for 2.5 seconds
  
}

final_df <- as.data.frame(t(do.call(rbind, final_list)),row.names = c("sector","branch"))

