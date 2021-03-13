library(forecastML)
library(dplyr)
library(DT)
library(ggplot2)
library(xgboost)

split.at = as.Date("2020-12-16")

split = which(sample$date<split.at)

df.train = sample[split,-c(1,2)] # Predictor training data set
y.train = sample[split,c(2)] # Outcome for training data set
date.train = sample[split,c(1)] # Date, not a predictor but useful for plotting

df.test  = sample[-split,-c(1,2)] # Predictors for testing/evaluation data set
y.test = sample[-split,c(2)] # Outcome for testing data set
date.test = sample[-split,c(1)] # date for test data set


# Scaling, centering, transofrmation
preprocess.df.train = preProcess(df.train, method=c("scale","center","BoxCox"))
df.train = predict(preprocess.df.train, newdata = df.train)
df.test = predict(preprocess.df.train,newdata = df.test)


# Boosted tree (gbm)
boostGrid = expand.grid(.interaction.depth = seq(3, 9, by = 2), .n.trees = seq(100, 200, by = 100),.shrinkage = c(0.01, 0.1),.n.minobsinnode = c(10))
# Model
controlObject <- trainControl(method = "timeslice",
                              initialWindow = 20,  # First model is trained on 52 weeks (x)
                              horizon = 20, #4?!   # Validation weeks (k)
                              skip = 0,            # Skip weeks to decrease CV-folds
                              fixedWindow = FALSE, # Origin stays the same
                              allowParallel = TRUE)# Paralel computing can speed things up


data <- cbind(y.train,df.train)

M.boost = train(Close.~.,data = data,
                method = "gbm",
                tuneGrid = xgb_grid,
                verbose = FALSE,
                trControl = controlObject)




# Bagged trees (treeBag)
M.bagtree = train(Close.~.,data = data,
                  method = "treebag",
                  trControl = controlObject)


