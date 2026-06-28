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

# Build upstream model for testing
set.seed(219)
mod <- suppressMessages(glm(days ~ insurance, family = poisson(), data = COUNT_DF))

# Build model with interaction term for sjPlot tests
set.seed(219)
COUNT_DF_INTERACTION <- COUNT_DF
COUNT_DF_INTERACTION$location <- rep(c("Urban","Rural"), 40L)
mod_interaction <- suppressMessages(glm(days ~ insurance * location, family = poisson(), data = COUNT_DF_INTERACTION))

# Tests for mysterycall_plot_effect
test_that("mysterycall_plot_effect returns ggplot with valid model and term", {
  skip_if_not_installed("effects")
  skip_if_not_installed("ggplot2")

  p <- suppressMessages(suppressWarnings(mysterycall_plot_effect(mod, "insurance")))
  expect_s3_class(p, "ggplot")
})

test_that("mysterycall_plot_effect defaults x_label to term name", {
  skip_if_not_installed("effects")
  skip_if_not_installed("ggplot2")

  p <- suppressMessages(suppressWarnings(mysterycall_plot_effect(mod, "insurance")))
  expect_equal(p$labels$x, "insurance")
})

test_that("mysterycall_plot_effect defaults y_label based on type argument", {
  skip_if_not_installed("effects")
  skip_if_not_installed("ggplot2")

  p_response <- suppressMessages(suppressWarnings(
    mysterycall_plot_effect(mod, "insurance", type = "response")
  ))
  expect_equal(p_response$labels$y, "Predicted response")

  p_link <- suppressMessages(suppressWarnings(
    mysterycall_plot_effect(mod, "insurance", type = "link")
  ))
  expect_equal(p_link$labels$y, "Linear predictor")
})

test_that("mysterycall_plot_effect respects custom x_label and y_label", {
  skip_if_not_installed("effects")
  skip_if_not_installed("ggplot2")

  p <- suppressMessages(suppressWarnings(
    mysterycall_plot_effect(mod, "insurance", x_label = "Insurance Type", y_label = "Expected Count")
  ))
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Insurance Type")
  expect_equal(p$labels$y, "Expected Count")
})

test_that("mysterycall_plot_effect errors when term is not single character string", {
  skip_if_not_installed("effects")
  skip_if_not_installed("ggplot2")

  expect_error(mysterycall_plot_effect(mod, 123), "`term` must be a single character string")
  expect_error(mysterycall_plot_effect(mod, c("a", "b")), "`term` must be a single character string")
  expect_error(mysterycall_plot_effect(mod, NULL), "`term` must be a single character string")
})

test_that("mysterycall_plot_effect produces ribbon and line geom layers", {
  skip_if_not_installed("effects")
  skip_if_not_installed("ggplot2")

  p <- suppressMessages(suppressWarnings(mysterycall_plot_effect(mod, "insurance")))
  layer_classes <- sapply(p$layers, function(x) class(x$geom)[1])
  expect_true("GeomRibbon" %in% layer_classes)
  expect_true("GeomLine" %in% layer_classes)
})

# Tests for mysterycall_plot_sjplot_interaction
test_that("mysterycall_plot_sjplot_interaction returns ggplot with valid interaction model", {
  skip_if_not_installed("sjPlot")

  p <- suppressMessages(suppressWarnings(
    mysterycall_plot_sjplot_interaction(mod_interaction, "insurance")
  ))
  expect_s3_class(p, "ggplot")
})

test_that("mysterycall_plot_sjplot_interaction accepts character vector of terms", {
  skip_if_not_installed("sjPlot")

  p <- suppressMessages(suppressWarnings(
    mysterycall_plot_sjplot_interaction(mod_interaction, c("insurance"))
  ))
  expect_s3_class(p, "ggplot")
})

test_that("mysterycall_plot_sjplot_interaction accepts optional title parameter", {
  skip_if_not_installed("sjPlot")

  p <- suppressMessages(suppressWarnings(
    mysterycall_plot_sjplot_interaction(mod_interaction, "insurance", title = "Interaction Plot")
  ))
  expect_s3_class(p, "ggplot")
})

test_that("mysterycall_plot_sjplot_interaction errors on empty terms vector", {
  skip_if_not_installed("sjPlot")

  expect_error(
    mysterycall_plot_sjplot_interaction(mod_interaction, c()),
    "`terms` must be a non-empty character vector"
  )
})

test_that("mysterycall_plot_sjplot_interaction errors when terms is non-character", {
  skip_if_not_installed("sjPlot")

  expect_error(
    mysterycall_plot_sjplot_interaction(mod_interaction, 123),
    "`terms` must be a non-empty character vector"
  )
  expect_error(
    mysterycall_plot_sjplot_interaction(mod_interaction, NULL),
    "`terms` must be a non-empty character vector"
  )
})
