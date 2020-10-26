#' Generate date ranges in small chunks
#' @param from first date of the range
#' @param to last date of the range
#' @param size size of the chunks
#' @param unit unit of the size of the chunks
#' @export
get_date_range <- function(from, to, size = 1, unit = c('year', 'month', 'week', 'day')) {

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
    } else if (unit == 'year') {
        index <- as.integer(format(date, '%Y'))
    }
    index <- index - min(index) + 1
    dates <- lapply(split(date, ceiling(index / size)), range)
    names(dates) <- NULL
    return(dates)
}

#' Print message in the console
#' @param ... passed to `cat()`
#' @export
print_log <- function(...) {
    cat(format(Sys.time(), "%F %X"),  ...)
}


is.date <- function(x) {
    class(x) == 'Date'
}
