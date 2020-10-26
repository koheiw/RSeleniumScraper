#' Get or set Selenium driver (for development)
#' @export
get_driver <- function() {
    config$driver
}

#' @rdname get_driver
#' @param driver Selenium driver to use
#' @export
set_driver <- function(driver) {
    config$driver <- driver
}

#' Get session from Selenium driver (for development)
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
