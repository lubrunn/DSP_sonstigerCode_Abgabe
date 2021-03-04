library(forecastML)
library(dplyr)
library(DT)
library(ggplot2)
library(xgboost)


data("data_buoy_gaps", package = "forecastML")

extended_data <- sample %>%
  dplyr::mutate(.,
                months = lubridate::month(date),
                years = lubridate::year(date),
                days = lubridate::day(date))


extended_data$date <- NULL

outcome_col <- 1
horizons <- c(1, 7)  # Forecast 1, 1:7, and 1:30 days into the future.
lookback <-  c(1:15)  # Features from 1 to 30 days in the past and annually.

dates <- sample$date  # Grouped time series forecasting requires dates.

frequency <- "1 day"

names(extended_data)
dynamic_features <- c("VIX", "coronavirus","WLEMUINDXD","sentiment_mean",
                      "months","years","days")
type <- "train"


data_train <- forecastML::create_lagged_df(extended_data, type = type, outcome_col = outcome_col,
                                           horizons = horizons, lookback = lookback,
                                           dates = dates, frequency = frequency,
                                           dynamic_features = dynamic_features,
                                           use_future = FALSE)

windows <- forecastML::create_windows(data_train, window_length = 50,skip=100)

p <- plot(windows, data_train) + theme(legend.position = "none")
p


# The value of outcome_col can also be set in train_model() with train_model(outcome_col = 1).
model_function <- function(data, outcome_col = 1) {

  # xgboost cannot handle missing outcomes data.
  data <- data[!is.na(data[, outcome_col]), ]

  indices <- 1:nrow(data)

  set.seed(224)
  train_indices <- sample(1:nrow(data), ceiling(nrow(data) * .8), replace = FALSE)
  test_indices <- indices[!(indices %in% train_indices)]

  data_train <- xgboost::xgb.DMatrix(data = as.matrix(data[train_indices,
                                                           -(outcome_col), drop = FALSE]),
                                     label = as.matrix(data[train_indices,
                                                            outcome_col, drop = FALSE]))

  data_test <- xgboost::xgb.DMatrix(data = as.matrix(data[test_indices,
                                                          -(outcome_col), drop = FALSE]),
                                    label = as.matrix(data[test_indices,
                                                           outcome_col, drop = FALSE]))

  params <- list("objective" = "reg:linear")
  watchlist <- list(train = data_train, test = data_test)

  set.seed(224)
  model <- xgboost::xgb.train(data = data_train, params = params,
                              max.depth = 8, nthread = 2, nrounds = 30,
                              metrics = "rmse", verbose = 0,
                              early_stopping_rounds = 5,
                              watchlist = watchlist)

  return(model)
}


model_results_cv <- forecastML::train_model(lagged_df = data_train,
                                            windows = windows,
                                            model_name = "xgboost",
                                            model_function = model_function,
                                            use_future = FALSE)



summary(model_results_cv$horizon_1$window_1$model)


prediction_function <- function(model, data_features) {
  x <- xgboost::xgb.DMatrix(data = as.matrix(data_features))
  data_pred <- data.frame("y_pred" = predict(model, x),
                          "y_pred_lower" = predict(model, x) - 2,  # Optional; in practice, forecast bounds are not hard coded.
                          "y_pred_upper" = predict(model, x) + 2)  # Optional; in practice, forecast bounds are not hard coded.
  return(data_pred)
}

data_pred_cv <- predict(model_results_cv, prediction_function = list(prediction_function), data = data_train)


plot(data_pred_cv) + theme(legend.position = "none")


plot(data_pred_cv, facet = group ~ model, windows = 1)

data_error <- forecastML::return_error(data_pred_cv)



