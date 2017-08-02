require(methods)
require(RSelenium)
require(urltools)
require(XML)
require(stringi)


reset_temp_file <- function() {
    unlink(paste0(dir_temp, '/*')) # clean temp directory
}

count_elements <- function(query) {
    tryCatch({
        suppressMessages({
            elems <- driver$findElement('xpath', query)
            return(length(elems))
        })
    }, 
    error = function(e) {
        return(0)
    })
}

get_prefs <- function(browser) {
    
    if (browser == 'firefox') {
        prefs <- makeFirefoxProfile(
            list("browser.download.dir" = tools::file_path_as_absolute(dir_temp),
                 "browser.download.folderList" = 2L,
                 "browser.download.manager.showWhenStarting" = FALSE,
                 "browser.helperApps.neverAsk.saveToDisk" = paste0(
                                    'multipart/x-zip',
                                    'application/zip',
                                    'application/x-zip-compressed',
                                    'application/x-compressed',
                                    'application/msword',
                                    'application/csv',
                                    'text/csv',
                                    'image/png ',
                                    'image/jpeg',
                                    'application/pdf',
                                    'text/html',
                                    'text/plain',
                                    ' application/excel',
                                    'application/vnd.ms-excel',
                                    'application/x-excel',
                                    'application/x-msexcel',
                                    'application/octet-stream', sep = ',')))
        
    }
    return(prefs)
}

open_browser <- function (browser = "firefox") {
    
    # assign global variable
    driver <<- remoteDriver(browserName = browser, 
                            extraCapabilities = get_prefs(browser), port=4444)
    driver$open(silent = TRUE)
    driver$navigate(login_url)
}

find_window <- function() {
    if (!select_window('Nexis®:')) {
        stop("Your have to login to Nexis using your library account\n")
    }
    Sys.sleep(1)
    click_powersearch()
}

select_window <- function(title) {
    window_current <- driver$getCurrentWindowHandle()[[1]]
    for (window in unlist(driver$getWindowHandles())) {
        driver$switchToWindow(window)
        if (stri_detect_fixed(driver$getTitle()[[1]], title)) {
            return(TRUE)
        }
    }
    driver$switchToWindow(window_current)
    return(FALSE)
}

click_powersearch <- function() {
    if (stri_detect_fixed(unlist(driver$getTitle()[[1]]), 'News Search')) {
        #elem <- driver$findElement('xpath', ".//a[text()='Power Search']")
        elem <- driver$findElement('xpath', ".//a[@title='Power Search']")
        elem$clickElement()
    }
}

modify_query <- function () {
    
    # Return to search window
    elem <- driver$findElement('xpath', ".//span[@title='Power Search']/a")
    elem$clickElement()
    
    while(!count_elements(".//*[@id='pageFooter']")) {
        Sys.sleep(1)
    }
}

search <- function(date) {
    
    if (count_elements(".//span[@title='Power Search']/a")) {
        modify_query()
    }
    
    print_log("Searching from", format(date[1], "%F"), 'to', format(date[2], "%F"))
    
    # Set search query
    elem <- driver$findElement('xpath', ".//*[@id='searchTextAreaStyle']")
    elem$clearElement()
    elem$sendKeysToElement(list(query))
    
    Sys.sleep(1)
    
    # Set date range
    elem <- driver$findElement('xpath', ".//*[@id='fromDate']")
    elem$clearElement()
    elem$sendKeysToElement(list(format(date[1], "%m/%d/%Y")))
    
    Sys.sleep(1)
    
    elem <- driver$findElement('xpath', ".//*[@id='toDate']")
    elem$clearElement()
    elem$sendKeysToElement(list(format(date[2], "%m/%d/%Y")))
    
    Sys.sleep(1)
    
    # Send query
    elem <- driver$findElement('xpath', ".//img[@title='Search']")
    elem$clickElement()
    
    while (!count_elements(".//*[@id='pageFooter']")) {
        cat(".")
        Sys.sleep(1)
        if (count_elements(".//img[@title='Over 3000 Results']"))
            stop("More than 3000 hits. You have to narrow date range.")
    }
    cat("\n")
    
    Sys.sleep(1)
}

is_completed <- function(date) {
    pattern <- paste0('^nexis_', 
                       format(date[1], '%Y%m%d'), '-', 
                       format(date[2], '%Y%m%d'), '_')
    files <- list.files(dir_data, pattern = pattern)
    if (!length(files))
        return(FALSE)
    match <- sapply(files, stri_match_last_regex, '(\\d+)-(\\d+)_(\\d+).html$')
    if (!ncol(match))
        return(FALSE)
    if (any(apply(match, 2, function(x) x[3] == x[4]))) {
        print_log("Skip", format(date[1], "%F"), 'to', format(date[2], "%F"), "\n")
        return(TRUE)
    } else {
        return(FALSE)
    }
}

is_zero <- function(date) {
    
    if (count_elements(".//h1[@class='zeroMsgHeader']")) {
        print_log("There is nothing to download\n")
        if (file.create(paste0(dir_data, '/', get_html_name(date, c(0, 0), 0)))) {
            return(TRUE)
        }
    }
    return(FALSE)
}

download <- function(date, range, last) {
    
    reset_temp_file()
    
    print_log("Downloading from", range[1], 'to', range[2])
    
    # Open delivery window
    elem <- driver$findElement('xpath', ".//*[@id='delivery_DnldRender']")
    elem$clickElement()
    
    while (!count_elements(".//img[@title='Download']")) {
        cat(".")
        Sys.sleep(1)
    }
    
    if (range[2] > 1) {
        # Set download range
        elem <- driver$findElement('xpath', ".//*[@id='rangetextbox']")
        elem$clearElement()
        elem$sendKeysToElement(list(paste0(range[1], '-', range[2])))
    }
    
    # Download
    elem <- driver$findElement('xpath', ".//img[@title='Download']")
    elem$clickElement()
    
    while (count_elements(".//img[@title='Download']")) {
        cat(".")
        Sys.sleep(1)
    }
    
    save_file(date, range, last)
    cat("\n")
    
    Sys.sleep(1)
}

get_date_range <- function(from, to, size = 1, unit = c('month', 'week', 'day')) {
    
    unit <- match.arg(unit)
    
    from <- as.Date(from)
    to <- as.Date(to)
    date <- seq.Date(from, to, by = 1)
    if (unit == 'day') {
        index <- as.integer(date)
    } else if (unit == 'week') {
        index <- as.integer(format(date, '%Y%U'))
    } else if (unit == 'month') {
        index <- as.integer(format(date, '%Y%m'))
    }
    index <- index - min(index) + 1
    dates <- lapply(split(date, ceiling(index / size)), range)
    names(dates) <- NULL
    return(dates)
}

get_download_range <- function(size = 500) {
    
    if (count_elements(".//*[@id='hitsTotal']")) {
        index <- 1
    } else {
        elem <- driver$findElement('xpath', ".//*[@id='updateCountDiv']")
        match <- stri_match_first_regex(elem$getElementText()[[1]], "(\\d+)")
        index <- seq_len(as.integer(match[,2]))
    }
    ranges <- lapply(split(index, ceiling(seq_along(index) / size)), range)
    names(ranges) <- NULL
    return(ranges)
}

save_file <- function(date, range, last) {
    
    files <- list.files(dir_temp, pattern = "\\.HTML$")
    while(length(files) == 0) {
        cat(".")
        Sys.sleep(1)
        files <- list.files(dir_temp, pattern = "\\.HTML$")
    }
    
    while (!check_file_ending(paste0(dir_temp, '/', files[1]), "</BODY></HTML>")) {
        cat(".")
        Sys.sleep(1)
    }
    
    name_html <- get_html_name(date, range, last)
    file.rename(paste0(dir_temp, '/', files[1]), 
                paste0(dir_data, '/', name_html))
    
    while(!count_elements(".//*[@id='closeBtn']")) {
        cat(".")
        Sys.sleep(1)
    }
    
    elem <- driver$findElement('xpath', ".//*[@id='closeBtn']")
    elem$clickElement()
    
}

get_html_name <- function (date, range, last) {
    name_html <- paste0('nexis_', 
                        format(date[1], '%Y%m%d'), '-', 
                        format(date[2], '%Y%m%d'), '_', 
                        sprintf('%04d', range[1]), '-', 
                        sprintf('%04d', range[2]), '_', 
                        sprintf('%04d', last), '.html')
    return(name_html)
}

check_file_ending <- function (file, expect) {
    if (!file.exists(file))
        return(FALSE)
    suppressWarnings({
        lines <- readLines(file)
    })
    line <- tail(lines, 1)
    if (length(line) == 0)
        return(FALSE)
    if (line == '')
        return(FALSE)
    if (line != expect) 
        return(FALSE)
    return(TRUE)
}


print_log <- function(...) {
    cat(format(Sys.time(), "%F %X"),  ...)
}
