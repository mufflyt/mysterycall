library(testthat)
library(mysterycall)

AUDIT <- data.frame(
  npi                              = c("1234567893","1234567893","9876543210","9876543210"),
  insurance                        = c("Medicaid","BCBS","Medicaid","BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A","A","B","B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN","OB/GYN","OB/GYN","OB/GYN"),
  phone                            = c("3035550100","3035550100","7205550200","7205550200"),
  physician_information            = c("Smith, John","Smith, John","Doe, Jane","Doe, Jane"),
  reason_for_exclusions            = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid","BCBS"), each = 40L),
  stringsAsFactors = FALSE
)


test_that("mysterycall_acceptance_waffle happy path with default parameters", {
  skip_if_not_installed("waffle")
  skip_if_not_installed("patchwork")

  acc_df <- data.frame(
    insurance_type = c("Medicaid", "Medicaid", "Blue Cross/Blue Shield", "Blue Cross/Blue Shield"),
    outcome        = c("Accepted", "Declined", "Accepted", "Declined"),
    n              = c(47L, 53L, 72L, 28L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_acceptance_waffle(acc_df, output_dir = NA)
  }))

  expect_invisible(result)
  expect_true(!is.null(result))
})


test_that("mysterycall_acceptance_waffle returns ggplot/patchwork object", {
  skip_if_not_installed("waffle")
  skip_if_not_installed("patchwork")

  acc_df <- data.frame(
    insurance_type = c("Medicaid", "Medicaid", "Blue Cross/Blue Shield", "Blue Cross/Blue Shield"),
    outcome        = c("Accepted", "Declined", "Accepted", "Declined"),
    n              = c(47L, 53L, 72L, 28L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_acceptance_waffle(acc_df, output_dir = NA)
  }))

  # Check that result is a ggplot or patchwork object
  expect_true(inherits(result, "ggplot") || inherits(result, "patchwork"))
})


test_that("mysterycall_acceptance_waffle errors when acceptance_result is not a data frame", {
  skip_if_not_installed("waffle")
  skip_if_not_installed("patchwork")

  expect_error(
    suppressMessages(suppressWarnings({
      mysterycall_acceptance_waffle(list(a = 1), output_dir = NA)
    })),
    "data frame"
  )
})


test_that("mysterycall_acceptance_waffle errors when required columns are missing", {
  skip_if_not_installed("waffle")
  skip_if_not_installed("patchwork")

  # Missing outcome column
  acc_missing <- data.frame(
    insurance_type = c("Medicaid", "Blue Cross/Blue Shield"),
    n              = c(47L, 72L),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(suppressWarnings({
      mysterycall_acceptance_waffle(acc_missing, output_dir = NA)
    })),
    "must.include"
  )
})


test_that("mysterycall_acceptance_waffle errors when insurance_type not found", {
  skip_if_not_installed("waffle")
  skip_if_not_installed("patchwork")

  acc_df <- data.frame(
    insurance_type = c("Medicaid", "Medicaid"),
    outcome        = c("Accepted", "Declined"),
    n              = c(47L, 53L),
    stringsAsFactors = FALSE
  )

  # Try to request a non-existent insurance type
  expect_error(
    suppressMessages(suppressWarnings({
      mysterycall_acceptance_waffle(acc_df, bcbs_label = "NonExistent", output_dir = NA)
    })),
    "No rows found"
  )
})


test_that("mysterycall_acceptance_waffle with custom parameters", {
  skip_if_not_installed("waffle")
  skip_if_not_installed("patchwork")

  acc_df <- data.frame(
    insurance_type = c("Medicaid", "Medicaid", "BCBS", "BCBS"),
    outcome        = c("Accepted", "Declined", "Accepted", "Declined"),
    n              = c(47L, 53L, 72L, 28L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_acceptance_waffle(
      acc_df,
      medicaid_label = "Medicaid",
      bcbs_label     = "BCBS",
      colors         = c(Accepted = "#E41A1C", Declined = "#377EB8"),
      rows           = 5L,
      title          = "Appointment Acceptance by Insurance",
      flip           = FALSE,
      monochrome     = FALSE,
      output_dir     = NA
    )
  }))

  expect_invisible(result)
  expect_true(!is.null(result))
})


test_that("mysterycall_acceptance_waffle with flip=TRUE", {
  skip_if_not_installed("waffle")
  skip_if_not_installed("patchwork")

  acc_df <- data.frame(
    insurance_type = c("Medicaid", "Medicaid", "Blue Cross/Blue Shield", "Blue Cross/Blue Shield"),
    outcome        = c("Accepted", "Declined", "Accepted", "Declined"),
    n              = c(47L, 53L, 72L, 28L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_acceptance_waffle(acc_df, flip = TRUE, output_dir = NA)
  }))

  expect_invisible(result)
  expect_true(!is.null(result))
})


test_that("mysterycall_acceptance_waffle errors on invalid rows parameter", {
  skip_if_not_installed("waffle")
  skip_if_not_installed("patchwork")

  acc_df <- data.frame(
    insurance_type = c("Medicaid", "Medicaid", "Blue Cross/Blue Shield", "Blue Cross/Blue Shield"),
    outcome        = c("Accepted", "Declined", "Accepted", "Declined"),
    n              = c(47L, 53L, 72L, 28L),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(suppressWarnings({
      mysterycall_acceptance_waffle(acc_df, rows = 0L, output_dir = NA)
    })),
    "lower"
  )
})


test_that("mysterycall_acceptance_waffle errors on non-flag flip parameter", {
  skip_if_not_installed("waffle")
  skip_if_not_installed("patchwork")

  acc_df <- data.frame(
    insurance_type = c("Medicaid", "Medicaid", "Blue Cross/Blue Shield", "Blue Cross/Blue Shield"),
    outcome        = c("Accepted", "Declined", "Accepted", "Declined"),
    n              = c(47L, 53L, 72L, 28L),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(suppressWarnings({
      mysterycall_acceptance_waffle(acc_df, flip = "yes", output_dir = NA)
    })),
    "flag"
  )
})


test_that("bcbs_label default matches the package-canonical BCBS string (bug 50)", {
  # The canonical insurance string is "Blue Cross/Blue Shield" (no spaces);
  # a spaced default silently produced "No rows found" on canonical data.
  expect_equal(formals(mysterycall_acceptance_waffle)$bcbs_label,
               "Blue Cross/Blue Shield")
})
