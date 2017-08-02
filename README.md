Nexis UK scraper
================

This is a package to automatically search and download news articles from the Nexis UK databse. This package is developed to promote large scale analysis in media and communications reserach to investiate problems in mass communication in the rapidly changing world.

Nexis only offers [its API](https://www.lexisnexis.com/webserviceskit/) for high extra fees, preveting the academics from accessing the data. Until the company decide to provide academic users with an API for no or reasonable costs, scraping is the only way for the academics to embark on large scale analysis of news content.

This package provides automated access to the Nexis database through a web browser. Web browsersing is manipulated using [**Selenium**](http://www.seleniumhq.org/) to search and download news articles without human attendance. Depending on the Nexis server response time, this scraper can download around 30,000 news atriles per hour to your laptop or desktop machine.

Target database
---------------

Nexis has different interfaces for the news database. This scraper is designed for [Nexis UK](https://github.com/koheiw/Nexis/blob/master/img/screenshot.png) which is used in the UK and Irish universities. For other interfaces, functions in this package needs to be modified.

Supported browser
-----------------

Currently, this package only supports scraping by **Firefox** is supported, but it is realtely easy to add **Chrome**.

Future updates
--------------

Web scraping is not an reliable technology as it depends on the HTML tags in the web pages that are frequently updated. This scraper also has to be updated to keep up with the changes in Nexis database. If this package suddenly stops working, try the latest version of this package. If it still do not work, file an issue in this repository, or writre a patch and submit a pull request.

**RSelenium**

Setup
-----

### Download and install packages and libraries

``` r
devtools::install_github('koheiw/Nexis/')
```

### Execute Selenium server

    java -jar selenium-server-standalone-3.4.0.jar

Setting
-------

<https://www.lexisnexis.com/start/shib/wayf>

``` r
require('Nexis')

#login_url <- 'http://www.lse.ac.uk/library'
login_url <- 'https://www.lexisnexis.com/start/shib/idpurlrd?entityID=https%3A%2F%2Flse.ac.uk%2Fidp&requestUrl=https://www.lexisnexis.com/start/shib/oaAuth?RelayState=fedId=3;appToken=AAA556656083ACCF9BB3B0BEC6FDBB3A'

dir <- '/home/kohei/Documents/Nexis'
query <- "japan"
from <- '2017-01-01'
to <- '2017-12-31'
size <- 1
unit <- 'month'
```

Download
--------

### Step 1: open Nexis in browser

``` r
set_directory(dir)
open_browser(login_url)
find_window()
```

### Step 2: execute the scraper

``` r
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