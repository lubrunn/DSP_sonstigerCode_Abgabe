


Sys.setlocale("LC_TIME", "English")



df_index <- read.csv(paste0("/home/kai-moritzbrehm/share/Lukas_TRUE/Data/Yahoo/",glue("Germany"),"/",glue("Germany"),"_Index_Components",".csv"))
symbol = c(df_index$Symbol[df_index$Symbol!="MTX.DE"],"GDAXI","MTX.F")
all_DE <- NULL
for (i in symbol){
  data <- read_csv(paste0("/home/kai-moritzbrehm/share/Lukas_TRUE/Data/Yahoo/",glue("Germany"),"/",glue("Germany"),"_",i,".csv"))
  colnames(data)[c(5,6)] <- c("Close","Adj.Close")
  #data[data$Volume == "-",] <- NA
  if (data$Volume[1]=="-"){
    data$Volume[1] <- data$Volume[2]
  }else{}
  help <- data[data$Volume != "-",]
  help["Volume"] <- as.numeric(gsub(",","",help$Volume))
  help["Open"] <- as.numeric(gsub(",","",help$Open))
  help["High"] <- as.numeric(gsub(",","",help$High))
  help["Low"] <- as.numeric(gsub(",","",help$Low))
  help["Close"] <- as.numeric(gsub(",","",help$Close))
  help["Adj.Close"] <- as.numeric(gsub(",","",help$'Adj.Close'))
  help <- help[complete.cases(help),]
  help$Return <- c(-diff(help$Adj.Close)/help$Adj.Close[-1], NA)
  #help[c("Open","High","Low","Close","Adj Close")] <- sapply(help[c("Open","High","Low","Close","Adj Close")],as.numeric)
  ifelse(i == "GDAXI",help$Date <- as.Date(help$Date, "%d %b %Y"),help$Date <- as.Date(help$Date, "%b %d, %Y"))
  #help["Volume"] <- as.numeric(gsub(",","",help$Volume))
  date_vector <- as.data.frame(seq(min(help$Date), max(help$Date), by="days"))
  colnames(date_vector)[1]<-"Dates"
  final <- left_join(date_vector,help,by=c("Dates"="Date"))
  # package: imputeTS , gibt noch weitere imputierm?glichkeiten
  final[1,8] <- mean(final$Return,na.rm = TRUE)
  final[c("Open","High","Low","Close","Adj.Close","Volume","Return")] <- sapply(final[c("Open","High","Low","Close","Adj.Close","Volume","Return")],na_kalman)
  final$log_Close <- log(final$Adj.Close)
  final$name <- i
  all_DE <- rbind(all_DE,final)
}



df_index_US <- read.csv(paste0("/home/kai-moritzbrehm/share/Lukas_TRUE/Data/Yahoo/",glue("USA"),"/",glue("USA"),"_Index_Components",".csv"))
symbol_US = c(df_index_US$Symbol,"DJI")
all_US <- NULL
for (i in symbol_US){
  data <- read_csv(paste0("/home/kai-moritzbrehm/share/Lukas_TRUE/Data/Yahoo/",glue("USA"),"/",glue("USA"),"_",i,".csv"))
  colnames(data)[c(5,6)] <- c("Close","Adj.Close")
  if (data$Volume[1]=="-"){
    data$Volume[1] <- data$Volume[2]
  }else{}
  help <- data[data$Volume != "-" & is.na(data$Volume) == FALSE,]
  help["Volume"] <- as.numeric(gsub(",","",help$Volume))
  help["Open"] <- as.numeric(gsub(",","",help$Open))
  help["High"] <- as.numeric(gsub(",","",help$High))
  help["Low"] <- as.numeric(gsub(",","",help$Low))
  help["Close"] <- as.numeric(gsub(",","",help$Close))
  help["Adj.Close"] <- as.numeric(gsub(",","",help$'Adj.Close'))
  help <- help[complete.cases(help),]
  help$Return <- c(-diff(help$Adj.Close)/help$Adj.Close[-1], NA)
  #help[c("Open","High","Low","Close","Adj Close")] <- sapply(help[c("Open","High","Low","Close","Adj Close")],as.numeric)
  ifelse(i == "DJI",help$Date <- as.Date(help$Date, "%d %b %Y"),help$Date <- as.Date(help$Date, "%b %d, %Y"))
  #help["Volume"] <- as.numeric(gsub(",","",help$Volume))
  if (i=="DOW"){
    date_vector <- as.data.frame(seq(as.Date("2018-11-30"), max(help$Date), by="days"))
  }else{
   date_vector <- as.data.frame(seq(min(help$Date), max(help$Date), by="days"))
  }
  colnames(date_vector)[1]<-"Dates"
  final <- left_join(date_vector,help,by=c("Dates"="Date"))
  # package: imputeTS , gibt noch weitere imputierm?glichkeiten
  final[1,8] <- mean(final$Return,na.rm = TRUE)
  final[c("Open","High","Low","Close","Adj.Close","Volume","Return")] <- sapply(final[c("Open","High","Low","Close","Adj.Close","Volume","Return")],na_kalman)
  final$log_Close <- log(final$Adj.Close)
  final$name <- i
  all_US <- rbind(all_US,final)
}


all_full <- rbind(all_US,all_DE)


write.csv(all_DE,"/home/kai-moritzbrehm/share/Lukas_TRUE/Data/Yahoo/Full/Germany_full.csv")
write.csv(all_US,"/home/kai-moritzbrehm/share/Lukas_TRUE/Data/Yahoo/Full/USA_full.csv")
write.csv(all_full,"/home/kai-moritzbrehm/share/Lukas_TRUE/Data/Yahoo/Full/all_full.csv")
