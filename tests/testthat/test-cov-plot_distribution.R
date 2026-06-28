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

# Happy path: valid numeric vector with explicit title and bins
test_that("mysterycall_plot_distribution returns named list of two ggplot objects", {
  set.seed(100)
  x <- rpois(100, 5)
  result <- mysterycall_plot_distribution(x, title = "Wait Days", bins = 20L)

  expect_type(result, "list")
  expect_named(result, c("raw", "sqrt_transformed"))
  expect_s3_class(result$raw, "ggplot")
  expect_s3_class(result$sqrt_transformed, "ggplot")
})

# Edge case: NA values should be removed before plotting
test_that("mysterycall_plot_distribution handles NA values", {
  set.seed(101)
  x <- c(rpois(50, 5), NA, NA, rpois(50, 5))
  result <- mysterycall_plot_distribution(x, title = "With NAs", bins = 25L)

  expect_type(result, "list")
  expect_length(result, 2)
  expect_s3_class(result$raw, "ggplot")
  expect_s3_class(result$sqrt_transformed, "ggplot")
})

# Edge case: single value vector
test_that("mysterycall_plot_distribution works with minimal data", {
  result <- mysterycall_plot_distribution(c(5, 10, 15), title = "Minimal", bins = 2L)

  expect_type(result, "list")
  expect_named(result, c("raw", "sqrt_transformed"))
  expect_s3_class(result$raw, "ggplot")
  expect_s3_class(result$sqrt_transformed, "ggplot")
})

# Default title parameter: NULL uses deparse(substitute(x))
test_that("mysterycall_plot_distribution uses deparse for NULL title", {
  set.seed(102)
  my_wait_days <- rpois(50, 8)
  result <- mysterycall_plot_distribution(my_wait_days)

  expect_type(result, "list")
  expect_length(result, 2)
  expect_s3_class(result$raw, "ggplot")
  expect_s3_class(result$sqrt_transformed, "ggplot")
})

# Bad input: non-numeric x should error
test_that("mysterycall_plot_distribution errors on non-numeric x", {
  expect_error(
    mysterycall_plot_distribution(c("a", "b", "c"), title = "Strings"),
    "`x` must be a numeric vector"
  )
})
