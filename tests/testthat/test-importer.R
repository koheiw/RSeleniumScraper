require(stringi)
context("importer")

test_that("importer can read English newspapers", {

    irt <- import_nexis('../../tests/html/irish-times_1995-06-12_0001.html')
    expect_equal(nrow(irt), 166)
    expect_false(any(irt$head == ''))
    expect_false(any(irt$body == ''))
    expect_true(all(stri_detect_regex(irt$date, '^\\d{4}-\\d{2}-\\d{2}$')))

    gur <- import_nexis('../../tests/html/guardian_1986-01-01_0001.html')
    expect_equal(nrow(gur), 262)
    expect_false(any(gur$head == ''))
    expect_false(any(gur$body == ''))
    expect_true(all(stri_detect_regex(gur$date, '^\\d{4}-\\d{2}-\\d{2}$')))

    sun <- import_nexis('../../tests/html/sun_2000-11-01_0001.html')
    expect_equal(nrow(sun), 32)
    expect_false(any(sun$head == ''))
    expect_false(any(sun$body == ''))
    expect_true(all(stri_detect_regex(sun$date, '^\\d{4}-\\d{2}-\\d{2}$')))

})

test_that("importer can read English newswires", {

    afp <- import_nexis('../../tests/html/afp_2013-03-12_0501.html')
    expect_equal(nrow(afp), 74)
    expect_false(any(afp$head == ''))
    expect_false(any(afp$body == ''))
    expect_true(all(stri_detect_regex(afp$date, '^\\d{4}-\\d{2}-\\d{2}$')))

})

test_that("importer can read German newswires", {

    spg <- import_nexis('../../tests/html/spiegel_2012-02-01_0001.html', language_date = 'german')
    expect_equal(nrow(spg), 49)
    expect_false(any(spg$head == ''))
    expect_false(any(spg$body == ''))
    expect_true(all(stri_detect_regex(spg$date, '^\\d{4}-\\d{2}-\\d{2}$')))

})

test_that("importer can read from folder", {

    all <- import_nexis('../../tests/html/')
    expect_equal(nrow(all), 166 + 262 + 32 + 74 + 49)

})
