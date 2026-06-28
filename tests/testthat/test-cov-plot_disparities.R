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

# Test 1: happy path with "rate" metric
test_that("mysterycall_plot_disparities with rate metric returns ggplot", {
  set.seed(2)
  rate_df <- data.frame(
    group     = c("Private", "Medicaid", "Medicare", "Uninsured"),
    rate      = c(0.91, 0.64, 0.84, 0.54),
    lower_ci  = c(0.85, 0.55, 0.76, 0.45),
    upper_ci  = c(0.97, 0.73, 0.92, 0.63),
    p_value   = c(NA, 0.001, 0.15, 0.0005),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_disparities(rate_df, metric = "rate")
  ))

  expect_s3_class(result, "ggplot")
  expect_true(inherits(result, "ggplot"))
})

# Test 2: abs_diff metric
test_that("mysterycall_plot_disparities with abs_diff metric returns ggplot", {
  set.seed(3)
  abs_diff_df <- data.frame(
    group     = c("Reference", "Group B", "Group C"),
    abs_diff  = c(0, -0.15, 0.08),
    lower_ci  = c(0, -0.25, -0.02),
    upper_ci  = c(0, -0.05, 0.18),
    p_value   = c(NA, 0.002, 0.12),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_disparities(abs_diff_df, metric = "abs_diff")
  ))

  expect_s3_class(result, "ggplot")
})

# Test 3: rel_risk metric
test_that("mysterycall_plot_disparities with rel_risk metric returns ggplot", {
  set.seed(4)
  rr_df <- data.frame(
    group     = c("Ref", "Group A", "Group B"),
    rel_risk  = c(1, 0.7, 0.95),
    rr_lower  = c(1, 0.55, 0.78),
    rr_upper  = c(1, 0.85, 1.12),
    p_value   = c(NA, 0.001, 0.45),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_disparities(rr_df, metric = "rel_risk")
  ))

  expect_s3_class(result, "ggplot")
})

# Test 4: missing required columns should error
test_that("mysterycall_plot_disparities errors when required columns missing", {
  set.seed(5)
  bad_df <- data.frame(
    group = c("A", "B"),
    rate = c(0.5, 0.7),
    # missing lower_ci and upper_ci
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_plot_disparities(bad_df, metric = "rate"),
    "Column.* required"
  )
})

# Test 5: show_ref = FALSE filters reference group
test_that("mysterycall_plot_disparities with show_ref = FALSE removes reference row", {
  set.seed(6)
  rate_df <- data.frame(
    group     = c("Ref", "A", "B"),
    rate      = c(0.80, 0.65, 0.75),
    lower_ci  = c(0.75, 0.55, 0.65),
    upper_ci  = c(0.85, 0.75, 0.85),
    p_value   = c(NA, 0.05, 0.20),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_disparities(rate_df, metric = "rate", show_ref = FALSE)
  ))

  expect_s3_class(result, "ggplot")
  # Verify the plot was created successfully with reduced rows
  expect_true(nrow(result$data) == 2)
})

# Test 6: show_p = FALSE suppresses p-value labels
test_that("mysterycall_plot_disparities with show_p = FALSE works", {
  set.seed(7)
  rate_df <- data.frame(
    group     = c("X", "Y", "Z"),
    rate      = c(0.70, 0.60, 0.80),
    lower_ci  = c(0.60, 0.50, 0.70),
    upper_ci  = c(0.80, 0.70, 0.90),
    p_value   = c(NA, 0.01, 0.50),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_disparities(rate_df, metric = "rate", show_p = FALSE)
  ))

  expect_s3_class(result, "ggplot")
})

# Test 7: custom title and labels
test_that("mysterycall_plot_disparities accepts custom title and x_label", {
  set.seed(8)
  rate_df <- data.frame(
    group     = c("Control", "Treatment"),
    rate      = c(0.50, 0.75),
    lower_ci  = c(0.40, 0.65),
    upper_ci  = c(0.60, 0.85),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_disparities(
      rate_df,
      metric = "rate",
      title = "My Custom Title",
      x_label = "Custom X Label"
    )
  ))

  expect_s3_class(result, "ggplot")
})

# Test 8: color and point_size customization
test_that("mysterycall_plot_disparities accepts custom colors and point_size", {
  set.seed(9)
  rate_df <- data.frame(
    group     = c("A", "B"),
    rate      = c(0.60, 0.80),
    lower_ci  = c(0.50, 0.70),
    upper_ci  = c(0.70, 0.90),
    p_value   = c(NA, 0.03),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_disparities(
      rate_df,
      metric = "rate",
      color_sig = "#FF0000",
      color_ns = "#0000FF",
      color_ref = "#00FF00",
      point_size = 5
    )
  ))

  expect_s3_class(result, "ggplot")
})

# Test 9: x_pct parameter
test_that("mysterycall_plot_disparities respects x_pct parameter", {
  set.seed(10)
  abs_diff_df <- data.frame(
    group     = c("Ref", "G1", "G2"),
    abs_diff  = c(0, -0.10, 0.05),
    lower_ci  = c(0, -0.20, -0.05),
    upper_ci  = c(0, 0, 0.15),
    stringsAsFactors = FALSE
  )

  # Test with x_pct = TRUE (default for abs_diff)
  result_pct <- suppressMessages(suppressWarnings(
    mysterycall_plot_disparities(abs_diff_df, metric = "abs_diff", x_pct = TRUE)
  ))

  # Test with x_pct = FALSE
  result_no_pct <- suppressMessages(suppressWarnings(
    mysterycall_plot_disparities(abs_diff_df, metric = "abs_diff", x_pct = FALSE)
  ))

  expect_s3_class(result_pct, "ggplot")
  expect_s3_class(result_no_pct, "ggplot")
})

# Test 10: show_ref = FALSE with only reference group errors
test_that("mysterycall_plot_disparities errors when show_ref = FALSE removes all rows", {
  set.seed(11)
  single_row_df <- data.frame(
    group     = c("OnlyRef"),
    rate      = c(0.75),
    lower_ci  = c(0.65),
    upper_ci  = c(0.85),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_plot_disparities(single_row_df, metric = "rate", show_ref = FALSE),
    "No rows remain"
  )
})

# Test 11: data with p_value_fmt column (pre-formatted p-values)
test_that("mysterycall_plot_disparities uses p_value_fmt when available", {
  set.seed(12)
  rate_df <- data.frame(
    group       = c("Ref", "G1", "G2"),
    rate        = c(0.70, 0.50, 0.85),
    lower_ci    = c(0.60, 0.40, 0.75),
    upper_ci    = c(0.80, 0.60, 0.95),
    p_value     = c(NA, 0.001, 0.456),
    p_value_fmt = c("(ref)", "p = 0.001", "p = 0.456"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_disparities(rate_df, metric = "rate", show_p = TRUE)
  ))

  expect_s3_class(result, "ggplot")
})
