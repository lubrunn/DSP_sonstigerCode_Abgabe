library(timetk)
library(xts)
library(tidyquant)
library(zoo)
library(ggplot2)
library(ggfortify)
library(forecast)
library(caret)
library(dygraphs)
#notes:
#scaling, hypeparameter tuning
#preprocessing in shiny -> find good amount of ARs and MAs
# corona dummy
#########################################
#shiny structure
#ggAcf, ggPacf
#dynamic variables
  #split train test (in percent):
split <- 0.7
  # lag AR process
lag <- 2
  # wanted variables for AR process
variable <- "Close."
  # moving average window
avg_len = 5
# drop down with post training analytics (feature importance,residual plot
#                                        + automatic test, )
  #forecast window
length_forecast <- 5

########################################
split_data <- function(sample,split){

    sample <- sample %>%
      dplyr::mutate(.,
                    months = lubridate::month(date),
                    years = lubridate::year(date),
                    weeks = lubridate::week(date),
                    days = lubridate::day(date))

    n_sample <- round(nrow(sample)*split)
    split.at = sample[n_sample,"date"]
    split = which(sample$date<split.at)

    out$df.train = sample[split,] # Predictor training data set
    out$y.train = sample[split,c(2)] # Outcome for training data set
    out$date.train = sample[split,c(1)] # Date, not a predictor but useful for plotting

    out$df.test  = sample[-split,] # Predictors for testing/evaluation data set
    out$y.test = sample[-split,c(2)] # Outcome for testing data set
    out$date.test = sample[-split,c(1)] # date for test data set

    return(out)
}

#do it after loading covariates and stocks
preprocess.df.train = preProcess(df.train, method=c("scale","center","BoxCox"))
df.train = predict(preprocess.df.train, newdata = df.train)
df.test = predict(preprocess.df.train,newdata = df.test)

#https://stackoverflow.com/questions/57924064/r-descale-data-back-to-their-original-values

#####do it for df.train
#create AR features
# only from wanted ts
AR_creator <- function(df,variable,lag){

  xts_object <- df %>%
    tk_xts(silent = TRUE)

  xts_object <-
    merge.xts(xts_object, lag.xts(xts_object[,variable], k = 1:lag))

  df <- xts_object %>%
                    tk_tbl()

  df = df[,-c(1)]

  return(df)
}

df.train <- AR_creator(df.train,variable,lag)
df.test <- AR_creator(df.test,variable,lag)




#create MA features
#only for wanted TS
MA_creator <- function(df,variable,avg_len){

x <- zoo(df[,"Close."])

df <- df %>%
  dplyr::mutate(MA = as.data.frame(zoo::rollmean(x, k = avg_len, fill = NA))) %>%
  dplyr::ungroup()

return(df)

}

df.train <- MA_creator(df.train,variable,avg_len)
df.test <- MA_creator(df.test,variable,avg_len)



train_xgboost <- function(df.train,df.test){

outcome_col <- 1

data_train <- xgboost::xgb.DMatrix(data = as.matrix(df.train[-(outcome_col),
                                                             drop = FALSE]),
                                   label = as.matrix(df.train[outcome_col,
                                                              drop = FALSE]))

data_test <- xgboost::xgb.DMatrix(data = as.matrix(df.test[-(outcome_col),
                                                           drop = FALSE]),
                                  label = as.matrix(df.test[outcome_col,
                                                            drop = FALSE]))

watchlist <- list(train = data_train, test = data_test )

params <- list(objective = "reg:squarederror",
               booster = "gbtree",
               eta = 0.1,
               colsample_bytree = 0.7,
               gamma = 0.1,
               subsample = 0.7)


model <- xgboost::xgb.train(data = data_train, params = params,
                            max.depth = 6, nthread = 2, nrounds = 100,
                            eval = "rmse", verbose = 1,
                            early_stopping_rounds = 5,
                            watchlist = watchlist)

return(model)

}

model <- train_xgboost(df.train,df.test)

#plot feature importance
importance <- xgb.importance(model = model)
xgb.ggplot.importance(importance_matrix = importance[1:20])

# full ts and predicted 1. Plot
# test ts and predicted 2. Plot
#1.Plot

pred <- xgboost::xgb.DMatrix(data = as.matrix(df.test[,-c(1)]))

test_pred <- predict(model,pred)

# 1. Plot
#https://towardsdatascience.com/how-to-create-better-interactive-forecast-plots-using-r-and-dygraph-29bdd7146066
test_pred <- test_pred %>%
  zoo(seq(from = as.Date(min(date.test)), to = as.Date(max(date.test)), by = "day"))
ts <- sample %>% pull(Close.) %>%
  zoo(seq(from = as.Date(min(date.train)), to = as.Date(max(date.test)), by = "day"))

a <- {cbind(actuals=ts, predicted=test_pred)} %>% dygraph()

# 2. Plot
ts_test <- y.test %>%
  zoo(seq(from = as.Date(min(date.test)), to = as.Date(max(date.test)), by = "day"))

b <- {cbind(actuals=ts_test, predicted=test_pred)} %>% dygraph()


# 3. Plot
train_pred <- xgboost::xgb.DMatrix(data = as.matrix(df.train[,-c(1)]))

ts_train_fit <- predict(model,train_pred) %>%
  zoo(seq(from = as.Date(min(date.train)),to = as.Date(max(date.train)), by = "day"))

ts_train <- y.train %>%
  zoo(seq(from = as.Date(min(date.train)), to = as.Date(max(date.train)), by = "day"))


c <- {cbind(fitted=ts_train_fit, actual_train=ts_train,actual_test=ts_test,
            predicted=test_pred)} %>% dygraph()

# RMSE , MAPE #white noise test

rmse <-  sqrt(mean((test_pred - df.test$Close.)^2))

mape <- mean(abs((df.test$Close.- test_pred)/df.test$Close.) * 100)

# check mean 0 and correlation
residuals = as.numeric(ts_train) - as.numeric(ts_train_fit)

Box.test(residuals, lag=10, fitdf=0)

ggAcf(residuals) + ggtitle("ACF of residuals")


#forecast for future
data_forecast <- function(sample,df.train,length_forecast){

  extended_data <- sample %>% dplyr::select(date,Close.) %>%
    rbind(tibble::tibble(date = seq(from = lubridate::as_date(max(sample$date))+1,
                                    by = "day", length.out = length_forecast),
                         Close. = rep(NA, length_forecast)))

  pred_forecast <- extended_data[(nrow(sample) + 1):nrow(extended_data), ] # extended time index

  df.train <- cbind(df.train,date.train)

  names(df.train)[ncol(df.train)] <- "date"

  pred_forecast <- left_join(pred_forecast,df.train[,-c(1)])
  #decompose the date
  pred_forecast <- pred_forecast %>%
    dplyr::mutate(.,
                  months = lubridate::month(date),
                  years = lubridate::year(date),
                  weeks = lubridate::week(date),
                  days = lubridate::day(date))

  pred_forecast$date <- NULL
  pred_forecast$Close. <- NULL

  return(pred_forecast)
}



pred_forecast <- xgboost::xgb.DMatrix(data = as.matrix(pred_forecast))
forecast_ts <- predict(model,pred_forecast)

# 4. Plot  forecast


forecast_ts <- forecast_ts %>%
  zoo(seq(from = as.Date(max(date.test))+1, to = as.Date(max(date.test))+length_forecast, by = "day"))

upper <- forecast_ts + 1.96*sqrt(sigma_res)
lower <- forecast_ts - 1.96*sqrt(sigma_res)
sigma_res <- sd(residuals)

# full_ts <- sample %>% dplyr::select(date,Close.) %>%
#   zoo(seq(from = as.Date(min(date.train)), to = as.Date(max(date.test)), by = "day"))


{cbind(forecast_mean=forecast_ts,
       lower_95=lower, upper_95=upper)} %>%
  dygraph() %>%
  dySeries(c("lower_95", "forecast_mean", "upper_95"),
           label = "95%", color = "blue")






###############Hyperparameter tuning
library(rsample)
library(recipes)
library(parsnip)
library(tune)
library(dials)
library(workflows)
library(yardstick)
library(janitor)
sample_t <- sample %>% select(-date)

ames_split <- rsample::initial_split(
  sample_t,
  prop = 0.7,
  strata = Close.
)

preprocessing_recipe <-
  recipes::recipe(Close. ~ ., data = training(ames_split)) %>% prep()

ames_cv_folds <-
  recipes::bake(
    preprocessing_recipe,
    new_data = training(ames_split)
  ) %>%
  rsample::vfold_cv(v = 2)

xgboost_model <-
  parsnip::boost_tree(
    mode = "regression",
    trees = 100,
    min_n = tune(),
    tree_depth = tune(),
    learn_rate = tune(),
    loss_reduction = tune()
  ) %>%
  set_engine("xgboost", objective = "reg:squarederror")

xgboost_params <-
  dials::parameters(
    min_n(),
    tree_depth(),
    learn_rate(),
    loss_reduction()
  )

xgboost_grid <-
  dials::grid_max_entropy(
    xgboost_params,
    size = 30
  )


xgboost_wf <-
  workflows::workflow() %>%
  add_model(xgboost_model) %>%
  add_formula(Close. ~ .)

xgboost_tuned <- tune::tune_grid(
  object = xgboost_wf,
  resamples = ames_cv_folds,
  grid = xgboost_grid,
  metrics = yardstick::metric_set(yardstick::rmse, yardstick::mae),
  control = tune::control_grid(verbose = TRUE)
)

xgboost_tuned %>%
  tune::show_best(metric = "rmse") %>%
  knitr::kable()

xgboost_best_params <- xgboost_tuned %>%
  tune::select_best("rmse")
knitr::kable(xgboost_best_params)

xgboost_model_final <- xgboost_model %>%
  finalize_model(xgboost_best_params)



test_processed  <- bake(preprocessing_recipe, new_data = testing(ames_split))
train_processed <- bake(preprocessing_recipe,  new_data = training(ames_split))

test_prediction <- xgboost_model_final %>%
  # fit the model on all the training data
  fit(
    formula = Close. ~ .,
    data    = train_processed
  ) %>%
  # use the training model fit to predict the test data
  predict(new_data = test_processed) %>%
  bind_cols(testing(ames_split))

# measure the accuracy of our model using `yardstick`

test_prediction$Close. <- as.numeric(test_prediction$Close.)

xgboost_score <-
  test_prediction %>%
  yardstick::metrics(Close., .pred) %>%
  mutate(.estimate = format(round(.estimate, 2), big.mark = ","))

knitr::kable(xgboost_score)

house_prediction_residual <- test_prediction %>%
  arrange(.pred) %>%
  mutate(residual_pct = (Close. - .pred)) %>%
  select(.pred, residual_pct)

ggplot(house_prediction_residual, aes(x = .pred, y = residual_pct)) +
  geom_point() +
  xlab("Predicted Sale Price") +
  ylab("Residual")



Box.test(house_prediction_residual$residual_pct, lag=10, fitdf=0)

ggAcf(house_prediction_residual) + ggtitle("ACF of residuals")



a <- xgboost_model_final %>%
  # fit the model on all the training data
  fit(
    formula = Close. ~ .,
    data    = train_processed
  ) %>%
  # use the training model fit to predict the test data
  predict(new_data = pred_forecast)


names(pred_forecast)

pred_forecast$Close..2 <- NULL

pred_forecast$Close..1 <- NULL

pred_forecast$date.1 <- NULL

pred_forecast$MA <- NULL




#what is the test data set in time series?



#Expanding (recursive) versus rolling forecast
#https://rpubs.com/mattBrown88/TimeSeriesMachineLearning

