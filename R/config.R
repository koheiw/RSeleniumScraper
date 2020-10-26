#' Set or get path to directory to save files
#' @param path path to the directory
#' @export
set_directory <- function (path) {

    if (missing(path)) stop('path must be a valid path to a directory')

    if (dir.exists(path)) {
        config$dir_data <- path
    } else {
        dir.create(path)
        config$dir_data <- path
    }
}

#' @rdname set_directory
#' @export
get_directory <- function () {
    config$dir_data
}

#' Get scraper's settings
#' @param name name of setting
#' @export
get_config <- function(name = NULL) {
    if (is.null(name)) {
        return(as.list(config))
    } else {
        return(config[[name]])
    }
}


get_prefs <- function(browser) {

    if (browser == 'firefox') {
        prefs <- RSelenium::makeFirefoxProfile(
            list("browser.download.dir" = tools::file_path_as_absolute(config$dir_temp),
                 "browser.download.folderList" = 2L,
                 "browser.download.manager.showWhenStarting" = FALSE,
                 "browser.helperApps.neverAsk.saveToDisk" = paste0(
                     'text/html',
                     'text/plain',
                     'application/msword',
                     'application/vnd.ms-excel',
                     'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                     'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                     sep = ',')
            ))

    }
    return(prefs)
}

