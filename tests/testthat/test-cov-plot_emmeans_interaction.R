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

test_that("mysterycall_plot_emmeans_interaction returns ggplot with 2 specs + color", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  set.seed(221)
  mod <- suppressMessages(
    mysterycall_simple_poisson(COUNT_DF, outcome = "days", group = "insurance", use_profile_ci = FALSE)
  )

  # Add a second factor to enable interaction
  COUNT_DF_ext <- COUNT_DF
  COUNT_DF_ext$wave <- rep(c(1, 2), length.out = nrow(COUNT_DF_ext))
  mod_ext <- suppressMessages(
    mysterycall_simple_poisson(COUNT_DF_ext, outcome = "days", group = "insurance", use_profile_ci = FALSE)
  )

  result <- mysterycall_plot_emmeans_interaction(
    model = mod_ext$model,
    specs = c("insurance"),
    variable = "Days to appointment"
  )

  expect_s3_class(result, "ggplot")
  expect_s3_class(result, "gg")
})

test_that("mysterycall_plot_emmeans_interaction with use_color=TRUE returns colored ggplot", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  set.seed(221)
  COUNT_DF_ext <- COUNT_DF
  COUNT_DF_ext$wave <- rep(c(1, 2), length.out = nrow(COUNT_DF_ext))
  mod <- suppressMessages(
    mysterycall_simple_poisson(COUNT_DF_ext, outcome = "days", group = "insurance", use_profile_ci = FALSE)
  )

  result <- mysterycall_plot_emmeans_interaction(
    model = mod$model,
    specs = c("insurance"),
    variable = "Days",
    use_color = TRUE
  )

  expect_s3_class(result, "ggplot")
  expect_equal(result$labels$x, "insurance")
  expect_equal(result$labels$y, "Days")
})

test_that("mysterycall_plot_emmeans_interaction with use_color=FALSE returns grey ggplot", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  set.seed(221)
  COUNT_DF_ext <- COUNT_DF
  COUNT_DF_ext$wave <- rep(c(1, 2), length.out = nrow(COUNT_DF_ext))
  mod <- suppressMessages(
    mysterycall_simple_poisson(COUNT_DF_ext, outcome = "days", group = "insurance", use_profile_ci = FALSE)
  )

  result <- mysterycall_plot_emmeans_interaction(
    model = mod$model,
    specs = c("insurance"),
    variable = "Days",
    use_color = FALSE
  )

  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_plot_emmeans_interaction rejects non-character specs", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  set.seed(221)
  COUNT_DF_ext <- COUNT_DF
  COUNT_DF_ext$wave <- rep(c(1, 2), length.out = nrow(COUNT_DF_ext))
  mod <- suppressMessages(
    mysterycall_simple_poisson(COUNT_DF_ext, outcome = "days", group = "insurance", use_profile_ci = FALSE)
  )

  expect_error(
    mysterycall_plot_emmeans_interaction(
      model = mod$model,
      specs = c(1, 2),
      variable = "Days"
    ),
    "specs.*must be a character vector"
  )
})

test_that("mysterycall_plot_emmeans_interaction rejects empty specs", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  set.seed(221)
  COUNT_DF_ext <- COUNT_DF
  COUNT_DF_ext$wave <- rep(c(1, 2), length.out = nrow(COUNT_DF_ext))
  mod <- suppressMessages(
    mysterycall_simple_poisson(COUNT_DF_ext, outcome = "days", group = "insurance", use_profile_ci = FALSE)
  )

  expect_error(
    mysterycall_plot_emmeans_interaction(
      model = mod$model,
      specs = character(0),
      variable = "Days"
    ),
    "specs.*must be a character vector"
  )
})
