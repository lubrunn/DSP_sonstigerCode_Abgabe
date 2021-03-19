


download.file("https://covid.ourworldindata.org/data/owid-covid-data.csv","/home/kai-moritzbrehm/share/TriggerTest/owid.csv")
owid <- read.csv("/home/kai-moritzbrehm/share/TriggerTest/owid.csv")
owid <- owid %>% filter(iso_code == "DEU" | iso_code == "USA")
owid <- owid %>% subset(select=c("location","date","total_cases","new_cases","total_deaths","new_deaths","total_cases_per_million",
                                 "new_cases_per_million","total_deaths_per_million","new_deaths_per_million","reproduction_rate",
                                 "icu_patients","icu_patients_per_million","hosp_patients","hosp_patients_per_million",
                                 "weekly_icu_admissions","weekly_icu_admissions_per_million","weekly_hosp_admissions",
                                 "weekly_hosp_admissions_per_million","new_tests","total_tests","total_tests_per_thousand",
                                 "new_tests_per_thousand","positive_rate","tests_per_case","total_vaccinations","people_vaccinated",
                                 "people_fully_vaccinated","new_vaccinations","total_vaccinations_per_hundred","people_vaccinated_per_hundred",
                                 "people_fully_vaccinated_per_hundred"))
owid$date <- as.Date(owid$date)
write.csv(owid,"/home/kai-moritzbrehm/share/Lukas_TRUE/Data/Corona/owid.csv")




### trigger script: https://stevenmortimer.com/automating-r-scripts-with-cron/