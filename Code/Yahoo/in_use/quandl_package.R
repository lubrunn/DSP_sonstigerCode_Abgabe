library("Quandl")

#2_YEaGn7ZdJq7g4WN1Ag

Quandl.api_key("2_YEaGn7ZdJq7g4WN1Ag")


#Ted-Spread
ted_spread = Quandl("FRED/TEDRATE")


#cpi
cpi_usa <- Quandl("RATEINF/CPI_USA ")

cpi_deu <-  Quandl("RATEINF/CPI_DEU")

NQEU <- Quandl("NASDAQOMX/NQEUEUR")

#Construction - TOTAL construction as a whole - Germany (Quarterly, NSA)
#ECBCS/CST_TOT_QU_DE

#Consumers - TOTAL Consumer - Germany (Quarterly, NSA)
#ECBCS/CON_TOT_QU_DE