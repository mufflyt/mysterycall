# tests/testthat/test-screen-predictors.R
# testthat 3rd edition — mysterycall_screen_predictors()

# ── Helper fixture ─────────────────────────────────────────────────────────────

make_sp_df <- function(seed = 7L) {
  set.seed(seed)
  n <- 120L
  data.frame(
    wait_days    = rpois(n, lambda = 14),
    insurance    = sample(c("Medicaid", "BCBS"), n, replace = TRUE),
    gender       = sample(c("M", "F"), n, replace = TRUE),
    region       = sample(c("NE", "SE", "MW", "W"), n, replace = TRUE),
    practice_sz  = sample(1:5, n, replace = TRUE),
    constant_col = rep("same", n),                         # only 1 unique value
    physician    = rep(paste0("Dr_", 1:12), each = 10L),
    stringsAsFactors = FALSE
  )
}

# ── 1. Class ───────────────────────────────────────────────────────────────────

test_that("screen_predictors: returns list of class mysterycall_screen_predictors", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = c("insurance", "gender"),
      family           = "poisson"
    )
  )
  expect_type(res, "list")
  expect_s3_class(res, "mysterycall_screen_predictors")
})

# ── 2. Required table columns ──────────────────────────────────────────────────

test_that("screen_predictors: table has required columns", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = c("insurance", "gender"),
      family           = "poisson"
    )
  )
  required <- c("predictor", "estimate", "ci_lower", "ci_upper", "p_value", "significant")
  expect_true(all(required %in% names(res$table)))
})

# ── 3. n_screened == non-skipped rows ─────────────────────────────────────────

test_that("screen_predictors: n_screened matches non-skipped rows in table", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = c("insurance", "gender", "constant_col"),
      family           = "poisson"
    )
  )
  expect_equal(res$n_screened, sum(!res$table$skipped))
})

# ── 4. significant_predictors is a character vector ───────────────────────────

test_that("screen_predictors: significant_predictors is a character vector", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = c("insurance", "gender"),
      family           = "poisson"
    )
  )
  expect_type(res$significant_predictors, "character")
})

# ── 5. sentence contains "screening" ──────────────────────────────────────────

test_that("screen_predictors: sentence is a character string containing 'screening'", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = c("insurance", "gender"),
      family           = "poisson"
    )
  )
  expect_type(res$sentence, "character")
  expect_match(res$sentence, "screening", ignore.case = TRUE)
})

# ── 6. Constant column is skipped with skip_reason set ────────────────────────

test_that("screen_predictors: column with 1 unique value is skipped with skip_reason", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = c("insurance", "constant_col"),
      family           = "poisson"
    )
  )
  row_const <- res$table[res$table$predictor == "constant_col", ]
  expect_equal(nrow(row_const), 1L)
  expect_true(row_const$skipped)
  expect_false(is.na(row_const$skip_reason))
  expect_gt(nchar(row_const$skip_reason), 0L)
})

# ── 7. exclude_cols removes columns from table ────────────────────────────────

test_that("screen_predictors: excluded columns do not appear in result table", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = c("insurance", "gender", "region"),
      exclude_cols     = "gender",
      family           = "poisson"
    )
  )
  expect_false("gender" %in% res$table$predictor)
})

# ── 8. Stricter alpha marks fewer (or equal) significant predictors ────────────

test_that("screen_predictors: alpha_screen=0.05 flags <= significant than alpha_screen=0.20", {
  skip_if_not_installed("lme4")
  df    <- make_sp_df()
  cands <- c("insurance", "gender", "region", "practice_sz")

  res_strict <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = cands,
      family           = "poisson",
      alpha_screen     = 0.05
    )
  )
  res_liberal <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = cands,
      family           = "poisson",
      alpha_screen     = 0.20
    )
  )
  expect_lte(res_strict$n_significant, res_liberal$n_significant)
})

# ── 9. Poisson estimates (IRR) are strictly positive ──────────────────────────

test_that("screen_predictors: family='poisson' produces IRR estimates > 0", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = c("insurance", "gender"),
      family           = "poisson"
    )
  )
  fitted_est <- res$table$estimate[!res$table$skipped & !is.na(res$table$estimate)]
  expect_true(length(fitted_est) > 0L)
  expect_true(all(fitted_est > 0))
})

# ── 10. Error: outcome_col not in data ────────────────────────────────────────

test_that("screen_predictors: error when outcome_col is absent from data", {
  expect_error(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "no_such_column",
      random_intercept = "physician",
      candidate_cols   = c("insurance", "gender"),
      family           = "poisson"
    ),
    regexp = "not found"
  )
})

# ── 11. Error: random_intercept not in data ───────────────────────────────────

test_that("screen_predictors: error when random_intercept is absent from data", {
  expect_error(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "wait_days",
      random_intercept = "no_such_group",
      candidate_cols   = c("insurance", "gender"),
      family           = "poisson"
    ),
    regexp = "not found"
  )
})

# ── 12. verbose=TRUE does not error ───────────────────────────────────────────

test_that("screen_predictors: verbose=TRUE runs without error", {
  skip_if_not_installed("lme4")
  expect_no_error(
    suppressMessages(suppressWarnings(
      mysterycall_screen_predictors(
        data             = make_sp_df(),
        outcome_col      = "wait_days",
        random_intercept = "physician",
        candidate_cols   = c("insurance", "gender"),
        family           = "poisson",
        verbose          = TRUE
      )
    ))
  )
})

# ── 13. family element in result matches the argument ─────────────────────────

test_that("screen_predictors: result$family equals the family argument", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = c("insurance", "gender"),
      family           = "poisson"
    )
  )
  expect_equal(res$family, "poisson")
})

# ── 14. table is a tibble with one row per candidate ──────────────────────────

test_that("screen_predictors: table is a tibble with one row per candidate column", {
  skip_if_not_installed("lme4")
  candidates <- c("insurance", "gender", "region")
  res <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = candidates,
      family           = "poisson"
    )
  )
  expect_s3_class(res$table, "tbl_df")
  expect_equal(nrow(res$table), length(candidates))
})

# ── 15. n_significant never exceeds n_screened ────────────────────────────────

test_that("screen_predictors: n_significant does not exceed n_screened", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(
    mysterycall_screen_predictors(
      data             = make_sp_df(),
      outcome_col      = "wait_days",
      random_intercept = "physician",
      candidate_cols   = c("insurance", "gender", "region"),
      family           = "poisson"
    )
  )
  expect_lte(res$n_significant, res$n_screened)
})
