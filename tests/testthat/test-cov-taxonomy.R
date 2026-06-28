library(testthat)
library(mysterycall)


# ---------------------------------------------------------------------------
# Tests for the `taxonomy` dataset
# ---------------------------------------------------------------------------

test_that("taxonomy dataset loads with expected structure", {
  data(taxonomy, package = "mysterycall", envir = environment())
  expect_s3_class(taxonomy, "data.frame")
  expect_equal(ncol(taxonomy), 3L)
  expect_gte(nrow(taxonomy), 800L)
  expect_named(taxonomy, c("Code", "Classification", "Specialization"))
})

test_that("taxonomy dataset contains known Obstetrics & Gynecology entries", {
  data(taxonomy, package = "mysterycall", envir = environment())
  # The base OB/GYN code (no subspecialty) must be present
  expect_true("207V00000X" %in% taxonomy$Code)
  # Its classification must be correct
  row <- taxonomy[taxonomy$Code == "207V00000X", ]
  expect_equal(row$Classification, "Obstetrics & Gynecology")
  # Gynecologic Oncology subspecialty must be present
  expect_true("207VX0201X" %in% taxonomy$Code)
})

test_that("taxonomy dataset Code column has no empty strings", {
  data(taxonomy, package = "mysterycall", envir = environment())
  # Codes may not be NA and must be non-empty strings
  expect_false(any(is.na(taxonomy$Code)))
  expect_false(any(!nzchar(taxonomy$Code)))
})


# ---------------------------------------------------------------------------
# Tests for mysterycall_search_taxonomy()
# ---------------------------------------------------------------------------

test_that("mysterycall_search_taxonomy returns empty tibble for NULL input", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_search_taxonomy(NULL, write_snapshot = FALSE, notify = FALSE)
  ))
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
})

test_that("mysterycall_search_taxonomy returns empty tibble for NA input", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_search_taxonomy(NA_character_, write_snapshot = FALSE, notify = FALSE)
  ))
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
})

test_that("mysterycall_search_taxonomy returns empty tibble for empty-string input", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_search_taxonomy("", write_snapshot = FALSE, notify = FALSE)
  ))
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
})

test_that("mysterycall_search_taxonomy errors when limit exceeds 1200", {
  expect_error(
    suppressMessages(
      mysterycall_search_taxonomy(
        "Obstetrics & Gynecology",
        limit = 1201L,
        write_snapshot = FALSE,
        notify = FALSE
      )
    )
  )
})

test_that("mysterycall_search_taxonomy errors when write_snapshot is not logical", {
  expect_error(
    suppressMessages(
      mysterycall_search_taxonomy(
        "Obstetrics & Gynecology",
        write_snapshot = "yes",
        notify = FALSE
      )
    )
  )
})

test_that("mysterycall_search_taxonomy warns and returns empty for multi-char state codes", {
  # State abbreviations longer than 2 characters are invalid; the function
  # should warn about them and, when no valid states remain, return an empty
  # data frame without hitting the API.
  expect_warning(
    result <- suppressMessages(
      mysterycall_search_taxonomy(
        "Obstetrics & Gynecology",
        states    = c("COLORADO", "CALIFORNIA"),
        write_snapshot = FALSE,
        notify    = FALSE
      )
    ),
    regexp = "invalid state abbreviation"
  )
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
})

test_that("mysterycall_search_taxonomy with real term requires API", {
  skip("requires live NPI API")
  result <- suppressMessages(
    mysterycall_search_taxonomy(
      "Gynecologic Oncology",
      write_snapshot = FALSE,
      notify = FALSE
    )
  )
  expect_s3_class(result, "data.frame")
  expect_true("npi" %in% names(result))
})
