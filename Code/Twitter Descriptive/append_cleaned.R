soure("append.R")



# which folders should be appended
source_main <- "cleaned"

# list all folders in source main
folders <- list.files(source_main)

folders <- folders[5]

# start function
append_all(source_main, folders)



dest <- "appended"
lang = "En"


final_appender(source_main,dest = "appended", "En")