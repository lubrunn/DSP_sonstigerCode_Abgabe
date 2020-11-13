if (!require("rvest")) install.packages("rvest")
if (!require("xml2")) install.packages("xml2")
if (!require("XML")) install.packages("XML")
if (!require("anytime")) install.packages("anytime")

library("rvest")
library("xml2")
library("anytime")
library("XML")

testit <- function(x)
{
  p1 <- proc.time()
  Sys.sleep(x)
  proc.time() - p1
}

#indices <- c("DJI","GDAXI","GSPTSE","IBEX","SSMI","AXAT","J141.JO","JNOU.JO","BVSP","ISEQ","ATX","STI%3FP%3D%5ESTI",
#             "NSEI","FCHI","OMX","000001.SS","IMOEX.ME","TA125.TA","MERV","N225","HSI","KS11","TWII","MXX")

#nur wo components und historical data verfügbar ist:
indices <- c("DJI","GDAXI","IBEX","SSMI","AXAT","BVSP","ISEQ","ATX","STI%3FP%3D%5ESTI",
             "NSEI","FCHI","OMX","MERV","HSI","MXX")




lastdate <- as.Date("2020-01-01")
help <- rev(seq(lastdate,Sys.Date(), by = "days"))
dates <- as.numeric(as.POSIXct(c(help[seq(1,length(help),135)],lastdate)))

#https://au.finance.yahoo.com/quote/%5EGDAXI/history?period1=1577836800&period2=1605225600&interval=1d&filter=history&frequency=1d&includeAdjustedClose=true
for (i in indices) {
  print(glue("Started fetching data for {i}"))
  datalist <- list()
  for (j in 1:(length(dates) - 1)) {
    url <- paste("https://au.finance.yahoo.com/quote/%5E",i,"/history?period1=",dates[j + 1],"&period2=", dates[j],"&interval=1d&filter=history&frequency=1d&includeAdjustedClose=true",sep = "")
    webpage <- readLines(url)
    html <- htmlTreeParse(webpage, useInternalNodes = TRUE, asText = TRUE)
    nodes <- getNodeSet(html, "//table")
    datalist[[j]] <- readHTMLTable(nodes[[1]])
    testit(2)
  }
  name <- paste(i,"-Index",sep = "")
  assign(name,do.call(rbind,datalist))
  testit(1)
  print(glue("Finished fetching data for {i}, waiting 2 seconds for next index."))
}







