The Nexis scraper
=================

This is a package to automatically search and download news articles from the Nexis database. This package is developed to promote large scale analysis in media and communications research to investigate problems in mass communication in the rapidly changing world.

LexisNexis demands high extra fees to access to the Nexis [API](https://www.lexisnexis.com/webserviceskit/), preventing the academics from accessing the data. Until the company decide to provide academic users with an API for no or reasonable extra costs, scraping is the only way for the academics to embark on large scale analysis of news content.

This package provides automated access to the Nexis database through a web browser. Web browsing is manipulated using [**Selenium**](http://www.seleniumhq.org/) to search and download news articles without human attendance. Depending on the Nexis server response time, this scraper can download around 30,000 news articles per hour to your laptop or desktop machine.

Target database
---------------

The Nexis database has different interfaces for users in different countries. This scraper is designed for [Nexis UK](https://github.com/koheiw/Nexis/blob/master/img/screenshot.png), which is used in the UK and Irish universities. For other Nexis databases for other countries, functions in this package needs to be modified.

Supported browser
-----------------

Currently, this package only supports scraping by **Firefox** is supported, but it is relatively easy to add **Chrome**.

Future updates
--------------

Web scraping is not an reliable technology as it depends on the HTML tags in web pages that are frequently updated. This scraper has to be maintained to keep up with the changes in Nexis database. If this package suddenly stops working, try the latest version available in this repository. If it does not fix the problem, file an issue or writer a patch and submit a pull request.

How to use
==========

Setup
-----

### Install programs

**R** and **Java Runtime Enviromnet** have to be installed to use this package. JRE is required to run the Selenium server.

-   R (&gt;= 3.2.2)
-   [Java Runtime Environment 8](http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html) (9 has problem with Selenium Server)

### Start Selenium server

You have to run the Selenium sever *before* using this package. Selenium Server is available at [SeleniumHQ](http://www.seleniumhq.org/download/). This repository contains the Selenium Standalone Sever (selenium-server-standalone-3.4.0.jar) and a web driver for Firefox (**geckodriver**) in [bin directory](https://github.com/koheiw/Nexis/tree/master/bin) to download.

To run Selenium Standalone Sever, you only need to type the following command in the console:

    java -jar selenium-server-standalone-3.4.0.jar

Sometimes, you have to tell **Selenium** the location of **geckodriver** (in the same directory, in this example):

    java -jar -Dwebdriver.gecko.driver=geckodriver selenium-server-standalone-3.4.0.jar

You can stop the Selenium sever by pressing `Ctrol + C`.

Run Nexis Scraper
-----------------

Since this package is in a private repository, you cannot use `devtools::install_github('koheiw/Nexis')`. You have to either clone the repository and build or download in a zip file and install:

``` r
devtools::install("/home/kohei/Downloads/Nexis-master/") # unzipped folder
require('Nexis')
```

File location
-------------

You first have to set a directory where downloaded files are saved:

``` r
set_directory('/home/kohei/Documents/Nexis')
```

Login to database
-----------------

You have to login to the Nexis database using your library account in the browser windows opened up by `open_browser()`. You can manually navigate to the database from the library website, or can directly access from <https://www.nexis.com> using *Academic Sign-in*.

``` r
url_login <- 'https://www.lexisnexis.com/start/shib/idpurlrd?entityID=https%3A%2F%2Flse.ac.uk%2Fidp&requestUrl=https://www.lexisnexis.com/start/shib/oaAuth?RelayState=fedId=3;appToken=AAA556656083ACCF9BB3B0BEC6FDBB3A'

# or 

#url_login <- 'http://www.lse.ac.uk/library'

open_browser(url_login) # a new browser window will open
```

Download setting
----------------

Before starting download, you have to search query, download period, and size of search window. With the following setting, the scraper will download news articles that contain "Brexit" between 1 January 2016 and 31 December 2016 separately for each month.

``` r
query <- "Brexit"
from <- '2016-01-01'
to <- '2016-12-31'
size <- 1
unit <- 'month'
```

Start download
--------------

Finally, start automated download:

``` r
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
