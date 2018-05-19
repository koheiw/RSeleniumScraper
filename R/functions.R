
nexis <- new.env() # package-level local variable

# function to extract Selenium driver (for development)
#' @export
get_driver <- function() {
    nexis$driver
}

# function to set Selenium driver (for development)
#' @export
set_driver <- function(driver) {
    nexis$driver <- driver
}


#' @export
set_directory <- function (dir) {

    if (missing(dir)) stop('dir must be a valid path to a directory')

    if (dir.exists(dir)) {
        nexis$dir_data <- dir
    } else {
        dir.create(dir)
        nexis$dir_data <- dir
    }
    if (dir.exists(paste0(nexis$dir_data, '/temp'))) {
        nexis$dir_temp <- paste0(nexis$dir_data, '/temp')
    } else {
        dir.create(paste0(nexis$dir_data, '/temp'))
        nexis$dir_temp <- paste0(nexis$dir_data, '/temp')
    }
}

#' @export
get_directory <- function () {
    nexis$dir_data
}



#' @export
open_browser <- function (url, browser = "firefox") {

    if (missing(url) || !stri_startswith_fixed(url[1], 'http')) stop('url must be a valid URL')
    browser <- match.arg(browser)

    if (!length(get_session())) {
        if (is.null(nexis$dir_temp) || is.null(nexis$dir_data))
            stop('download directory must be set by set_directory() before opeing a brower')
        session <- get_session()
        # assign global variable
        nexis$driver <- remoteDriver(browserName = browser,
                                     extraCapabilities = get_prefs(browser), port=4444)
        nexis$driver$open(silent = TRUE)
        print_log("Opening browser")
        nexis$driver$navigate(url[1])
    } else {
        print_log("Browser is already open:", paste0('"', nexis$driver$getTitle()[[1]], '"'))
    }
}

#' check login status and move to Power Search
#'
#' This funtion check if the user is logged into Nexis database. If so, move to
#' Power Search page.
#' @export
check_login <- function() {
    if (!select_window('Nexis®:')) {
        stop("Your have to login to Nexis using your library account\n")
    }
    Sys.sleep(1)
    click_powersearch()
}


#' set and submit search query
#'
#' This function sets search keyword and data, and submit to the database. Users
#' should select sources manually before running this command.
#' @param query a query string for Nexis database
#' @param date a vector Date object created by \code{get_date_range()}. The fist
#'   date is the first day and second element is the last day of the serach
#'   period.
#' @param date_format format the date. It should be "\%d\%m/\%Y" for Nexis UK, but
#'   "\%m/\%d/\%Y" for other versions.
#' @export
submit <- function(query, date, date_format = "%m/%d/%Y") {

    if (missing(query) || !is.character(query)) stop('query must be a character string')
    if (missing(date) || !stri_length(query)) stop('query must be a valid search query')
    if (!is.date(date[1]) || !is.date(date[2]))
        stop('date must be a pair of dates that defines the search period')

    if (count_elements(".//span[@title='Power Search']/a")) {
        modify_query()
    }

    print_log("Searching from", format(date[1], "%F"), 'to', format(date[2], "%F"))

    # Set search query
    elem <- Nexis:::nexis$driver$findElement('xpath', ".//*[@id='searchTextAreaStyle']")
    elem$clearElement()
    elem$sendKeysToElement(list(query))

    Sys.sleep(1)

    # User custom date range
    elem <- Nexis:::nexis$driver$findElement('xpath', ".//*[@id='specifyDateDefaultStyle']/option[@value='from']")
    if (!length(elem$getElementAttribute("selected"))) {
        elem$clickElement()
    }

    Sys.sleep(1)

    # Set date range
    elem <- Nexis:::nexis$driver$findElement('xpath', ".//*[@id='fromDate']")
    elem$clearElement()
    elem$sendKeysToElement(list(format(date[1], date_format)))
    elem$setElementAttribute("value", format(date[1], date_format))

    Sys.sleep(1)

    elem <- Nexis:::nexis$driver$findElement('xpath', ".//*[@id='toDate']")
    elem$clearElement()
    elem$sendKeysToElement(list(format(date[2], date_format)))
    elem$setElementAttribute("value", format(date[2], date_format))

    Sys.sleep(1)

    # Send query
    elem <- Nexis:::nexis$driver$findElement('xpath', ".//img[@title='Search']")
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

#' @export
download <- function(date, range, last) {

    reset_temp_file()

    if (!is.date(date[1]) || !is.date(date[2]))
        stop('date must be a pair of dates that defines the search period')
    if (!is.numeric(range[1]) || !is.numeric(range[2]))
        stop('range must be a pair of integer that defines the download range')
    print_log("Downloading from", range[1], 'to', range[2])

    # Open delivery window
    elem <- nexis$driver$findElement('xpath', ".//*[@id='delivery_DnldRender']")
    elem$clickElement()

    while (!count_elements(".//img[@title='Download']")) {
        cat(".")
        Sys.sleep(1)
    }

    if (range[2] > 1) {
        # Set download range
        elem <- nexis$driver$findElement('xpath', ".//*[@id='rangetextbox']")
        elem$clearElement()
        elem$sendKeysToElement(list(paste0(range[1], '-', range[2])))
        Sys.sleep(1)

        # Set download format
        # js <- "document.getElementById('delFmt').selectedIndex = -1;" # reset
        # driver$executeScript(js, args = list('null'))
        # elem <- nexis$driver$findElement('xpath', ".//option[@value='QDS_EF_HTML']")
        # elem$setElementAttribute("selected", "selected")

        js <- "document.getElementById('delFmt').selectedIndex = 1;"
        nexis$driver$executeScript(js, args = list('null'))
        Sys.sleep(1)
    }

    # Download
    elem <- nexis$driver$findElement('xpath', ".//img[@title='Download']")
    elem$clickElement()

    while (count_elements(".//img[@title='Download']")) {
        cat(".")
        Sys.sleep(1)
    }

    save_file(date, range, last)
    cat("\n")

    Sys.sleep(1)
}

#' @export
is_completed <- function(date) {
    pattern <- paste0('^nexis_',
                       format(date[1], '%Y%m%d'), '-',
                       format(date[2], '%Y%m%d'), '_')
    files <- list.files(nexis$dir_data, pattern = pattern)
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

#' @export
is_zero <- function(date) {

    if (count_elements(".//h1[@class='zeroMsgHeader']")) {
        print_log("There is nothing to download\n")
        if (file.create(paste0(nexis$dir_data, '/', get_html_name(date, c(0, 0), 0)))) {
            return(TRUE)
        }
    }
    return(FALSE)
}

#' @export
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

#' @export
get_download_range <- function(size = 500) {

    if (count_elements(".//*[@id='hitsTotal']")) {
        index <- 1
    } else {
        elem <- nexis$driver$findElement('xpath', ".//*[@id='updateCountDiv']")
        match <- stri_match_first_regex(elem$getElementText()[[1]], "(\\d+)")
        index <- seq_len(as.integer(match[,2]))
    }
    ranges <- lapply(split(index, ceiling(seq_along(index) / size)), range)
    names(ranges) <- NULL
    return(ranges)
}

# Internal functions -----------------------------------------------------------

is.date <- function(x) {
   class(x) == 'Date'
}

get_prefs <- function(browser) {

    if (browser == 'firefox') {
        prefs <- makeFirefoxProfile(
            list("browser.download.dir" = tools::file_path_as_absolute(nexis$dir_temp),
                 "browser.download.folderList" = 2L,
                 "browser.download.manager.showWhenStarting" = FALSE,
                 "browser.helperApps.neverAsk.saveToDisk" = paste0(
                     'text/html',
                     'text/plain',
                     sep = ',')))

    }
    return(prefs)
}

select_window <- function(title) {
    window_current <- nexis$driver$getCurrentWindowHandle()[[1]]
    for (window in unlist(nexis$driver$getWindowHandles())) {
        nexis$driver$switchToWindow(window)
        if (stri_detect_fixed(nexis$driver$getTitle()[[1]], title)) {
            return(TRUE)
        }
    }
    nexis$driver$switchToWindow(window_current)
    return(FALSE)
}

click_powersearch <- function() {
    if (stri_detect_fixed(unlist(nexis$driver$getTitle()[[1]]), 'News Search')) {
        #elem <- nexis$driver$findElement('xpath', ".//a[text()='Power Search']")
        elem <- nexis$driver$findElement('xpath', ".//a[@title='Power Search']")
        elem$clickElement()
    }
}

modify_query <- function () {

    # Return to search window
    elem <- nexis$driver$findElement('xpath', ".//span[@title='Power Search']/a")
    elem$clickElement()

    while(!count_elements(".//*[@id='pageFooter']")) {
        Sys.sleep(1)
    }
}

save_file <- function(date, range, last) {

    files <- list.files(nexis$dir_temp, pattern = "\\.HTML$")
    while(length(files) == 0) {
        cat(".")
        Sys.sleep(1)
        files <- list.files(nexis$dir_temp, pattern = "\\.HTML$")
    }

    while (!check_file_ending(paste0(nexis$dir_temp, '/', files[1]), "</BODY></HTML>")) {
        cat(".")
        Sys.sleep(1)
    }

    name_html <- get_html_name(date, range, last)
    file.rename(paste0(nexis$dir_temp, '/', files[1]),
                paste0(nexis$dir_data, '/', name_html))

    while(!count_elements(".//*[@id='closeBtn']")) {
        cat(".")
        Sys.sleep(1)
    }

    elem <- nexis$driver$findElement('xpath', ".//*[@id='closeBtn']")
    elem$clickElement()

}

get_html_name <- function(date, range, last) {
    name_html <- paste0('nexis_',
                        format(date[1], '%Y%m%d'), '-',
                        format(date[2], '%Y%m%d'), '_',
                        sprintf('%04d', range[1]), '-',
                        sprintf('%04d', range[2]), '_',
                        sprintf('%04d', last), '.html')
    return(name_html)
}


# Utility functions -----------------------------------------


reset_temp_file <- function() {
    unlink(paste0(nexis$dir_temp, '/*')) # clean temp directory
}

count_elements <- function(query) {
    tryCatch({
        suppressMessages({
            elems <- nexis$driver$findElement('xpath', query)
            return(length(elems))
        })
    },
    error = function(e) {
        return(0)
    })
}

#' @importFrom utils tail
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

get_session <- function () {
    tryCatch({
        suppressMessages({
            return(Nexis:::nexis$driver$getSession())
        })
    },
    error = function(e) {
        list()
    })
}

print_log <- function(...) {
    cat(format(Sys.time(), "%F %X"),  ...)
}
