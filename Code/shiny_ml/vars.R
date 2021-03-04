library(tidyverse)

filename <- "https://unitc-my.sharepoint.com/:x:/g/personal/zxmvp94_s-cloud_uni-tuebingen_de/EZMnSOrMHqZPoYT5PgFiQkkBLdU6rTC8qYnoAdWKMjprrg?download=1"
sentiment <- read.csv(filename)

controls <- read.csv("https://unitc-my.sharepoint.com/:x:/g/personal/zxmvp94_s-cloud_uni-tuebingen_de/EdK7M0hgGDpAk_jOPLz-72ABDcQSPSuF32uTQFzyvsALCw?download=1")

stock <- read.csv("https://unitc-my.sharepoint.com/:x:/g/personal/zxmvp94_s-cloud_uni-tuebingen_de/EVMgYnBudQRAuaP9o6klvBsBUATwb3GY1WBks-nh3pYXrA?download=1")

names(controls)[1] <- "date"


covariates <- inner_join(controls,sentiment)

covariates <- covariates %>% select(date,VIX,coronavirus,WLEMUINDXD,sentiment_mean)

stock$Date <- as.Date(stock$Date, "%d %b %Y")


stock <- missing_date_imputer(stock,"Close.")

names(stock)[1] <- "date"
covariates$date <- as.Date(covariates$date)
stock$date <- as.Date(stock$date)
covariates <- semi_join(covariates,stock)


##########VAR

#ADF
series <- cbind(covariates,stock)

series[,6] <- NULL

apply(series[,-1], 2, adf.test)


ts_series = ts(series,
               frequency = 365,
               start = c(2020, as.numeric(format(series$date[1], "%j"))))

diff_series <- diffM(series[-1])
apply(diff_series, 2, adf.test)

plot.ts(diff_series)

var.a <- vars::VAR(diff_series,
                   lag.max = 15, #highest lag order for lag length selection according to the choosen ic
                   ic = "AIC", #information criterion
                   type = "none") #type of deterministic regressors to include


serial.test(var.a)


fcast = predict(var.a, n.ahead = 5) # we forecast over a short horizon because beyond short horizon prediction becomes unreliable or uniform

Stock_pre = fcast[["fcst"]][["Close."]]


x = Stock$Close.[,1]; x

tail(series)

x = cumsum(x) + 31458.40

Stockinv =ts(c(ts_series[,6], x),
             start = c(2020,2),
             frequency = 365)



###ARIMAX
# https://www.datascienceblog.net/post/machine-learning/forecasting-an-introduction/


plot(decompose(stock))

acf(stock)
acf(stock, type = "partial")

train <- 1:350

test <- 351:408

test.matrix = as.matrix(covariates[train, c("VIX", "coronavirus","sentiment_weight_retweet")])
test.matrix = as.matrix(covariates[c("VIX","coronavirus","sentiment_weight_retweet")])

A <- Arima(stock$Close.,
           xreg = test.matrix,
           order = c(1,0,0))

preds <- forecast(A, xreg = test.matrix)
plot(preds)


#
# plot(stock)
# stock.components <- decompose(stock)
# #stationarity
# #AR parameter -> PACF
# acfp <- acf(stock, main = "pACF", plot = FALSE)
# acfp$lag <- acfp$lag * 12
# plot(acfp, main = "ACF")
# #MA parameter -> ACF
# acfpl <- acf(stock, main = "pACF", type = "partial", plot = FALSE)
# acfpl$lag <- acfpl$lag * 12
# plot(acfpl, main = "pACF")
# arimax(stock$Close., order = c(1,1,0),xtransf = covariates,xreg=covariates,
#        method = c("ML"))
# #MAPE
#test residuals
#statistical test

