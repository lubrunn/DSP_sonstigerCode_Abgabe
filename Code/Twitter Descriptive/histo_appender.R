
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



source_main <- "plot_data"

folders_main <- list.files(source_main)[!grepl("appended", list.files(source_main))]

metrics <- c("rt", "likes", "senti", "Long")

likes_list <- c(0, 10, 50, 100, 200)
retweets_list <- c(0, 10, 50, 100, 200)
long_list <- c(0,81)

#### process for nofilter folders
for (folder in folders_main){
  folders_sub <- list.files(file.path(source_main, folder))
  
  #for (subfolder in folders_sub[!grepl("appended", folders_sub)])
    
    # list all files
    files <- list.files(file.path(source_main, folder))
  
  for (retweets_filter in retweets_list){
    for(likes_filter in likes_list){
      for(length_filter in long_list){
        # check which name to five file
        if (length_filter == 81){
          long_name <- "long_only"
        } else{
          long_name <- "all"
        }
        
        for (metric in metrics){
          add_on <- glue("{metric}_{folder}_rt_{retweets_filter}_li_{likes_filter}_lo_{long_name}")
          # check all files that have this addon
          selected_files <-  files[grepl(add_on, files)] 
          
          # read all files and append
          df_all <- NULL
          for (selected_file in selected_files){
          df <- readr::read_csv(file.path(source_main, folder, selected_file))
          if (is.null(df_all)){
            df_all <- df
          } else {
            df_all <- bind_rows(df_all,df)
          }
          }
          
          new_filename <- glue("histo_{add_on}.csv")
          dest <- file.path(source_main,folder, "appended", new_filename)
          
          vroom_write(df, dest, delim =",")
          
        
        }
        
      }
    }
  }
}

df_all <- data.table:: fread(dest)
df_all %>%
  # filter(likes_count < 10000
  #         # likes_count > 0
  #        ) %>%
  
  
  group_by(likes_count) %>% summarise(n = sum(N)) %>%
  
  
  mutate(log_metric = log(likes_count + 0.0001),
         bins = cut_interval(log_metric, n = 100)) %>%
  ggplot(aes(bins, n)) +
  geom_col() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  geom_density()




# read file and create histogram




