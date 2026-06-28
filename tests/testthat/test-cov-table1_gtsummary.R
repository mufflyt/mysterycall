library(testthat)

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

test_that("mysterycall_table1_gtsummary returns gtsummary object with minimal inputs", {
  skip_if_not_installed("gtsummary")

  set.seed(1)
  df <- data.frame(
    gender = sample(c("Male", "Female"), 20, replace = TRUE),
    age    = sample(c("30-39", "40-49"), 20, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_table1_gtsummary(df, vars = c("gender", "age"))
  ))

  expect_s3_class(result, "tbl_summary")
  expect_s3_class(result, "gtsummary")
})

test_that("mysterycall_table1_gtsummary adds overall and p-values with strata_col", {
  skip_if_not_installed("gtsummary")

  set.seed(1)
  df <- data.frame(
    gender    = sample(c("Male", "Female"), 40, replace = TRUE),
    setting   = sample(c("Academic", "Private"), 40, replace = TRUE),
    insurance = rep(c("BCBS", "Medicaid"), each = 20L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_table1_gtsummary(
      df,
      vars       = c("gender", "setting"),
      strata_col = "insurance"
    )
  ))

  expect_s3_class(result, "tbl_summary")
  expect_true(!is.null(result$table_body))
})

test_that("mysterycall_table1_gtsummary respects overall_last parameter", {
  skip_if_not_installed("gtsummary")

  set.seed(1)
  df <- data.frame(
    gender    = sample(c("Male", "Female"), 40, replace = TRUE),
    insurance = rep(c("BCBS", "Medicaid"), each = 20L),
    stringsAsFactors = FALSE
  )

  result_first <- suppressMessages(suppressWarnings(
    mysterycall_table1_gtsummary(
      df,
      vars       = c("gender"),
      strata_col = "insurance",
      overall_last = FALSE
    )
  ))

  result_last <- suppressMessages(suppressWarnings(
    mysterycall_table1_gtsummary(
      df,
      vars       = c("gender"),
      strata_col = "insurance",
      overall_last = TRUE
    )
  ))

  expect_s3_class(result_first, "tbl_summary")
  expect_s3_class(result_last, "tbl_summary")
})

test_that("mysterycall_table1_gtsummary warns when strata_col in vars", {
  skip_if_not_installed("gtsummary")

  set.seed(1)
  df <- data.frame(
    gender    = sample(c("Male", "Female"), 20, replace = TRUE),
    insurance = sample(c("BCBS", "Medicaid"), 20, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- NULL
  suppressMessages(
    expect_warning(
      {
        result <- mysterycall_table1_gtsummary(
          df,
          vars       = c("gender", "insurance"),
          strata_col = "insurance"
        )
      },
      "appears in `vars`"
    )
  )

  expect_s3_class(result, "tbl_summary")
})

test_that("mysterycall_table1_gtsummary respects missing and percent parameters", {
  skip_if_not_installed("gtsummary")

  set.seed(1)
  df <- data.frame(
    gender = c("Male", "Female", NA, "Male"),
    age    = c("30-39", "40-49", "30-39", NA),
    stringsAsFactors = FALSE
  )

  result_ifany <- suppressMessages(suppressWarnings(
    mysterycall_table1_gtsummary(df, vars = c("gender", "age"), missing = "ifany")
  ))

  result_row <- suppressMessages(suppressWarnings(
    mysterycall_table1_gtsummary(df, vars = c("gender", "age"), percent = "row")
  ))

  expect_s3_class(result_ifany, "tbl_summary")
  expect_s3_class(result_row, "tbl_summary")
})

test_that("mysterycall_table1_gtsummary errors on invalid inputs", {
  skip_if_not_installed("gtsummary")

  # Not a data frame
  expect_error(
    mysterycall_table1_gtsummary(list(x = 1), vars = c("x")),
    "`data` must be a data frame"
  )

  # Empty vars
  expect_error(
    mysterycall_table1_gtsummary(data.frame(x = 1), vars = c()),
    "non-empty character vector"
  )

  # Missing variable
  expect_error(
    mysterycall_table1_gtsummary(data.frame(x = 1), vars = c("missing")),
    "not found in `data`"
  )

  # Invalid strata_col
  expect_error(
    mysterycall_table1_gtsummary(data.frame(x = 1), vars = c("x"), strata_col = "missing"),
    "not found in `data`"
  )
})

test_that("mysterycall_table1_gtsummary handles NA and edge cases", {
  skip_if_not_installed("gtsummary")

  # Data with NA values
  set.seed(1)
  df <- data.frame(
    x = c(1, 2, NA, 4),
    y = c("A", "B", "A", NA),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_table1_gtsummary(df, vars = c("x", "y"), missing = "always")
  ))

  expect_s3_class(result, "tbl_summary")

  # Small data frame
  small_df <- data.frame(z = c(1, 2))
  result_small <- suppressMessages(suppressWarnings(
    mysterycall_table1_gtsummary(small_df, vars = "z")
  ))

  expect_s3_class(result_small, "tbl_summary")
})
