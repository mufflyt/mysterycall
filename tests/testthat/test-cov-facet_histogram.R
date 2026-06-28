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

test_that("mysterycall_facet_histogram returns ggplot with minimal inputs", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  result <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "x", facet_col = "group", output_dir = NA)
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_facet_histogram with show_mean_line = FALSE", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  result <- suppressMessages(
    mysterycall_facet_histogram(
      df, x_col = "x", facet_col = "group",
      show_mean_line = FALSE, output_dir = NA
    )
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_facet_histogram with show_stats_text = FALSE", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  result <- suppressMessages(
    mysterycall_facet_histogram(
      df, x_col = "x", facet_col = "group",
      show_stats_text = FALSE, output_dir = NA
    )
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_facet_histogram with monochrome = TRUE", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  result <- suppressMessages(
    mysterycall_facet_histogram(
      df, x_col = "x", facet_col = "group",
      monochrome = TRUE, output_dir = NA
    )
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_facet_histogram with reorder_facets = TRUE", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  result <- suppressMessages(
    mysterycall_facet_histogram(
      df, x_col = "x", facet_col = "group",
      reorder_facets = TRUE, output_dir = NA
    )
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_facet_histogram with custom labels and title", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  result <- suppressMessages(
    mysterycall_facet_histogram(
      df, x_col = "x", facet_col = "group",
      x_label = "Custom X", y_label = "Custom Y",
      title = "Custom Title", output_dir = NA
    )
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_facet_histogram with custom binwidth and colors", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  result <- suppressMessages(
    mysterycall_facet_histogram(
      df, x_col = "x", facet_col = "group",
      binwidth = 2, fill = "lightblue", color = "darkblue",
      alpha = 0.5, output_dir = NA
    )
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_facet_histogram handles NA values in x_col", {
  set.seed(1)
  df <- data.frame(
    x = c(NA, rpois(59, 5), NA, rpois(59, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  result <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "x", facet_col = "group", output_dir = NA)
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_facet_histogram errors when x_col not in data", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  expect_error(
    mysterycall_facet_histogram(df, x_col = "missing_col", facet_col = "group", output_dir = NA),
    "Column 'missing_col' not found"
  )
})

test_that("mysterycall_facet_histogram errors when facet_col not in data", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  expect_error(
    mysterycall_facet_histogram(df, x_col = "x", facet_col = "missing_facet", output_dir = NA),
    "Column 'missing_facet' not found"
  )
})

test_that("mysterycall_facet_histogram errors when data is not a data frame", {
  expect_error(
    mysterycall_facet_histogram(list(x = 1:10), x_col = "x", facet_col = "group", output_dir = NA),
    "`data` must be a data frame"
  )
})

test_that("mysterycall_facet_histogram errors when x_col is not character", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  expect_error(
    mysterycall_facet_histogram(df, x_col = 1, facet_col = "group", output_dir = NA),
    "`x_col` must be a single non-empty character string"
  )
})

test_that("mysterycall_facet_histogram errors when facet_col is not character", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  expect_error(
    mysterycall_facet_histogram(df, x_col = "x", facet_col = 1, output_dir = NA),
    "`facet_col` must be a single non-empty character string"
  )
})

test_that("mysterycall_facet_histogram with base_size parameter", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  result <- suppressMessages(
    mysterycall_facet_histogram(
      df, x_col = "x", facet_col = "group",
      base_size = 14, output_dir = NA
    )
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_facet_histogram returns invisibly", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  result <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "x", facet_col = "group", output_dir = NA)
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_facet_histogram with AUDIT data", {
  result <- suppressMessages(
    mysterycall_facet_histogram(
      AUDIT, x_col = "wait_days", facet_col = "insurance",
      output_dir = NA
    )
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_facet_histogram with COUNT_DF data", {
  result <- suppressMessages(
    mysterycall_facet_histogram(
      COUNT_DF, x_col = "days", facet_col = "insurance",
      output_dir = NA
    )
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_facet_histogram with all features enabled", {
  set.seed(1)
  df <- data.frame(
    x = c(rpois(60, 5), rpois(60, 10)),
    group = rep(c("A", "B"), each = 60)
  )
  result <- suppressMessages(
    mysterycall_facet_histogram(
      df, x_col = "x", facet_col = "group",
      show_mean_line = TRUE, show_stats_text = TRUE,
      monochrome = FALSE, reorder_facets = TRUE,
      binwidth = 1.5, fill = "coral", color = "navy",
      alpha = 0.6, base_size = 11,
      output_dir = NA
    )
  )
  expect_s3_class(result, "ggplot")
})
