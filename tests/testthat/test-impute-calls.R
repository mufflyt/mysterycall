# ── mysterycall_impute_calls ──────────────────────────────────────────────────

# Helper: build a minimal data frame with controllable missingness
make_call_df <- function(n_phys = 15L, n_calls = 4L,
                         pct_miss = 0.15, seed = 42L) {
  set.seed(seed)
  n <- n_phys * n_calls
  df <- data.frame(
    offered   = rbinom(n, 1L, 0.65),
    insurance = rep(c("Medicaid", "BCBS"), length.out = n),
    physician = rep(paste0("Dr", seq_len(n_phys)), each = n_calls),
    stringsAsFactors = FALSE
  )
  if (pct_miss > 0) {
    miss_idx <- sample(seq_len(n), size = max(1L, round(n * pct_miss)))
    df$offered[miss_idx] <- NA_integer_
  }
  df
}

# ── 1. Function exists and is callable ────────────────────────────────────────

test_that("impute_calls: function is exported and callable", {
  expect_true(existsMethod  <- is.function(mysterycall_impute_calls))
  expect_true(existsMethod)
})

# ── 2. Error when mice is not installed ───────────────────────────────────────

test_that("impute_calls: errors with informative message when mice absent", {
  skip_if_not_installed("mockery")
  df <- make_call_df()
  mockery::stub(
    mysterycall_impute_calls,
    "requireNamespace",
    function(pkg, quietly = FALSE) if (pkg == "mice") FALSE else TRUE
  )
  expect_error(
    mysterycall_impute_calls(
      data             = df,
      outcome_col      = "offered",
      predictors       = "insurance",
      random_intercept = "physician",
      m                = 5L
    ),
    regexp = "mice"
  )
})

# ── 3. Error when outcome_col not in data ─────────────────────────────────────

test_that("impute_calls: errors when outcome_col is absent from data", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")
  df <- make_call_df()
  expect_error(
    mysterycall_impute_calls(
      data             = df,
      outcome_col      = "MISSING_COLUMN",
      predictors       = "insurance",
      random_intercept = "physician",
      m                = 5L
    ),
    regexp = "MISSING_COLUMN"
  )
})

# ── 4. Error when predictors not in data ──────────────────────────────────────

test_that("impute_calls: errors when a predictor column is absent from data", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")
  df <- make_call_df()
  expect_error(
    mysterycall_impute_calls(
      data             = df,
      outcome_col      = "offered",
      predictors       = c("insurance", "nonexistent_col"),
      random_intercept = "physician",
      m                = 5L
    ),
    regexp = "nonexistent_col|not found|required"
  )
})

# ── 5. Error when data has zero rows ──────────────────────────────────────────

test_that("impute_calls: errors when data has no rows", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")
  empty_df <- data.frame(
    offered   = integer(0),
    insurance = character(0),
    physician = character(0),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_impute_calls(
      data             = empty_df,
      outcome_col      = "offered",
      predictors       = "insurance",
      random_intercept = "physician",
      m                = 5L
    )
  )
})

# ── 6. Warning when <1% of outcome values are missing ────────────────────────

test_that("impute_calls: warns when missingness is below 1%", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")
  # Build a large-ish df, set exactly one NA (<1%)
  df <- make_call_df(n_phys = 30L, n_calls = 6L, pct_miss = 0)
  df$offered[1L] <- NA_integer_   # 1 / 180 ≈ 0.56%
  expect_warning(
    mysterycall_impute_calls(
      data             = df,
      outcome_col      = "offered",
      predictors       = "insurance",
      random_intercept = "physician",
      m                = 5L,
      maxit            = 3L,
      seed             = 7L
    ),
    regexp = "missing|unnecessary|1%|imputation",
    ignore.case = TRUE
  )
})

# ── 7. pooled_table structure ─────────────────────────────────────────────────

test_that("impute_calls: pooled_table is a data frame with required columns", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")
  df  <- make_call_df()
  res <- mysterycall_impute_calls(
    data             = df,
    outcome_col      = "offered",
    predictors       = "insurance",
    random_intercept = "physician",
    m                = 5L,
    maxit            = 3L,
    seed             = 1L
  )
  expect_true(is.data.frame(res$pooled_table))
  required_cols <- c("term", "or", "ci_lower", "ci_upper", "p_value", "fmi")
  expect_true(
    all(required_cols %in% names(res$pooled_table)),
    info = paste(
      "Missing columns:",
      paste(setdiff(required_cols, names(res$pooled_table)), collapse = ", ")
    )
  )
})

# ── 8. m parameter controls number of imputations ────────────────────────────

test_that("impute_calls: m controls the number of individual fits returned", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")
  df <- make_call_df()
  for (m_val in c(5L, 8L)) {
    res <- mysterycall_impute_calls(
      data             = df,
      outcome_col      = "offered",
      predictors       = "insurance",
      random_intercept = "physician",
      m                = m_val,
      maxit            = 2L,
      seed             = 99L
    )
    expect_equal(res$m, m_val)
    expect_equal(length(res$individual_fits), m_val)
  }
})

# ── 9. sentence is a character string containing "imputation" ─────────────────

test_that("impute_calls: sentence is character and mentions imputation", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")
  df  <- make_call_df()
  res <- mysterycall_impute_calls(
    data             = df,
    outcome_col      = "offered",
    predictors       = "insurance",
    random_intercept = "physician",
    m                = 5L,
    maxit            = 3L,
    seed             = 2L
  )
  expect_type(res$sentence, "character")
  expect_true(grepl("imputation", res$sentence, ignore.case = TRUE))
})

# ── 10. fmi values in [0, 1] ─────────────────────────────────────────────────

test_that("impute_calls: fmi values are in [0, 1]", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")
  df  <- make_call_df()
  res <- mysterycall_impute_calls(
    data             = df,
    outcome_col      = "offered",
    predictors       = "insurance",
    random_intercept = "physician",
    m                = 6L,
    maxit            = 3L,
    seed             = 3L
  )
  fmi_vals <- res$pooled_table$fmi
  non_na   <- fmi_vals[!is.na(fmi_vals)]
  if (length(non_na) > 0L) {
    expect_true(all(non_na >= 0 & non_na <= 1),
                info = paste("Out-of-range FMI:", paste(non_na[non_na < 0 | non_na > 1], collapse = ", ")))
  }
})

# ── 11. Return object has the right class ─────────────────────────────────────

test_that("impute_calls: return value has class mysterycall_impute_calls", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")
  df  <- make_call_df()
  res <- mysterycall_impute_calls(
    data             = df,
    outcome_col      = "offered",
    predictors       = "insurance",
    random_intercept = "physician",
    m                = 5L,
    maxit            = 2L,
    seed             = 5L
  )
  expect_s3_class(res, "mysterycall_impute_calls")
})

# ── 12. n_missing and pct_missing are consistent ──────────────────────────────

test_that("impute_calls: n_missing and pct_missing are consistent with data", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")
  df <- make_call_df(pct_miss = 0.20, seed = 77L)
  n_na_expected <- sum(is.na(df$offered))
  res <- mysterycall_impute_calls(
    data             = df,
    outcome_col      = "offered",
    predictors       = "insurance",
    random_intercept = "physician",
    m                = 5L,
    maxit            = 2L,
    seed             = 8L
  )
  expect_equal(res$n_missing, n_na_expected)
  expect_equal(res$pct_missing, n_na_expected / nrow(df) * 100)
})
