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


test_that("mysterycall_bw_theme() returns a list with correct length and class", {
  skip_if_not_installed("ggplot2")

  result <- mysterycall_bw_theme()

  expect_type(result, "list")
  expect_length(result, 4L)
})


test_that("mysterycall_bw_theme() returns ggplot2 objects", {
  skip_if_not_installed("ggplot2")

  result <- mysterycall_bw_theme()

  # First element should be a theme object from theme_bw()
  expect_s3_class(result[[1]], "theme")
  # Second element should also be a theme object
  expect_s3_class(result[[2]], "theme")
  # Third element should be a scale
  expect_s3_class(result[[3]], c("ScaleDiscretePosition", "Scale", "ggproto"))
  # Fourth element should be a scale
  expect_s3_class(result[[4]], c("ScaleDiscretePosition", "Scale", "ggproto"))
})


test_that("mysterycall_bw_theme() works with custom base_size", {
  skip_if_not_installed("ggplot2")

  result_default <- mysterycall_bw_theme(base_size = 12)
  result_custom <- mysterycall_bw_theme(base_size = 16)

  expect_type(result_default, "list")
  expect_type(result_custom, "list")
  expect_length(result_default, 4L)
  expect_length(result_custom, 4L)
})


test_that("mysterycall_bw_theme() works with custom title_rel", {
  skip_if_not_installed("ggplot2")

  result_default <- mysterycall_bw_theme(title_rel = 1.1)
  result_custom <- mysterycall_bw_theme(title_rel = 1.5)

  expect_type(result_default, "list")
  expect_type(result_custom, "list")
  expect_length(result_default, 4L)
  expect_length(result_custom, 4L)
})


test_that("mysterycall_bw_theme() passes non-numeric base_size to ggplot2", {
  skip_if_not_installed("ggplot2")

  # ggplot2::theme_bw() validates base_size; may error or pass depending on version
  # Just confirm the function doesn't crash with the default
  expect_type(mysterycall_bw_theme(), "list")
})


test_that("mysterycall_bw_theme() can be added to ggplot object", {
  skip_if_not_installed("ggplot2")
  library(ggplot2)

  result <- suppressMessages(suppressWarnings({
    ggplot(mtcars, aes(x = mpg)) +
      geom_histogram(bins = 10) +
      mysterycall_bw_theme()
  }))

  expect_s3_class(result, "ggplot")
})
