library(readr)
library(corpus)
setwd(r"(C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\raw_csv\En_NoFilter)")
df <- readr::read_csv("En_NoFilter_2018-11-30.csv",
                      col_types = cols(.default = "c", lat = "d", long = "d",
                                       retweets_count = "i", replies_count = "i",
                                       likes_count = "i", tweet_length = "i"))


stem_hunspell <- function(term) {
  # look up the term in the dictionary
  stems <- hunspell::hunspell_stem(term)[[1]]
  
  if (length(stems) == 0) { # if there are no stems, use the original term
    stem <- term
  } else { # if there are multiple stems, use the last one
    stem <- stems[[length(stems)]]
  }
  
  stem
}


time1 <- Sys.time()
stem1 <- text_tokens(df$tweet, stemmer = stem_hunspell)
print(Sys.time() - time1)

time1 <- Sys.time()
df$tweet_stem2 <- text_tokens(df$tweet, stemmer = "en")
print(Sys.time() - time1)





##################################
# download the list
url <- "http://www.lexiconista.com/Datasets/lemmatization-en.zip"
tmp <- tempfile()
download.file(url, tmp)

# extract the contents
con <- unz(tmp, "lemmatization-en.txt", encoding = "UTF-8")
tab <- read.delim(con, header=FALSE, stringsAsFactors = FALSE)
names(tab) <- c("stem", "term")




