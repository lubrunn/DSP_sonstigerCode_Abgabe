devtools::install_github("PMassicotte/gtrendsR")
library(gtrendsR)
library(ggplot2)
library(devtools)

keywords= c("Covid")

country=c('DE','US')

times =("2018-11-30 2021-02-20")

channel='web'


trends = gtrends(keyword = 'coronavirus', 
                 time = times, 
                 geo = 'DE',
                 gprop ="web")


time_trend=trends$interest_over_time
#calcualte sm

write.csv(time_trend,"C:/Users/simon/OneDrive - UT Cloud/Eigene Dateien/Data/Twitter/sentiment/Model/gTrend_Covid.csv",row.names = F)



plot <- ggplot(data=time_trend, aes(x=date, y=hits,group=keyword,col=keyword))+
        geom_line()+xlab('Time')+ylab('Relative Interest')+ theme_bw()+
        theme(legend.title = element_blank(),
              legend.position="bottom",
              legend.text=element_text(size=12))+
        ggtitle("Google Search Volume")

plot
