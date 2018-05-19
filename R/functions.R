
config <- new.env() # for package-level global variables

# function to extract Selenium driver (for development)
#' @export
get_driver <- function() {
    config$driver
}

# function to set Selenium driver (for development)
#' @export
set_driver <- function(driver) {
    config$driver <- driver
}

#' @export
set_directory <- function (dir) {

    if (missing(dir)) stop('dir must be a valid path to a directory')

    if (dir.exists(dir)) {
        config$dir_data <- dir
    } else {
        dir.create(dir)
        config$dir_data <- dir
    }
    if (dir.exists(paste0(config$dir_data, '/temp'))) {
        config$dir_temp <- paste0(config$dir_data, '/temp')
    } else {
        dir.create(paste0(config$dir_data, '/temp'))
        config$dir_temp <- paste0(config$dir_data, '/temp')
    }
}

#' @export
get_directory <- function () {
    config$dir_data
}

#' @export
open_browser <- function (url, browser = "firefox") {

    if (missing(url) || !stri_startswith_fixed(url[1], 'http')) stop('url must be a valid URL')
    browser <- match.arg(browser)

    if (!length(get_session())) {
        if (is.null(config$dir_temp) || is.null(config$dir_data))
            stop('download directory must be set by set_directory() before opeing a brower')
        session <- get_session()
        # assign global variable
        config$driver <- remoteDriver(browserName = browser,
                                      extraCapabilities = get_prefs(browser), port=4444)
        config$driver$open(silent = TRUE)
        print_log("Opening browser")
        config$driver$navigate(url[1])
    } else {
        print_log("Browser is already open:", paste0('"', config$driver$getTitle()[[1]], '"'))
    }
}

#' @export
print_log <- function(...) {
    cat(format(Sys.time(), "%F %X"),  ...)
}

#' @export
get_config <- function(name = NULL) {
    if (is.null(name)) {
        return(as.list(config))
    } else {
        return(config[[name]])
    }
}

#' @export
is_completed <- function(prefix, date, ext) {
    pattern <- paste0('^', prefix, '_',
                      format(date[1], '%Y%m%d'), '-',
                      format(date[2], '%Y%m%d'), '_')
    files <- list.files(config$dir_data, pattern = pattern)
    if (!length(files))
        return(FALSE)
    match <- sapply(files, stri_match_last_regex, paste0('(\\d+)-(\\d+)_(\\d+)\\.', ext,'$'))
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
select_window <- function(title) {
    window_current <- config$driver$getCurrentWindowHandle()[[1]]
    for (window in unlist(config$driver$getWindowHandles())) {
        config$driver$switchToWindow(window)
        if (stri_detect_fixed(config$driver$getTitle()[[1]], title)) {
            return(TRUE)
        }
    }
    config$driver$switchToWindow(window_current)
    return(FALSE)
}

#' @export
make_filename <- function(prefix, date, range, last, ext) {
    paste0(prefix, '_',
           format(date[1], '%Y%m%d'), '-',
           format(date[2], '%Y%m%d'), '_',
           sprintf('%04d', range[1]), '-',
           sprintf('%04d', range[2]), '_',
           sprintf('%04d', last), '.', ext)
}

#' @export
reset_temp_file <- function() {
    unlink(paste0(config$dir_temp, '/*')) # clean temp directory
}

#' @export
count_elements <- function(query) {
    tryCatch({
        suppressMessages({
            elems <- config$driver$findElement('xpath', query)
            return(length(elems))
        })
    },
    error = function(e) {
        return(0)
    })
}

#' @export
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

#' @export
get_session <- function () {
    tryCatch({
        suppressMessages({
            return(config$driver$getSession())
        })
    },
    error = function(e) {
        list()
    })
}


# Internal functions -----------------------------------------------------------

is.date <- function(x) {
    class(x) == 'Date'
}

get_prefs <- function(browser) {

    if (browser == 'firefox') {
        prefs <- makeFirefoxProfile(
            list("browser.download.dir" = tools::file_path_as_absolute(config$dir_temp),
                 "browser.download.folderList" = 2L,
                 "browser.download.manager.showWhenStarting" = FALSE,
                 "browser.helperApps.neverAsk.saveToDisk" = paste0(
                     'text/html',
                     'text/plain',
                     'application/msword',
                     sep = ',')))

    }
    return(prefs)
}

