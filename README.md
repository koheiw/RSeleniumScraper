# Nexis UK scraper

This is a package to automatically search and download news articles from [Nexis UK databse]() for media reserach.



```

rm(list=ls())
source('nexis.R')

# java -jar selenium-server-standalone-3.4.0.jar

#https://www.lexisnexis.com/start/shib/wayf


#login_url <- 'http://www.lse.ac.uk/library'
login_url <- 'https://www.lexisnexis.com/start/shib/idpurlrd?entityID=https%3A%2F%2Flse.ac.uk%2Fidp&requestUrl=https://www.lexisnexis.com/start/shib/oaAuth?RelayState=fedId=3;appToken=AAA556656083ACCF9BB3B0BEC6FDBB3A'

dir_data <- "./data"
dir_temp <- "./temp"

query <- "japan"
from <- '2017-01-01'
to <- '2017-12-31'
size <- 1
unit <- 'day'

# Open browser from Selenium
open_browser()
find_window()

dates <- get_date_range(from, to, size, unit)
for (i in seq_along(dates)) {
    if (is_completed(dates[[i]])) next
    search(dates[[i]])
    if (is_zero(dates[[i]])) next
    ranges <- get_download_range(size = 500) # download 500 items each time
    for (j in seq_along(ranges)) {
        download(dates[[i]], ranges[[j]], tail(unlist(ranges), 1))
    }
}


```
