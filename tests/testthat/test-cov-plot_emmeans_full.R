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

test_that("mysterycall_plot_emmeans_full: happy path with single spec as character", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  m <- lm(mpg ~ factor(cyl), data = mtcars)
  result <- mysterycall_plot_emmeans_full(
    model    = m,
    specs    = "cyl",
    variable = "cylinder"
  )

  expect_type(result, "list")
  expect_named(result, c("data", "plot"))
  expect_s3_class(result$data, "data.frame")
  expect_s3_class(result$plot, "ggplot")
  expect_true(nrow(result$data) >= 1L)
})

test_that("mysterycall_plot_emmeans_full: with two specs for grouping", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  mt <- mtcars
  mt$cyl_f <- factor(mt$cyl)
  mt$am_f <- factor(mt$am)
  m <- lm(mpg ~ cyl_f * am_f, data = mt)

  result <- mysterycall_plot_emmeans_full(
    model    = m,
    specs    = c("cyl_f", "am_f"),
    variable = "cyl_f",
    use_color = TRUE
  )

  expect_type(result, "list")
  expect_named(result, c("data", "plot"))
  expect_s3_class(result$plot, "ggplot")
})

test_that("mysterycall_plot_emmeans_full: greyscale mode use_color=FALSE", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  mt <- mtcars
  mt$cyl_f <- factor(mt$cyl)
  mt$am_f <- factor(mt$am)
  m <- lm(mpg ~ cyl_f * am_f, data = mt)

  result <- mysterycall_plot_emmeans_full(
    model    = m,
    specs    = c("cyl_f", "am_f"),
    variable = "cyl_f",
    use_color = FALSE
  )

  expect_type(result, "list")
  expect_s3_class(result$plot, "ggplot")
})

test_that("mysterycall_plot_emmeans_full: group_col override parameter", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  mt <- mtcars
  mt$cyl_f <- factor(mt$cyl, labels = c("4-cyl", "6-cyl", "8-cyl"))
  mt$am_f <- factor(mt$am, labels = c("Auto", "Manual"))
  m <- lm(mpg ~ cyl_f + am_f, data = mt)

  result <- mysterycall_plot_emmeans_full(
    model    = m,
    specs    = c("cyl_f", "am_f"),
    variable = "cylinder",
    group_col = "am_f",
    use_color = TRUE
  )

  expect_type(result, "list")
  expect_s3_class(result$plot, "ggplot")
  expect_true(nrow(result$data) >= 3L)
})

test_that("mysterycall_plot_emmeans_full: type='link' uses log scale", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  m <- lm(mpg ~ factor(cyl) + wt, data = mtcars)
  result <- mysterycall_plot_emmeans_full(
    model    = m,
    specs    = "cyl",
    variable = "cyl",
    type     = "link"
  )

  expect_type(result, "list")
  expect_s3_class(result$plot, "ggplot")
})

test_that("mysterycall_plot_emmeans_full: variable must be character", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  m <- lm(mpg ~ factor(cyl), data = mtcars)

  expect_error(
    mysterycall_plot_emmeans_full(
      model    = m,
      specs    = "cyl",
      variable = 123
    ),
    "must be a single character string"
  )
})

test_that("mysterycall_plot_emmeans_full: variable must have length 1", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  m <- lm(mpg ~ factor(cyl), data = mtcars)

  expect_error(
    mysterycall_plot_emmeans_full(
      model    = m,
      specs    = "cyl",
      variable = c("cyl", "wt")
    ),
    "must be a single character string"
  )
})
