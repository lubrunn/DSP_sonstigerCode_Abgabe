library(glue)
library(tidyverse)
library(dplyr)
library(imputeTS)
library(PerformanceAnalytics)
library(ggplot2)
library(openxlsx)
library(XML)
library(magrittr)
library(httr)
library(rvest)
library(stringr)
library(tm)
library(xml2)
library(anytime)
library(anytime)
library(lubridate)



source("/home/kai-moritzbrehm/share/yahoo_update.R") # <- put in path to the function on your pc

#execute function for selected countries
countries <- c("Germany","USA")

for(i in countries) {

  get_Yahoo_update(i)

}

source("/home/kai-moritzbrehm/share/Corona.R")
source("/home/kai-moritzbrehm/share/Full_alle_einzelnen_appenden.R")
source("/home/kai-moritzbrehm/share/VIX.R")
