library(testthat)
library(mysterycall)

# Shared test fixtures
AUDIT <- data.frame(
  npi = c("1234567893", "1234567893", "9876543210", "9876543210"),
  insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS"),
  offered = c(TRUE, TRUE, FALSE, TRUE),
  contact_office = c(TRUE, TRUE, FALSE, TRUE),
  wait_days = c(5L, 12L, 3L, 7L),
  business_days_until_appointment = c(5L, 12L, 3L, 7L),
  caller_id = c("A", "A", "B", "B"),
  wave = c(1L, 1L, 2L, 2L),
  specialty = c("OB/GYN", "OB/GYN", "OB/GYN", "OB/GYN"),
  phone = c("3035550100", "3035550100", "7205550200", "7205550200"),
  physician_information = c("Smith, John", "Smith, John", "Doe, Jane", "Doe, Jane"),
  reason_for_exclusions = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid", "BCBS"), each = 40L),
  stringsAsFactors = FALSE
)

# ── mysterycall_write_table + mysterycall_read_table ──────────────────────────

test_that("write_table then read_table round-trips a CSV correctly", {
  skip_if_not_installed("readr")

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  suppressMessages(suppressWarnings(
    mysterycall_write_table(COUNT_DF, tmp)
  ))

  expect_true(file.exists(tmp))

  result <- suppressMessages(suppressWarnings(
    mysterycall_read_table(tmp)
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), nrow(COUNT_DF))
  expect_equal(ncol(result), ncol(COUNT_DF))
  expect_equal(sort(names(result)), sort(names(COUNT_DF)))
})

test_that("write_table returns the path invisibly", {
  skip_if_not_installed("readr")

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  result <- suppressMessages(suppressWarnings(
    mysterycall_write_table(mtcars, tmp)
  ))

  expect_equal(result, tmp)
})

test_that("read_table coerces numeric npi column to character", {
  skip_if_not_installed("readr")

  # Write a CSV that stores NPI as numeric (integer-valued)
  df_num_npi <- data.frame(
    npi = c(1234567893, 9876543210),
    value = c(1L, 2L),
    stringsAsFactors = FALSE
  )

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  # Write directly with utils so we control the column type on disk
  suppressMessages(suppressWarnings(
    utils::write.csv(df_num_npi, tmp, row.names = FALSE)
  ))

  result <- suppressMessages(suppressWarnings(
    mysterycall_read_table(tmp)
  ))

  expect_true(is.character(result[["npi"]]),
    info = "npi column should be coerced to character")
})

test_that("read_table warns when npi column has non-integer numeric values", {
  skip_if_not_installed("readr")

  # Write a CSV that stores NPI as a non-integer numeric
  tmp_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp_csv), add = TRUE)

  # Write raw text so readr reads npi as numeric with a decimal
  writeLines(c("npi,value", "123456789.5,1", "987654321.9,2"), tmp_csv)

  expect_warning(
    suppressMessages(mysterycall_read_table(tmp_csv)),
    regexp = "non-integer"
  )
})

test_that("write_table append=TRUE adds rows to an existing CSV", {
  skip_if_not_installed("readr")

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  half1 <- COUNT_DF[1:40, ]
  half2 <- COUNT_DF[41:80, ]

  suppressMessages(suppressWarnings(
    mysterycall_write_table(half1, tmp)
  ))
  suppressMessages(suppressWarnings(
    mysterycall_write_table(half2, tmp, append = TRUE, col_names = FALSE)
  ))

  result <- suppressMessages(suppressWarnings(
    mysterycall_read_table(tmp)
  ))

  expect_equal(nrow(result), nrow(COUNT_DF))
})

test_that("read_table errors when the file does not exist", {
  skip_if_not_installed("readr")

  bad_path <- tempfile(fileext = ".csv")  # never created

  expect_error(
    suppressMessages(mysterycall_read_table(bad_path))
  )
})
