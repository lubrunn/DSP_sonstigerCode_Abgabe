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

'
In this file we append all coordinates files and upload them to sql


'
########################### for no filter



source_main <- "coords/joined"

folder <- "En_NoFilter"

files <- list.files(file.path(source_main, folder))




### load all files
df_all <- NULL
for (file in files){
df <- readr::read_csv(file.path(source_main, folder, file),
                   col_types = cols("doc_id" = "c"))

if (is.null(df_all)){
  df_all <- df
} else {
  df_all <- dplyr::bind_rows(df_all, df)
}
}


#df <- data.frame(df)

#### add identifier column for sql
df_all$company <- folder

#### connect to sql
con <- DBI::dbConnect(RSQLite::SQLite(), "C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases/clean_database.db")

# upload
RSQLite::dbWriteTable(
  con,
  "coords",
  df_all,
  append = T
)


# disconnect
DBI::dbDisconnect(con)





###################### for companies


source_main <- "coords/joined"

folder <- "Companies"

subfolders <- list.files(file.path(source_main, folder))


##### find last update
con <- DBI::dbConnect(RSQLite::SQLite(), "C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases/clean_database.db")
time1 <- Sys.time()
comp_have <- DBI::dbGetQuery(con, "select distinct(company) from coords")


### compaies still needed
subfolders_need <- subfolders[!subfolders %in% comp_have$company]




for (subfolder in subfolders_need){
  files <- list.files(file.path(source_main, folder, subfolder))
  
  print(glue("Working on {subfolder} files"))
 
  
  
  ### load all files
  for (file in files){
    df <- readr::read_csv(file.path(source_main, folder, subfolder, file),
                          col_types = cols("doc_id" = "c"))
    
    #### add company name as column (first replace umlaute)
    company <- gsub("ü", "ue", subfolder)
    company <- gsub("ö", "oe", company)
    
    df$company <- company
    
    #con <- DBI::dbConnect(RSQLite::SQLite(), "C:/Users/lukas/OneDrive - UT Cloud/Data/SQLiteStudio/databases/clean_database.db")
    
    # upload
    RSQLite::dbWriteTable(
      con,
      glue("coords"),
      df,
      append = T
    )
    
  }
  
  
  
}
# disconnect
DBI::dbDisconnect(con)
