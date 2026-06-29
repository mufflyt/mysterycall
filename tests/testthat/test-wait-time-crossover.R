library(testthat)

# helper: builds a standard paired long-format data frame
make_wt_data <- function(n = 30L, seed = 42L,
                         bcbs_mean = 12, bcbs_sd = 4,
                         med_mean  = 18, med_sd  = 6) {
  set.seed(seed)
  bcbs_days     <- pmax(1L, round(stats::rnorm(n, mean = bcbs_mean, sd = bcbs_sd)))
  medicaid_days <- pmax(1L, round(stats::rnorm(n, mean = med_mean,  sd = med_sd)))
  data.frame(
    phone     = rep(sprintf("555-%04d", seq_len(n)), times = 2L),
    insurance = rep(c("BCBS", "Medicaid"), each = n),
    business_days_until_appointment = c(bcbs_days, medicaid_days),
    stringsAsFactors = FALSE
  )
}

# ---- 1. class ---------------------------------------------------------------

test_that("result inherits class mysterycall_wait_time_crossover", {
  res <- mysterycall_wait_time_crossover(make_wt_data(), min_pairs = 5L)
  expect_s3_class(res, "mysterycall_wait_time_crossover")
  expect_type(res, "list")
})

# ---- 2. crossover_days type -------------------------------------------------

test_that("crossover_days is a length-1 numeric (possibly NA)", {
  res <- mysterycall_wait_time_crossover(make_wt_data(), min_pairs = 5L)
  expect_true(is.numeric(res$crossover_days))
  expect_length(res$crossover_days, 1L)
})

# ---- 3. sentence type -------------------------------------------------------

test_that("sentence is a non-empty character scalar", {
  res <- mysterycall_wait_time_crossover(make_wt_data(), min_pairs = 5L)
  expect_type(res$sentence, "character")
  expect_length(res$sentence, 1L)
  expect_gt(nchar(res$sentence), 0L)
})

# ---- 4. n_pairs count -------------------------------------------------------

test_that("n_pairs equals number of physicians with data in both groups", {
  # 25 physicians each appear exactly once in BCBS and Medicaid -> 25 pairs
  df  <- make_wt_data(n = 25L)
  res <- mysterycall_wait_time_crossover(df, min_pairs = 5L)
  expect_equal(res$n_pairs, 25L)
})

# ---- 5. slope and intercept types ------------------------------------------

test_that("slope and intercept are non-NA numeric scalars", {
  res <- mysterycall_wait_time_crossover(make_wt_data(), min_pairs = 5L)
  expect_type(res$slope,     "double")
  expect_type(res$intercept, "double")
  expect_length(res$slope,     1L)
  expect_length(res$intercept, 1L)
  expect_false(is.na(res$slope))
  expect_false(is.na(res$intercept))
})

# ---- 6. r_squared bounds ----------------------------------------------------

test_that("r_squared is in [0, 1]", {
  res <- mysterycall_wait_time_crossover(make_wt_data(), min_pairs = 5L)
  expect_gte(res$r_squared, 0)
  expect_lte(res$r_squared, 1)
})

# ---- 7. plot_data shape -----------------------------------------------------

test_that("plot_data is a data.frame with exactly 2 columns", {
  res <- mysterycall_wait_time_crossover(make_wt_data(), min_pairs = 5L)
  expect_s3_class(res$plot_data, "data.frame")
  expect_equal(ncol(res$plot_data), 2L)
})

# ---- 8. slope >= 1 -> NA crossover -----------------------------------------

test_that("slope >= 1 yields NA crossover_days and sentence containing 'crossover_days is NA'", {
  # y = 2 * x on original scale -> slope = 2 >= 1 -> no equalization point
  n      <- 20L
  x_vals <- seq(5L, 24L, by = 1L)
  y_vals <- 2L * x_vals
  df <- data.frame(
    phone     = rep(sprintf("555-%04d", seq_len(n)), times = 2L),
    insurance = rep(c("G1", "G2"), each = n),
    business_days_until_appointment = c(x_vals, y_vals),
    stringsAsFactors = FALSE
  )
  # suppressWarnings: perfectly collinear data triggers "essentially perfect fit"
  res <- suppressWarnings(
    mysterycall_wait_time_crossover(df, log_transform = FALSE, min_pairs = 5L)
  )
  expect_gte(res$slope, 1)
  expect_true(is.na(res$crossover_days))
  expect_match(res$sentence, "crossover_days is NA", fixed = TRUE)
})

# ---- 9. exactly 2 groups ----------------------------------------------------

test_that("function works correctly when data contains exactly 2 insurance groups", {
  df <- make_wt_data()
  expect_equal(length(unique(df$insurance)), 2L)
  res <- mysterycall_wait_time_crossover(df, min_pairs = 5L)
  expect_s3_class(res, "mysterycall_wait_time_crossover")
  expect_equal(res$group1, "BCBS")
  expect_equal(res$group2, "Medicaid")
})

# ---- 10. min_pairs error ----------------------------------------------------

test_that("errors when complete pairs are fewer than min_pairs", {
  df_small <- make_wt_data(n = 5L)
  expect_error(
    mysterycall_wait_time_crossover(df_small, min_pairs = 10L),
    regexp = "min_pairs"
  )
})

# ---- 11. missing group_col --------------------------------------------------

test_that("errors when group_col is absent from data", {
  df <- make_wt_data()
  expect_error(
    mysterycall_wait_time_crossover(df, group_col = "no_such_col"),
    regexp = "not found in"
  )
})

# ---- 12. missing id_col -----------------------------------------------------

test_that("errors when id_col is absent from data", {
  df <- make_wt_data()
  expect_error(
    mysterycall_wait_time_crossover(df, id_col = "no_such_col"),
    regexp = "not found in"
  )
})

# ---- 13. alphabetical auto-selection ----------------------------------------

test_that("group1 and group2 are auto-selected alphabetically when NULL", {
  set.seed(42L)
  n <- 20L
  df <- data.frame(
    phone     = rep(sprintf("555-%04d", seq_len(n)), times = 2L),
    insurance = rep(c("Medicaid", "Aetna"), each = n),
    business_days_until_appointment = c(
      pmax(1L, round(stats::rnorm(n, 18, 5))),
      pmax(1L, round(stats::rnorm(n, 10, 3)))
    ),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_wait_time_crossover(df, min_pairs = 5L)
  expect_equal(res$group1, "Aetna")    # alphabetically first
  expect_equal(res$group2, "Medicaid") # alphabetically second
})

# ---- 14. plot_data column names match groups --------------------------------

test_that("plot_data column names equal group1 and group2", {
  res <- mysterycall_wait_time_crossover(make_wt_data(), min_pairs = 5L)
  expect_equal(names(res$plot_data), c(res$group1, res$group2))
})

# ---- 15. positive crossover when 0 < slope < 1 ------------------------------

test_that("crossover_days is positive when slope is strictly between 0 and 1", {
  # y = 0.5 * x + 5 (original scale, no log); crossover at x = 5 / (1 - 0.5) = 10
  set.seed(5L)
  n      <- 20L
  x_vals <- seq(2L, 21L, by = 1L)
  y_vals <- 0.5 * x_vals + 5 + stats::rnorm(n, 0, 0.1)
  df <- data.frame(
    phone     = rep(sprintf("555-%04d", seq_len(n)), times = 2L),
    insurance = rep(c("G1", "G2"), each = n),
    business_days_until_appointment = c(x_vals, y_vals),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_wait_time_crossover(df, log_transform = FALSE, min_pairs = 5L)
  expect_gt(res$slope, 0)
  expect_lt(res$slope, 1)
  expect_false(is.na(res$crossover_days))
  expect_gt(res$crossover_days, 0)
})
