library(lubridate)
library(tseries)
library(MTS)
library(vars)
library(lattice)
library(grid)
library(TSA)
library(imputeTS)
library(glue)
library(xgboost)
library(caret)

filename <- "https://unitc-my.sharepoint.com/:x:/g/personal/zxmvp94_s-cloud_uni-tuebingen_de/EZMnSOrMHqZPoYT5PgFiQkkBLdU6rTC8qYnoAdWKMjprrg?download=1"
sentiment <- read.csv(filename)

controls <- read.csv("https://unitc-my.sharepoint.com/:x:/g/personal/zxmvp94_s-cloud_uni-tuebingen_de/EdK7M0hgGDpAk_jOPLz-72ABDcQSPSuF32uTQFzyvsALCw?download=1")

stock <- read.csv("https://unitc-my.sharepoint.com/:x:/g/personal/zxmvp94_s-cloud_uni-tuebingen_de/EVMgYnBudQRAuaP9o6klvBsBUATwb3GY1WBks-nh3pYXrA?download=1")

names(controls)[1] <- "date"


covariates <- inner_join(controls,sentiment)

covariates <- covariates %>% dplyr::select(date,VIX,coronavirus,WLEMUINDXD,sentiment_mean)

stock$Date <- as.Date(stock$Date, "%d %b %Y")


stock <- missing_date_imputer(stock,"Close.")

names(stock)[1] <- "date"
covariates$date <- as.Date(covariates$date)
stock$date <- as.Date(stock$date)
covariates <- semi_join(covariates,stock)

#stock <- rev(stock)
#stock %>% map_df(rev)


sample <- cbind(stock,covariates)
sample[,3] <- NULL


# index values for forecast 5 days
extended_data <- sample %>%
  rbind(tibble::tibble(date = seq(from = lubridate::as_date("2021-02-13"),
                                  by = "day", length.out = 5),
                       Close. = rep(NA, 5), VIX = rep(NA, 5), coronavirus = rep(NA, 5),
                         WLEMUINDXD = rep(NA, 5) , sentiment_mean = rep(NA, 5)))

extended_data_mod <- extended_data %>%
  dplyr::mutate(.,
                months = lubridate::month(date),
                years = lubridate::year(date),
                days = lubridate::day(date) )

#could do more with seasons and stuff

train <- extended_data_mod[1:nrow(sample), ] # initial data

pred <- extended_data_mod[(nrow(sample) + 1):nrow(extended_data), ] # extended time index


#split
x_train <- xgboost::xgb.DMatrix(as.matrix(train %>%
                                            dplyr::select(months, years, days)))

x_pred <- xgboost::xgb.DMatrix(as.matrix(pred %>%
                                           dplyr::select(months, years, days)))

y_train <- train$Close.


xgb_trcontrol <- caret::trainControl(
  method = "cv",
  number = 5,
  allowParallel = TRUE,
  verboseIter = FALSE,
  returnData = FALSE
)


xgb_grid <- base::expand.grid(
  list(
    nrounds = c(100, 200),
    max_depth = c(10, 15, 20), # maximum depth of a tree
    colsample_bytree = seq(0.5), # subsample ratio of columns when construction each tree
    eta = 0.1, # learning rate
    gamma = 0, # minimum loss reduction
    min_child_weight = 1,  # minimum sum of instance weight (hessian) needed ina child
    subsample = 1 # subsample ratio of the training instances
  ))



# xgb_model <- caret::train(
#   x_train,
#   y_train,
#   trControl = xgb_trcontrol,
#   tuneGrid = xgb_grid,
#   method = "xgbTree",
#   metric = "MAPE"
# )
names(train)
train <- train %>% dplyr::select(Close.,months,years,days)

xgb_model <- caret::train(Close.~.,
  data = train,
  trControl = xgb_trcontrol,
  tuneGrid = xgb_grid,
  method = "xgbTree")

xgb_model$bestTune


pred <- pred %>% dplyr::select(months, years, days)

xgb_pred <- xgb_model %>% stats::predict(pred)

#
# xgbGrid <- expand.grid(nrounds = c(100,200),  # this is n_estimators in the python code above
#                        max_depth = c(10, 15, 20, 25),
#                        colsample_bytree = seq(0.5, 0.9, length.out = 5),
#                        ## The values below are default values in the sklearn-api.
#                        eta = 0.1,
#                        gamma=0,
#                        min_child_weight = 1,
#                        subsample = 1
# )
#


library(zoo)
fitted <- xgb_model %>%
  stats::predict(train[,-1]) %>%
  zoo(seq(from = as.Date("2020-01-02"), to = as.Date("2021-02-12"), by = "day"))

xgb_forecast <- xgb_pred %>%
  zoo(seq(from = as.Date("2021-02-13"), to = as.Date("2021-02-17"), by = "day"))

ts <- y_train %>%
  zoo(seq(from = as.Date("2020-01-02"), to = as.Date("2021-02-12"), by = "day"))

forecast_list <- list(
  model = xgb_model$modelInfo,
  method = xgb_model$method,
  mean = xgb_forecast,
  x = ts,
  fitted = fitted,
  residuals = as.numeric(ts) - as.numeric(fitted)
)

class(forecast_list) <- "forecast"



forecast::autoplot(forecast_list)


