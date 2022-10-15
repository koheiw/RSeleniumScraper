
#' Open page in browser
#' @param url URL to load in the browser
#' @param browser web browser to start
#' @import RSelenium
#' @export
open_browser <- function (url, browser) {

    if (missing(url) || !stri_startswith_fixed(url[1], 'http')) stop('url must be a valid URL')
    browser <- match.arg(browser)

    # temporary file
    if (.Platform$OS.type == 'windows') {
        config$dir_temp <- paste(tempdir(), "download", sep = '\\')
    } else {
        config$dir_temp <- paste(tempdir(), "download", sep = '/')
    }
    if (!dir.exists(config$dir_temp)) {
        dir.create(config$dir_temp)
    }

    if (!length(get_session())) {
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

#' @rdname open_browser
#' @export
navigate_browser <- function(url) {
    config$driver$navigate(url)
}


#' Select browser's pop-up window by window titles
#' @param title title of the window
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

#' Select or count elements by XPath
#' @param xpath query to specify elements
#' @param wait wait until elements are found if `TRUE`
#' @export
find_element <- function(xpath, wait = FALSE) {
    while(wait && !count_elements(xpath))
        Sys.sleep(1)
    get_driver()$findElement('xpath', xpath)
}

#' @rdname find_element
#' @export
find_elements <- function(xpath, wait = FALSE) {
    while(wait && !count_elements(xpath))
        Sys.sleep(1)
    get_driver()$findElements('xpath', xpath)
}

#' @rdname find_element
#' @export
count_elements <- function(xpath) {
    tryCatch({
        suppressMessages({
            elems <- config$driver$findElements('xpath', xpath)
            return(length(elems))
        })
    },
    error = function(e) {
        return(0)
    })
}

#' Get height and width of element
#' @param xpath query to specify element
#' @export
get_element_size <- function(xpath) {

    tryCatch({
        suppressMessages({
            elem <- get_driver()$findElement('xpath', xpath)
            size <- elem$getElementSize()
            return(c(size$height, size$width))
        })
    },
    error = function(e) {
        return(c(0, 0))
    })
}

#' Wait for element to be found
#' @param xpath query to specify element
#' @param timeout maximum time to wait in seconds
#' @export
wait_for <- function(xpath, timeout = 120) {
    t <- 0
    while (!count_elements(xpath)) {
        Sys.sleep(1)
        t <- t + 1
        if (t > timeout) {
            invisible(NULL)
        }
    }
    Sys.sleep(1)
    invisible(NULL)
}
