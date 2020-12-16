df = read.csv(r"(C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\Berlin\Berlin_2019-11-30.csv)")


library(tidyverse)
a <- filter(df, place != "")
b <- a$place
b[1]
matches <- as.numeric(unlist(regmatches(b,
                                        gregexpr("[[:digit:]]+\\.*[[:digit:]]*",b))
)      )
k = 1

for (i in 1:nrow(a)){
  
  a[i,"lat"] = matches[k]
  a[i, "long"] = matches[k + 1]
  k = k + 2
}


library(grid)
library(rworldmap)


worldMap <- getMap()

# Member States of the European Union
europeanUnion <- "Germany"
# Select only the index of states member of the E.U.
indEU <- which(worldMap$NAME%in%europeanUnion)


europeCoords <- lapply(indEU, function(i){
  df <- data.frame(worldMap@polygons[[i]]@Polygons[[1]]@coords)
  df$region =as.character(worldMap$NAME[i])
  colnames(df) <- list("long", "lat", "region")
  return(df)
})

europeCoords <- do.call("rbind", europeCoords)

ggplot() + geom_polygon(data = europeCoords, aes(long, lat), fill = "grey")+
  geom_point(data = a, aes(a$long, a$lat))





