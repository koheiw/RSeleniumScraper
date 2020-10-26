#' Generate file names
#' @param prefix prefix of the files
#' @param date date of the files
#' @param range number indicating the items download
#' @param last number indicating the last item
#' @param ext extension of the files
#' @export
make_filename <- function(prefix, date, range, last, ext) {
    paste0(prefix, '_',
           format(date[1], '%Y%m%d'), '-',
           format(date[2], '%Y%m%d'), '_',
           sprintf('%04d', range[1]), '-',
           sprintf('%04d', range[2]), '_',
           sprintf('%04d', last), '.', ext)
}

#' Reset temporary folder
#' @export
reset_temp_file <- function() {
    unlink(paste0(config$dir_temp, '/*')) # clean temp directory
}

#' Check the last line of text file
#' @param path path to the file
#' @param expect expected content of the last line
#' @export
check_file_ending <- function (path, expect) {

    if (!file.exists(path))
        return(FALSE)
    suppressWarnings({
        lines <- readLines(path)
    })
    line <- utils::tail(lines, 1)
    if (length(line) == 0)
        return(FALSE)
    if (line == '')
        return(FALSE)
    if (line != expect)
        return(FALSE)
    return(TRUE)
}

#' Check if downloaded temporary file is a valid zip file
#' @export
check_zipfile <- function() {
    tryCatch({
        utils::unzip(list.files(get_config("dir_temp"), full.names = TRUE)[1], list = TRUE)
        return(TRUE)
    },
    error = function(e) {
        return(FALSE)
    },
    warning = function(e) {
        return(FALSE)
    })
}

#' Save downloaded temporary file in a new location
#' @param path path to a new location
#' @export
save_file <- function(path) {
    file.rename(list.files(get_config("dir_temp"), full.names = TRUE)[1], path)
}

#' Check if files exists in the data folder
#' @inheritParams make_filename
#' @import stringi
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
