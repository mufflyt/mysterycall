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


test_that("mysterycall_plot_source_venn: happy path with minimal valid inputs", {
  skip_if_not_installed("ggplot2")

  d <- list(
    npis  = as.character(1:100),
    nppes = as.character(1:70),
    pc    = as.character(30:90),
    dac   = as.character(50:100)
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_plot_source_venn(d)
  }))

  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_source_venn: returns ggplot object", {
  skip_if_not_installed("ggplot2")

  d <- list(
    npis  = c("A", "B", "C", "D", "E"),
    nppes = c("A", "B", "C"),
    pc    = c("B", "C", "D"),
    dac   = c("C", "D", "E")
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_plot_source_venn(d, title = "Test Venn")
  }))

  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_source_venn: error on non-list, non-character input", {
  skip_if_not_installed("ggplot2")

  expect_error(
    suppressMessages(suppressWarnings({
      mysterycall_plot_source_venn(12345)
    })),
    "`data_or_path` must be a named list or a path to an .rds file."
  )
})


test_that("mysterycall_plot_source_venn: error on missing required column", {
  skip_if_not_installed("ggplot2")

  d <- list(
    npis  = c("A", "B", "C"),
    nppes = c("A", "B")
  )

  expect_error(
    suppressMessages(suppressWarnings({
      mysterycall_plot_source_venn(d)
    })),
    "Key 'pc' not found in data"
  )
})


test_that("mysterycall_plot_source_venn: error when source_short not length 3", {
  skip_if_not_installed("ggplot2")

  d <- list(
    npis  = c("A", "B", "C"),
    nppes = c("A", "B"),
    pc    = c("B", "C"),
    dac   = c("C")
  )

  expect_error(
    suppressMessages(suppressWarnings({
      mysterycall_plot_source_venn(d, source_short = c("S1", "S2"))
    })),
    "`source_short` must be a character vector of length 3."
  )
})


test_that("mysterycall_plot_source_venn: error when fills not length 3", {
  skip_if_not_installed("ggplot2")

  d <- list(
    npis  = c("A", "B", "C"),
    nppes = c("A", "B"),
    pc    = c("B", "C"),
    dac   = c("C")
  )

  expect_error(
    suppressMessages(suppressWarnings({
      mysterycall_plot_source_venn(d, fills = c("#FF0000", "#00FF00"))
    })),
    "`fills` must be a character vector of length 3."
  )
})


test_that("mysterycall_plot_source_venn: works with NULL universe_col", {
  skip_if_not_installed("ggplot2")

  d <- list(
    nppes = c("A", "B", "C"),
    pc    = c("B", "C", "D"),
    dac   = c("C", "D", "E")
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_plot_source_venn(d, universe_col = NULL)
  }))

  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_source_venn: works with custom column names", {
  skip_if_not_installed("ggplot2")

  d <- list(
    all_ids = c("A", "B", "C", "D", "E"),
    source1 = c("A", "B", "C"),
    source2 = c("B", "C", "D"),
    source3 = c("C", "D", "E")
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_plot_source_venn(
      d,
      A_col = "source1",
      B_col = "source2",
      C_col = "source3",
      universe_col = "all_ids"
    )
  }))

  expect_s3_class(result, "ggplot")
})
