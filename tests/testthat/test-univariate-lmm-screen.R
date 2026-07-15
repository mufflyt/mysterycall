# tests/testthat/test-univariate-lmm-screen.R
# testthat 3rd edition

# ── helpers ──────────────────────────────────────────────────────────────────

make_lmm_df <- function(seed = 1L, n = 120L) {
  set.seed(seed)
  n_phys <- 20L
  data.frame(
    business_days_until_appointment = c(
      rpois(n / 2, 7),   # BCBS
      rpois(n / 2, 14)   # Medicaid: higher wait
    ),
    insurance = rep(c("BCBS", "Medicaid"), each = n / 2),
    gender    = rep(c("M", "F"), n / 2),
    last      = rep(paste0("Dr", seq_len(n_phys)), each = n / n_phys),
    record_id = seq_len(n),
    stringsAsFactors = FALSE
  )
}

# ── structural tests ──────────────────────────────────────────────────────────

test_that("lmm_screen: returns named list with required elements", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df()
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, output_dir = NA)
  )
  expect_named(res, c("results", "significant", "sentence", "alpha"))
})

test_that("lmm_screen: $results has expected column names", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df()
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, output_dir = NA)
  )
  expected_cols <- c("Predictor", "P_Value", "P_Formatted", "Estimate",
                     "CI_Lower", "CI_Upper")
  expect_true(all(expected_cols %in% names(res$results)))
})

test_that("lmm_screen: $results is a tibble", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df()
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, output_dir = NA)
  )
  expect_s3_class(res$results, "tbl_df")
})

test_that("lmm_screen: $sentence is non-empty character", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df()
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, output_dir = NA)
  )
  expect_type(res$sentence, "character")
  expect_gt(nchar(res$sentence), 0L)
})

test_that("lmm_screen: $alpha matches argument", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df()
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, alpha = 0.1, output_dir = NA)
  )
  expect_equal(res$alpha, 0.1)
})

# ── adversarial tests ─────────────────────────────────────────────────────────

test_that("lmm_screen: error when outcome_col not found", {
  df <- make_lmm_df()
  expect_error(
    mysterycall_univariate_lmm_screen(df, outcome_col = "nonexistent",
                                      output_dir = NA),
    "not found"
  )
})

test_that("lmm_screen: error when random_effect col not found", {
  df <- make_lmm_df()
  expect_error(
    mysterycall_univariate_lmm_screen(df, random_effect = "badcol",
                                      output_dir = NA),
    "not found"
  )
})

test_that("lmm_screen: error when data is not a data frame", {
  expect_error(
    mysterycall_univariate_lmm_screen(list(a = 1), output_dir = NA),
    "data frame"
  )
})

test_that("lmm_screen: all predictors one unique value -> zero-row significant + no-sig sentence", {
  skip_if_not_installed("lmerTest")
  df <- data.frame(
    business_days_until_appointment = c(3, 7, 14),
    constant_col = c(1, 1, 1),
    last         = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(
      df,
      exclude_cols = c("business_days_until_appointment", "last"),
      output_dir   = NA
    )
  )
  # constant_col has 1 unique value -> skipped
  expect_equal(nrow(res$significant), 0L)
  expect_match(res$sentence, "No significant predictors")
})

test_that("lmm_screen: alpha = 0 -> all filtered out", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df()
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, alpha = 0, output_dir = NA)
  )
  expect_equal(nrow(res$significant), 0L)
})

test_that("lmm_screen: NAs in outcome dropped silently", {
  skip_if_not_installed("lmerTest")
  df <- make_lmm_df()
  df$business_days_until_appointment[1:5] <- NA
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, output_dir = NA)
  )
  expect_s3_class(res$results, "tbl_df")
})

# ── semantic tests ────────────────────────────────────────────────────────────

test_that("lmm_screen: insurance appears in $significant with known data", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df(seed = 42L, n = 200L)
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, alpha = 0.2, output_dir = NA)
  )
  # insurance should be detected as a significant predictor at alpha = 0.2
  sig_preds <- res$significant$Predictor
  expect_true("insurance" %in% sig_preds,
              info = paste("Significant predictors:", paste(sig_preds, collapse = ", ")))
})

test_that("lmm_screen: $significant sorted ascending by P_Value", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df()
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, alpha = 0.5, output_dir = NA)
  )
  if (nrow(res$significant) > 1L) {
    expect_true(all(diff(res$significant$P_Value) >= 0))
  } else {
    succeed()
  }
})

test_that("lmm_screen: sentence contains predictor name when significant", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df(seed = 7L, n = 200L)
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, alpha = 0.5, output_dir = NA)
  )
  if (nrow(res$significant) > 0L) {
    first_pred <- res$significant$Predictor[1L]
    expect_match(res$sentence, first_pred, fixed = TRUE)
  } else {
    succeed()
  }
})

# ── p_adjust_method tests ─────────────────────────────────────────────────────

test_that("lmm_screen: p_adjust_method='BH' adds P_Value_Adjusted column", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df()
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, p_adjust_method = "BH",
                                      output_dir = NA)
  )
  expect_true("P_Value_Adjusted" %in% names(res$results))
})

test_that("lmm_screen: p_adjust_method='bonferroni' gives adjusted >= raw p", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df()
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, p_adjust_method = "bonferroni",
                                      output_dir = NA)
  )
  expect_true("P_Value_Adjusted" %in% names(res$results))
  # Bonferroni always inflates (adjusted >= raw)
  expect_true(all(res$results$P_Value_Adjusted >= res$results$P_Value))
})

test_that("lmm_screen: p_adjust_method='none' produces no P_Value_Adjusted column", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df()
  res <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, p_adjust_method = "none",
                                      output_dir = NA)
  )
  expect_false("P_Value_Adjusted" %in% names(res$results))
})

test_that("lmm_screen: p_adjust_method='invalid_xyz' errors", {
  skip_if_not_installed("lmerTest")
  df  <- make_lmm_df()
  expect_error(
    suppressMessages(
      mysterycall_univariate_lmm_screen(df, p_adjust_method = "invalid_xyz",
                                        output_dir = NA)
    )
  )
})
