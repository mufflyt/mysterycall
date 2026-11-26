# Adversarial tests pinning the zip5 core and read_table NPI fabrication fixes.
# Every case here used to produce a DIFFERENT valid-looking value instead of
# the right one or an explicit missing.

test_that("zip5: unseparated ZIP+4 that lost its leading zero is recovered, not shifted", {
  for (fun in list(mysterycall_clean_zip,
                   mysterycall:::mysterycall_extract_zip5,
                   mysterycall:::mysterycall_normalize_zip5)) {
    # Boston 02101-1234 after a numeric round-trip; used to return 21011
    expect_equal(fun("21011234"), "02101")
    expect_equal(fun("2101-1234"), "02101")
    # two leading zeros lost: 00501-1234; used to return 50112
    expect_equal(fun("5011234"), "00501")
    # intact forms unchanged
    expect_equal(fun("021011234"), "02101")
    expect_equal(fun("123456789"), "12345")
  }
})

test_that("zip5: scientific notation is missing, never reassembled", {
  for (fun in list(mysterycall_clean_zip,
                   mysterycall:::mysterycall_extract_zip5,
                   mysterycall:::mysterycall_normalize_zip5)) {
    for (x in c("8.0204e4", "1.2e5", "8E+04", "8.0204e+04")) {
      expect_true(is.na(fun(x)), info = x)
    }
  }
})

test_that("zip5: digit runs that are not ZIP-shaped are missing, not truncated", {
  for (fun in list(mysterycall_clean_zip,
                   mysterycall:::mysterycall_extract_zip5,
                   mysterycall:::mysterycall_normalize_zip5)) {
    # a phone number in the ZIP column used to become ZIP 30355
    expect_true(is.na(fun("3035550199")))
    expect_true(is.na(fun("123456")))
    expect_true(is.na(fun("13035550199")))
  }
})

test_that("zip5: enshrined contracts survive the shape rules", {
  # documented, test-enshrined behaviors must not move
  expect_equal(mysterycall_clean_zip("1"), "00001")
  expect_equal(mysterycall_clean_zip(8031), "08031")
  expect_true(is.na(mysterycall:::mysterycall_extract_zip5("80")))
  expect_equal(mysterycall_clean_zip("7001-1234"), "07001")
  expect_equal(mysterycall_clean_zip(c("80204, 02101", "80204")), c("80204", "80204"))
  # idempotence: normalizing twice is a fixed point
  raw <- c("21011234", "5011234", "7030", "80204.0", "2101-1234")
  once <- mysterycall_clean_zip(raw)
  expect_true(all(grepl("^[0-9]{5}$", once)))
  expect_equal(mysterycall_clean_zip(once), once)
})

test_that("read_table: fractional corruption becomes missing, not a fabricated NPI", {
  skip_if_not_installed("readr")
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  # 123456789.5 used to round to 123456790 -- a different valid-looking NPI
  writeLines(c("npi,value", "123456789.5,1", "1922051358,2"), tmp)
  expect_warning(
    df <- suppressMessages(mysterycall_read_table(tmp)),
    "non-integer"
  )
  expect_true(is.na(df$npi[1]))
  expect_equal(df$npi[2], "1922051358")
})

test_that("read_table: Inf, scientific-scale and negative input cannot fabricate NPIs", {
  skip_if_not_installed("readr")
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(c("npi,value", "1e15,1", "-1962780445,2", "1234567893,3"), tmp)
  df <- suppressWarnings(suppressMessages(mysterycall_read_table(tmp)))
  # 1e15 used to become a 15-digit string; now rejected by the SSOT
  expect_true(is.na(df$npi[1]))
  expect_equal(df$npi[3], "1234567893")
})

test_that("read_table: missing numeric NPI still round-trips to NA, not 'NA'", {
  skip_if_not_installed("readr")
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(c("npi,x", "1234567893,a", "NA,b"), tmp)
  df <- suppressMessages(mysterycall_read_table(tmp))
  expect_true(is.na(df$npi[2]))
  expect_false(any(df$npi == "NA", na.rm = TRUE))
})
