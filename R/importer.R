#' extract texts and meta data from Nexis HTML files
#'
#' This extract headings, body texts and meta data (date, byline, length,
#' secotion, edntion) from items in HTML files downloaded by the scraper.
#' @param path either path to a HTML file or a directory that containe HTML files
#' @param paragraph_separator a character to sperarate paragrahphs in body texts.
#' @export
#' @examples
#' irt <- import_nexis('tests/html/irish-times_1995-06-12_0001.html')
#' afp <- import_nexis('tests/html/afp_2013-03-12_0501.html')
#' gur <- import_nexis('tests/html/guardian_1986-01-01_0001.html')
#' all <- import_nexis('tests/html')
import_nexis <- function(path, paragraph_separator = '|'){

    if (dir.exists(path)) {
        dir <- path
        file <- list.files(dir, full.names = TRUE, recursive = TRUE)
        data <- data.frame()
        for(f in file){
            #print(file)
            if(stri_detect_regex(f, '\\.html$|\\.htm$|\\.xhtml$', ignore.case = TRUE)){
                data <- rbind(data, import_html(f, paragraph_separator))
            }
        }
    } else if (file.exists(path)) {
        data <- import_html(path, paragraph_separator)
    } else {
        stop(path, "does not exist")
    }
    return(data)
}

import_html <- function(file, sep = ' '){

    #Convert format
    cat('Reading', file, '\n')

    line <- readLines(file, warn = FALSE, encoding = "UTF-8")
    html <- paste0(fix_html(line), collapse = "\n")

    #Load as DOM object
    dom <- htmlParse(html, encoding = "UTF-8")
    data <- data.frame()
    for(doc in getNodeSet(dom, '//doc')){
        data <- rbind(data, extract_attrs(doc))
    }
    colnames(data) <- c('pub', 'edition', 'date', 'byline', 'length', 'section', 'head', 'body')
    return(data)
}


extract_attrs <- function(node, sep = "|") {

    attrs <- list(pub = '', edition = '', date = '', byline = '', length = '', section = '', head = '', body = '')

    regex <- paste0(c('(January|February|March|April|May|June|July|August|September|October|November|December)',
                     '[, ]+([0-9]{1,2})',
                     '[, ]+([0-9]{4})',
                     '([,; ]+(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday))?',
                     '([, ]+(.+))?'), collapse = '')

    n_max <- 0;
    i <- 1
    #print(node)
    for(div in getNodeSet(node, './/div')){

        s <- xmlValue(div, './/text()')
        s <- clean_text(s)
        n <- stri_length(s);
        if (is.na(n)) next

        #cat('----------------\n')
        #cat(i, stri_trim(s), "\n")

        if (i == 2) {
            attrs$pub <- stri_trim(s)
        } else if (i == 3) {
            m <- stri_match_first_regex(s, regex)
            if (all(!is.na(m[1,2:4]))) {
                attrs$date <- format(as.Date(paste0(m[1,2:4], collapse = ' '), '%B %d %Y'), '%Y-%m-%d')
            }
            if (!is.na(m[1,8])) {
                attrs$edition <- stri_trim(m[1,8])
            }
        } else if (i == 4) {
            attrs$head <- stri_trim(s)
        } else if (i >= 5) {
            if (stri_detect_regex(s, "^BYLINE: ")) {
                attrs$byline = stri_trim(stri_replace_first_regex(s, "^BYLINE: ", ''))
            } else if (stri_detect_regex(s, "^SECTION: ")) {
                attrs$section = stri_trim(stri_replace_first_regex(s, "^SECTION: ", ''));
            } else if (stri_detect_regex(s, "^LENGTH: ")) {
                attrs$length = stri_trim(stri_replace_all_regex(s, "[^0-9]", ''))
            } else if (!is.null(attrs$length) && n > n_max &&
                       !stri_detect_regex(s, "^(BYLINE|URL|LOAD-DATE|LANGUAGE|GRAPHIC|PUBLICATION-TYPE|JOURNAL-CODE): ")){
                ps <- getNodeSet(div, './/p')
                p <- sapply(ps, xmlValue)
                attrs$body <- stri_trim(paste0(p, collapse = paste0(' ', sep, ' ')))
                n_max = n
            }
        }
        i <- i + 1
    }
    if (attrs$pub[1] == '' || is.na(attrs$pub[1])) warning('Failed to extract publication name')
    if (attrs$date[1] == '' || is.na(attrs$date[1])) warning('Failed to extract date')
    if (attrs$head[1] == '' || is.na(attrs$head[1])) warning('Failed to extract heading')
    if (attrs$body[1] == '' || is.na(attrs$body[1])) warning('Failed to extract body text')
    return(as.data.frame(attrs, stringsAsFactors = FALSE))
}

clean_text <- function(str) {
    str = stri_replace_all_regex(str, '/[[:^print:]]/', ' '); # This works better
    str = stri_replace_all_fixed(str, "\r", ' ')
    str = stri_replace_all_fixed(str, "\n", ' ')
    str = stri_replace_all_fixed(str, "\t", ' ')
    str = stri_replace_all_regex(str, "\\s\\s+", ' ')
    str = stri_trim(str);
    return(str)
}

fix_html <- function(line){
    d <- 0
    for (i in seq_along(line)) {
        l <- line[i]
        if (stri_detect_fixed(l, '<DOC NUMBER=1>')) d <- d + 1
        l = stri_replace_all_fixed(l, '<!-- Hide XML section from browser', '');
        l = stri_replace_all_fixed(l, '<DOC NUMBER=1>', paste0('<DOC ID="doc_id_',  d,  '">', collapse = ''))
        l = stri_replace_all_fixed(l, '<DOCFULL> -->', '<DOCFULL>');
        l = stri_replace_all_fixed(l, '</DOC> -->', '</DOC>');
        l = stri_replace_all_fixed(l, '<BR>', '<BR> ');
        line[i] <- l
    }
    return(line)
}

