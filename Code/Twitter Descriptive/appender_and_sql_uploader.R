library(vroom)
library(glue)

################################################################################
### this is simply for easier switching between vpcl and local
vpc = FALSE

# read in data
if (vpc == T) {
  setwd("/home/lukasbrunner/share/onedrive_new/Data/Twitter")
} else {
  setwd("C:/Users/lukas/OneDrive - UT Cloud/Data/Twitter")
}

################################################################################


########################### for no filter



source_main <- "plot_data"

folder <- "En_NoFilter"

files <- list.files(file.path(source_main, folder))

## all relevant sumstats files
files_sum_stats <- files[grepl("sum_stats", files)]


### load all files
df <- vroom::vroom(file.path(source_main, folder, files_sum_stats), delim = ",")

df <- data.frame(df)

con <- DBI::dbConnect(RSQLite::SQLite(), "C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases/clean_database.db")

# upload
RSQLite::dbWriteTable(
  con,
  "sum_stats_en",
  df,
  append = T
)


# disconnect
DBI::dbDisconnect(con)





###################### for companies


source_main <- "plot_data"

folder <- "Companies"

subfolders <- list.files(file.path(source_main, folder))


##### find last update
con <- DBI::dbConnect(RSQLite::SQLite(), "C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases/clean_database.db")
time1 <- Sys.time()
comp_have <- DBI::dbGetQuery(con, "select distinct(company) from sum_stats_companies")


### compaies still needed
subfolders_need <- subfolders[!subfolders %in% comp_have$company]


subfolder <- subfolders_need[1]

for (subfolder in subfolders){
  files <- list.files(file.path(source_main, folder, subfolder))
  
  print(glue("Working on {subfolder} files"))
  ## all relevant sumstats files
  files_sum_stats <- files[grepl("sum_stats", files)]
  
  
  ### load all files
  for (file in files_sum_stats){
  df <- data.table::fread(file.path(source_main, folder, subfolder, file))
  
  # convert to df
  df <- data.frame(df)
  
  #con <- DBI::dbConnect(RSQLite::SQLite(), "C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases/clean_database.db")
  print("Uploading to SQL")
  # upload
  RSQLite::dbWriteTable(
    con,
    glue("sum_stats_companies"),
    df,
    append = T
  )
  
  }
  
  
  
}
# disconnect
DBI::dbDisconnect(con)
