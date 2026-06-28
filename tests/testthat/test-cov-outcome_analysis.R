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

# ============================================================================
# Tests for mysterycall_wait_time_summary
# ============================================================================

test_that("wait_time_summary: happy path, no grouping returns correct structure", {
  res <- suppressWarnings(mysterycall_wait_time_summary(AUDIT))

  expect_type(res, "list")
  expect_named(res, c("summary", "test", "p_value", "test_name", "interpretation"))
  expect_s3_class(res$summary, "data.frame")
  expect_equal(nrow(res$summary), 1L)
  expect_named(res$summary, c("n", "n_missing", "mean", "sd", "median", "q1", "q3", "min", "max"))
  expect_equal(res$test, NULL)
  expect_true(is.na(res$p_value))
  expect_equal(res$test_name, "none")
  expect_true(is.character(res$interpretation) && nchar(res$interpretation) > 0)
})

test_that("wait_time_summary: grouped (2 groups) runs Wilcoxon test", {
  res <- suppressWarnings(mysterycall_wait_time_summary(AUDIT, group_by = "insurance"))

  expect_type(res, "list")
  expect_s3_class(res$summary, "data.frame")
  expect_equal(nrow(res$summary), 2L)
  expect_true("insurance" %in% names(res$summary))
  expect_equal(res$test_name, "Wilcoxon rank-sum (Mann-Whitney U)")
  expect_true(is.numeric(res$p_value) && !is.na(res$p_value))
  expect_true(!is.null(res$test))
  expect_s3_class(res$test, "htest")
})

test_that("wait_time_summary: grouped (3+ groups) runs Kruskal-Wallis test", {
  test_df <- rbind(AUDIT, AUDIT, AUDIT)
  test_df$insurance <- c(rep("Medicaid", 4L), rep("BCBS", 4L), rep("Other", 4L))

  res <- suppressWarnings(mysterycall_wait_time_summary(test_df, group_by = "insurance"))

  expect_type(res, "list")
  expect_s3_class(res$summary, "data.frame")
  expect_equal(nrow(res$summary), 3L)
  expect_equal(res$test_name, "Kruskal-Wallis")
  expect_true(!is.null(res$test))
  expect_s3_class(res$test, "htest")
})

test_that("wait_time_summary: edge case with NA values in wait_days", {
  test_df <- AUDIT
  test_df$wait_days[2] <- NA

  res <- suppressWarnings(mysterycall_wait_time_summary(test_df))

  expect_equal(res$summary$n_missing, 1L)
  expect_equal(res$summary$n, 3L)
  expect_true(is.numeric(res$summary$mean) && !is.na(res$summary$mean))
})

test_that("wait_time_summary: bad input - non-numeric wait column throws error", {
  expect_error(
    mysterycall_wait_time_summary(AUDIT, wait_col = "insurance"),
    "must be a numeric column"
  )
})

test_that("wait_time_summary: bad input - conf_level out of bounds throws error", {
  expect_error(
    mysterycall_wait_time_summary(AUDIT, conf_level = 1.5),
    "conf_level"
  )
})

test_that("wait_time_summary: bad input - missing wait_col throws error", {
  expect_error(
    mysterycall_wait_time_summary(AUDIT, wait_col = "nonexistent_column"),
    "nonexistent_column"
  )
})

# ============================================================================
# Tests for mysterycall_acceptance_rate
# ============================================================================

test_that("acceptance_rate: happy path, no grouping returns correct structure", {
  res <- suppressWarnings(mysterycall_acceptance_rate(AUDIT))

  expect_type(res, "list")
  expect_named(res, c("summary", "test", "p_value", "test_name", "interpretation"))
  expect_s3_class(res$summary, "data.frame")
  expect_equal(nrow(res$summary), 1L)
  expect_named(res$summary, c("n_total", "n_missing", "n_accepted", "n_rejected", "rate", "ci_lower", "ci_upper"))
  expect_true(res$summary$rate >= 0 && res$summary$rate <= 1)
  expect_equal(res$test, NULL)
  expect_true(is.na(res$p_value))
  expect_equal(res$test_name, "none")
})

test_that("acceptance_rate: grouped (2 groups) runs chi-square or Fisher test", {
  # Create larger dataset to avoid small cells triggering Fisher's exact
  test_df <- rbind(
    AUDIT,
    data.frame(
      npi = c("1111111111", "1111111111", "2222222222", "2222222222"),
      insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS"),
      offered = c(TRUE, TRUE, FALSE, TRUE),
      contact_office = c(TRUE, TRUE, TRUE, FALSE),
      wait_days = c(5L, 12L, 3L, 7L),
      business_days_until_appointment = c(5L, 12L, 3L, 7L),
      caller_id = c("C", "C", "D", "D"),
      wave = c(1L, 1L, 2L, 2L),
      specialty = c("OB/GYN", "OB/GYN", "OB/GYN", "OB/GYN"),
      phone = c("3035550101", "3035550101", "7205550201", "7205550201"),
      physician_information = c("Brown, Bob", "Brown, Bob", "Green, Gina", "Green, Gina"),
      reason_for_exclusions = rep("Able to contact", 4L),
      stringsAsFactors = FALSE
    )
  )

  res <- suppressWarnings(mysterycall_acceptance_rate(test_df, group_by = "insurance"))

  expect_type(res, "list")
  expect_s3_class(res$summary, "data.frame")
  expect_equal(nrow(res$summary), 2L)
  expect_true("insurance" %in% names(res$summary))
  expect_true(grepl("chi-square|Fisher", res$test_name))
  expect_true(!is.null(res$test))
  expect_s3_class(res$test, "htest")
  expect_true(is.numeric(res$p_value) && !is.na(res$p_value))
})

test_that("acceptance_rate: character acceptance column (yes/no/true/1) coerces correctly", {
  test_df <- AUDIT
  test_df$contact_office <- c("yes", "NO", "True", "1")

  res <- suppressWarnings(mysterycall_acceptance_rate(test_df))

  expect_equal(res$summary$n_accepted, 3L)
  expect_equal(res$summary$n_rejected, 1L)
  expect_equal(res$summary$rate, 0.75)
})

test_that("acceptance_rate: numeric acceptance column (0/1) coerces correctly", {
  test_df <- AUDIT
  test_df$contact_office <- c(1, 0, 1, 0)

  res <- suppressWarnings(mysterycall_acceptance_rate(test_df))

  expect_equal(res$summary$n_accepted, 2L)
  expect_equal(res$summary$n_rejected, 2L)
  expect_equal(res$summary$rate, 0.5)
})

test_that("acceptance_rate: logical acceptance column works correctly", {
  test_df <- AUDIT
  test_df$contact_office <- c(TRUE, FALSE, TRUE, FALSE)

  res <- suppressWarnings(mysterycall_acceptance_rate(test_df))

  expect_equal(res$summary$n_accepted, 2L)
  expect_equal(res$summary$rate, 0.5)
})

test_that("acceptance_rate: edge case with missing values", {
  test_df <- AUDIT
  test_df$contact_office[2] <- NA

  res <- suppressWarnings(mysterycall_acceptance_rate(test_df))

  expect_equal(res$summary$n_missing, 1L)
  expect_equal(res$summary$n_total, 3L)
})

test_that("acceptance_rate: Wilson CI bounds are reasonable", {
  test_df <- AUDIT
  test_df$contact_office <- c(TRUE, TRUE, TRUE, FALSE)

  res <- suppressWarnings(mysterycall_acceptance_rate(test_df, conf_level = 0.95))

  # For 3/4 successes, CI should be within (0, 1)
  expect_true(res$summary$ci_lower >= 0)
  expect_true(res$summary$ci_upper <= 1)
  expect_true(res$summary$ci_lower < res$summary$rate)
  expect_true(res$summary$ci_upper > res$summary$rate)
})

test_that("acceptance_rate: bad input - conf_level < 0 or > 1 throws error", {
  expect_error(
    mysterycall_acceptance_rate(AUDIT, conf_level = 0),
    "conf_level"
  )
  expect_error(
    mysterycall_acceptance_rate(AUDIT, conf_level = 1),
    "conf_level"
  )
})

test_that("acceptance_rate: bad input - min_cell negative throws error", {
  expect_error(
    mysterycall_acceptance_rate(AUDIT, min_cell = -1),
    "min_cell"
  )
})

test_that("acceptance_rate: bad input - missing required column throws error", {
  bad_df <- AUDIT[, -which(names(AUDIT) == "contact_office")]

  expect_error(
    mysterycall_acceptance_rate(bad_df),
    "contact_office"
  )
})

test_that("acceptance_rate: custom accepted_col parameter works", {
  test_df <- AUDIT
  test_df$my_custom_col <- c(TRUE, FALSE, TRUE, TRUE)

  res <- suppressWarnings(mysterycall_acceptance_rate(test_df, accepted_col = "my_custom_col"))

  expect_equal(res$summary$n_accepted, 3L)
  expect_equal(res$summary$rate, 0.75)
})
