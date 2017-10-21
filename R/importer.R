library(XML) #might need libxml2-dev via apt-get command

import_nexis <- function(dir, sep = '|'){

    file <- list.files(dir, full.names = TRUE, recursive = TRUE)
    data <- data.frame()
    for(f in file){
        #print(file)
        if(stri_detect_regex(f, '\\.html$|\\.htm$|\\.xhtml$', ignore.case = TRUE)){
            data <- rbind(data, import_html(f, sep))
        }
    }
    return(data)
}

import_html <- function(file, sep = ' '){

    #Convert format
    cat('Reading', file, '\n')

    # HTML cleaning------------------------------------------------

    line <- readLines(file, encoding = "UTF-8")
    html <- paste0(fix_html(line), collapse = "\n")

    # Write to debug
    #cat(html, file="converted.html", sep="", append=FALSE)

    # Main process------------------------------------------------


    data <- data.frame()

    #Load as DOM object
    dom <- htmlParse(html, encoding = "UTF-8")
    for(doc in getNodeSet(dom, '//doc')){

        i <- 1
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

        cat('----------------\n')
        cat(i, stri_trim(s), "\n")

        if (length(getNodeSet(div, './/span')) == 1) {
            if (i == 2) {
                attrs$pub <- stri_trim(s)
            } else if (i == 3) {
                m <- stri_match_first_regex(s, regex)
                if (all(!is.na(m[1,2:4]))) {
                    attrs$date <- format(as.Date(paste0(m[1,2:4], collapse = ''), '%B %d %Y'), '%Y-%m-%d')
                }
                if (!is.na(m[1,8])) {
                    attrs$edition <- stri_trim(m[1,8])
                }
            } else if (i == 4) {
                attrs$head <- stri_trim(s)
            }
        } else {
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
    return(as.data.frame(attrs, stringsAsFactors = FALSE))
}

out <- import_html('/home/kohei/packages/Nexis/tests/html/irish-times_1995-06-12_0001.html')
out <- import_html('/home/kohei/packages/Nexis/tests/html//afp_2013-03-12_0501.html')
#out <- import_nexis('/home/kohei/packages/Nexis/tests/html/')
print(out$date)


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

