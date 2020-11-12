#I changed this code -signed Lukas

install.packages("rvest")
library(rvest)
install.packages("xml2")
library("xml2")
install.packages("XML")
library("XML")
install.packages("anytime")
library("anytime")

testit <- function(x)
{
  p1 <- proc.time()
  Sys.sleep(x)
  proc.time() - p1
}

symbols <- c("SAP.DE","LIN.DE","SIE.DE","ALV.DE","DTE.DE","ADS.DE","DAI.DE","DPW.DE","BAS.DE","BAYN.DE")

lastdate <- as.Date("2020-01-01")
help <- rev(seq(lastdate,Sys.Date(), by = "days"))
dates <- as.numeric(as.POSIXct(c(help[seq(1,length(help),135)],lastdate)))


for (i in symbols) {
  datalist <- list()
   for (j in 1:(length(dates) - 1)) {
    url <- paste("https://finance.yahoo.com/quote/", i, "/history?period1=",dates[j + 1],"&period2=",dates[j],"&interval=1d&filter=history&frequency=1d&includeAdjustedClose=true",sep = "")
    webpage <- readLines(url)
    html <- htmlTreeParse(webpage, useInternalNodes = TRUE, asText = TRUE)
    nodes <- getNodeSet(html, "//table")
    datalist[[j]] <- readHTMLTable(nodes[[1]])
    testit(1)
   }
  name <- paste("Stock",i,sep = "")
  assign(name,do.call(rbind,datalist))
testit(1)
}









#########################################################
anydate(1604966400)
as.numeric(as.POSIXct("2020-11-10"))
as.numeric(as.POSIXct(Sys.Date() - 135))


for (i in symbols){
  url <- paste("https://finance.yahoo.com/quote/", i, "/history?period1=1573344000&period2=1592784000&interval=1d&filter=history&frequency=1d&includeAdjustedClose=true",sep="")
  webpage <- readLines(url)
  html <- htmlTreeParse(webpage, useInternalNodes = TRUE, asText = TRUE)
  nodes <- getNodeSet(html, "//table")
  name <- paste("Stock",i,sep="")
  assign(name,readHTMLTable(nodes[[1]]))
}


test <- read_html("https://finance.yahoo.com/quote/HD/history?p=HD")
tables <- html_nodes(test, css = "table")
UNH <- html_table(tables)[[1]]
UNH

test <- read_html("https://finance.yahoo.com/quote/HD/history?p=HD")
nodes <- html_nodes(test, xpath = '//*[@id="Col1-1-HistoricalDataTable-Proxy"]/section/div[2]/table')
UNH3 <- html_table(nodes)[[1]]
