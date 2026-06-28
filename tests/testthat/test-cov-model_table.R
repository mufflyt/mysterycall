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

test_that("mysterycall_model_table happy path with poisson model", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    wait_days = rpois(40, lambda = 18),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    physician = rep(paste0("Dr_", 1:8), each = 5),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait_days", "insurance", "physician")
  ))

  output <- suppressWarnings(suppressMessages(
    mysterycall_model_table(result)
  ))

  expect_no_error(
    suppressWarnings(suppressMessages(
      mysterycall_model_table(result)
    ))
  )
  expect_true(is.data.frame(output))
  expect_true(nrow(output) > 0)
})

test_that("mysterycall_model_table returns correct output type and structure", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    wait_days = rpois(40, lambda = 18),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    physician = rep(paste0("Dr_", 1:8), each = 5),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait_days", "insurance", "physician")
  ))

  output <- suppressWarnings(suppressMessages(
    mysterycall_model_table(result)
  ))

  # Output is a data frame
  expect_s3_class(output, "data.frame")

  # Has three columns with expected names
  expect_equal(ncol(output), 3L)
  expect_equal(colnames(output), c("Term", "IRR (95% CI)", "p-value"))

  # Columns are character
  expect_true(is.character(output[[1]]))
  expect_true(is.character(output[[2]]))
  expect_true(is.character(output[[3]]))

  # No intercept by default
  expect_false(any(output[[1]] == "(Intercept)"))
})

test_that("mysterycall_model_table with include_intercept=TRUE", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    wait_days = rpois(40, lambda = 18),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    physician = rep(paste0("Dr_", 1:8), each = 5),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait_days", "insurance", "physician")
  ))

  output <- suppressWarnings(suppressMessages(
    mysterycall_model_table(result, include_intercept = TRUE)
  ))

  # Should include intercept row
  expect_true(any(output[[1]] == "(Intercept)"))
})

test_that("mysterycall_model_table with custom digits parameter", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    wait_days = rpois(40, lambda = 18),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    physician = rep(paste0("Dr_", 1:8), each = 5),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait_days", "insurance", "physician")
  ))

  # With 3 digits
  output_3 <- suppressWarnings(suppressMessages(
    mysterycall_model_table(result, digits = 3L)
  ))

  # With 0 digits
  output_0 <- suppressWarnings(suppressMessages(
    mysterycall_model_table(result, digits = 0L)
  ))

  # Both should return data frames
  expect_s3_class(output_3, "data.frame")
  expect_s3_class(output_0, "data.frame")

  # Output_3 should have more decimal places in IRR column
  expect_true(nchar(output_3[[2]][1]) > nchar(output_0[[2]][1]))
})

test_that("mysterycall_model_table with custom column names", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    wait_days = rpois(40, lambda = 18),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    physician = rep(paste0("Dr_", 1:8), each = 5),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait_days", "insurance", "physician")
  ))

  output <- suppressWarnings(suppressMessages(
    mysterycall_model_table(
      result,
      term_col = "Variable",
      irr_col = "Hazard Ratio",
      p_col = "Significance"
    )
  ))

  expect_equal(colnames(output), c("Variable", "Hazard Ratio", "Significance"))
})

test_that("mysterycall_model_table errors on invalid x class", {
  skip_if_not_installed("lme4")

  # Pass a list that is not a model object
  invalid_result <- list(irr_table = data.frame())

  expect_error(
    mysterycall_model_table(invalid_result),
    "`x` must be a `mysterycall_poisson_model` or `mysterycall_nb_model` object."
  )

  # Pass a data frame instead
  expect_error(
    mysterycall_model_table(data.frame(x = 1:10)),
    "`x` must be a `mysterycall_poisson_model` or `mysterycall_nb_model` object."
  )
})

test_that("mysterycall_model_table errors on invalid digits parameter", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    wait_days = rpois(40, lambda = 18),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    physician = rep(paste0("Dr_", 1:8), each = 5),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait_days", "insurance", "physician")
  ))

  # Negative digits
  expect_error(
    mysterycall_model_table(result, digits = -1),
    "`digits` must be a non-negative integer scalar."
  )

  # Non-numeric digits
  expect_error(
    mysterycall_model_table(result, digits = "3"),
    "`digits` must be a non-negative integer scalar."
  )

  # Vector of digits
  expect_error(
    mysterycall_model_table(result, digits = c(2, 3)),
    "`digits` must be a non-negative integer scalar."
  )
})

test_that("mysterycall_model_table with nb_model", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    wait_days = rpois(40, lambda = 18),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    physician = rep(paste0("Dr_", 1:8), each = 5),
    stringsAsFactors = FALSE
  )

  # Build a negative binomial model
  result <- suppressWarnings(suppressMessages(
    mysterycall_nb_model(df, "wait_days", "insurance", "physician")
  ))

  output <- suppressWarnings(suppressMessages(
    mysterycall_model_table(result)
  ))

  expect_s3_class(output, "data.frame")
  expect_equal(ncol(output), 3L)
})

test_that("mysterycall_model_table formatting is correct", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    wait_days = rpois(40, lambda = 18),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    physician = rep(paste0("Dr_", 1:8), each = 5),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait_days", "insurance", "physician")
  ))

  output <- suppressWarnings(suppressMessages(
    mysterycall_model_table(result, digits = 2L)
  ))

  # Check IRR column format: should be "X.XX (X.XX-X.XX)"
  irr_col <- output[[2]][1]
  expect_match(irr_col, "^[0-9.]+\\s\\([0-9.]+-[0-9.]+\\)$")

  # Check p-value column format: should be numeric-like or "<0.001"
  p_col <- output[[3]][1]
  expect_true(
    grepl("^<0\\.001$|^0\\.[0-9]{3}$", p_col)
  )
})
