skip_if_not_installed("lme4")

# ── Shared fixtures ────────────────────────────────────────────────────────────

set.seed(2024)
n_doc <- 10
n_per <- 6

# Symmetric (approx normal) wait days — should NOT trigger auto_log
sym_df <- data.frame(
  wait_days = round(rnorm(n_doc * n_per, mean = 21, sd = 6)),
  scenario  = rep(c("Straight", "Lesbian", "Single"), length.out = n_doc * n_per),
  physician = rep(paste0("Dr", seq_len(n_doc)), each = n_per),
  stringsAsFactors = FALSE
)

# Right-skewed wait days (skewness >> 1) — should trigger auto_log
skewed_df <- sym_df
skewed_df$wait_days <- c(round(exp(rnorm(n_doc * n_per - 1, 2.5, 0.8))), 544)

# ── Input validation ──────────────────────────────────────────────────────────

test_that("lmm: stops when data is not a data frame", {
  expect_error(mysterycall_lmm(list(), "wait_days", "scenario", "physician"))
})

test_that("lmm: stops when outcome column is missing", {
  expect_error(
    mysterycall_lmm(sym_df, "no_such_col", "scenario", "physician"),
    "no_such_col"
  )
})

test_that("lmm: stops when predictor column is missing", {
  expect_error(
    mysterycall_lmm(sym_df, "wait_days", "no_such_col", "physician"),
    "no_such_col"
  )
})

test_that("lmm: stops when random_intercept column is missing", {
  expect_error(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "no_such_col"),
    "no_such_col"
  )
})

test_that("lmm: stops when outcome is not numeric", {
  df <- sym_df
  df$wait_days <- as.character(df$wait_days)
  expect_error(
    mysterycall_lmm(df, "wait_days", "scenario", "physician"),
    "numeric"
  )
})

test_that("lmm: stops when conf_level is out of range", {
  expect_error(mysterycall_lmm(sym_df, "wait_days", "scenario", "physician", conf_level = 1.5))
  expect_error(mysterycall_lmm(sym_df, "wait_days", "scenario", "physician", conf_level = 0))
})

# ── Return structure ──────────────────────────────────────────────────────────

test_that("lmm: returns a mysterycall_lmm object with expected fields", {
  fit <- suppressWarnings(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "physician")
  )
  expect_s3_class(fit, "mysterycall_lmm")
  expected_fields <- c(
    "model", "coef_table", "gmr_table", "log_transformed",
    "outcome_original", "outcome_used",
    "random_effects", "factor_refs", "formula",
    "n", "n_dropped", "n_clusters",
    "sigma", "r_squared", "normality", "convergence",
    "aic", "bic", "REML"
  )
  for (f in expected_fields) {
    expect_true(f %in% names(fit), info = paste("missing field:", f))
  }
})

test_that("lmm: coef_table has expected columns", {
  fit <- suppressWarnings(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "physician")
  )
  expect_true(all(c("term", "estimate", "se", "ci_lower", "ci_upper", "p_value_fmt") %in%
                    names(fit$coef_table)))
})

test_that("lmm: n equals complete-case rows", {
  df_na <- sym_df
  df_na$wait_days[c(1, 5)] <- NA
  fit <- suppressWarnings(
    mysterycall_lmm(df_na, "wait_days", "scenario", "physician")
  )
  expect_equal(fit$n, nrow(sym_df) - 2L)
  expect_equal(fit$n_dropped, 2L)
})

test_that("lmm: r_squared marginal is in [0, 1]", {
  fit <- suppressWarnings(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "physician")
  )
  expect_gte(fit$r_squared$marginal,    0)
  expect_lte(fit$r_squared$marginal,    1)
  expect_gte(fit$r_squared$conditional, 0)
  expect_lte(fit$r_squared$conditional, 1)
})

test_that("lmm: factor_refs records reference level for character predictors", {
  fit <- suppressWarnings(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "physician")
  )
  expect_true("scenario" %in% names(fit$factor_refs))
  # alphabetically first level of scenario
  expect_equal(fit$factor_refs$scenario, sort(unique(sym_df$scenario))[[1]])
})

# ── auto_log behaviour ────────────────────────────────────────────────────────

test_that("lmm: symmetric outcome does NOT trigger auto_log transform", {
  fit <- suppressWarnings(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "physician")
  )
  expect_false(fit$log_transformed)
  expect_equal(fit$outcome_original, "wait_days")
  expect_equal(fit$outcome_used,     "wait_days")
  expect_null(fit$gmr_table)
})

test_that("lmm: right-skewed outcome triggers auto_log transform automatically", {
  fit <- suppressWarnings(suppressMessages(
    mysterycall_lmm(skewed_df, "wait_days", "scenario", "physician")
  ))
  expect_true(fit$log_transformed)
  expect_equal(fit$outcome_original, "wait_days")
  expect_equal(fit$outcome_used,     "log1p_wait_days")
  expect_false(is.null(fit$gmr_table))
})

test_that("lmm: auto_log emits an informative message when triggered", {
  expect_message(
    suppressWarnings(
      mysterycall_lmm(skewed_df, "wait_days", "scenario", "physician")
    ),
    regexp = "auto_log.*skewness.*log1p"
  )
})

test_that("lmm: auto_log = FALSE skips transform even on skewed data", {
  fit <- suppressWarnings(
    mysterycall_lmm(skewed_df, "wait_days", "scenario", "physician", auto_log = FALSE)
  )
  expect_false(fit$log_transformed)
  expect_equal(fit$outcome_used, "wait_days")
  expect_null(fit$gmr_table)
})

# ── gmr_table correctness ─────────────────────────────────────────────────────

test_that("lmm: gmr_table GMR equals exp(estimate) from coef_table", {
  fit <- suppressWarnings(suppressMessages(
    mysterycall_lmm(skewed_df, "wait_days", "scenario", "physician")
  ))
  expect_equal(
    fit$gmr_table$GMR,
    exp(fit$coef_table$estimate),
    tolerance = 1e-9
  )
  expect_equal(
    fit$gmr_table$GMR_lo,
    exp(fit$coef_table$ci_lower),
    tolerance = 1e-9
  )
  expect_equal(
    fit$gmr_table$GMR_hi,
    exp(fit$coef_table$ci_upper),
    tolerance = 1e-9
  )
})

test_that("lmm: gmr_table GMR values are strictly positive", {
  fit <- suppressWarnings(suppressMessages(
    mysterycall_lmm(skewed_df, "wait_days", "scenario", "physician")
  ))
  expect_true(all(fit$gmr_table$GMR    > 0))
  expect_true(all(fit$gmr_table$GMR_lo > 0))
  expect_true(all(fit$gmr_table$GMR_hi > 0))
})

# ── normality reporting ───────────────────────────────────────────────────────

test_that("lmm: normality list has required fields", {
  fit <- suppressWarnings(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "physician")
  )
  expect_true(all(c("statistic", "p_value", "interpretation", "method") %in%
                    names(fit$normality)))
})

# ── print method ──────────────────────────────────────────────────────────────

test_that("lmm: print produces output without error (raw scale)", {
  fit <- suppressWarnings(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "physician")
  )
  expect_output(print(fit), "Linear Mixed Model")
  expect_output(print(fit), "Fixed effects")
})

test_that("lmm: print shows GMR table when log_transformed", {
  fit <- suppressWarnings(suppressMessages(
    mysterycall_lmm(skewed_df, "wait_days", "scenario", "physician")
  ))
  expect_output(print(fit), "Geometric mean ratios")
  expect_output(print(fit), "GMR")
})

test_that("lmm: print does NOT show GMR table on raw-scale model", {
  fit <- suppressWarnings(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "physician")
  )
  expect_no_match <- function(object, regexp) {
    out <- capture.output(object)
    expect_false(any(grepl(regexp, out)))
  }
  expect_no_match(print(fit), "Geometric mean ratios")
})

# ── missing-data handling ─────────────────────────────────────────────────────

test_that("lmm: all-NA outcome throws an error", {
  df_bad <- sym_df
  df_bad$wait_days <- NA_real_
  expect_error(
    mysterycall_lmm(df_bad, "wait_days", "scenario", "physician"),
    "No complete cases"
  )
})

# ── Regression: bug fixes (CI/df/label) ───────────────────────────────────────

# BUG 44: fixed-effect CI must use the matching t quantile so it agrees with
# the Satterthwaite t-based p-value. Invariant: a term's CI excludes 0 iff its
# p-value < (1 - conf_level).
test_that("lmm: CI agreement with p-value uses t (not z) quantile", {
  fit <- suppressWarnings(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "physician")
  )
  ct <- fit$coef_table
  excludes_zero <- ct$ci_lower > 0 | ct$ci_upper < 0
  sig_p         <- ct$p_value < 0.05
  expect_equal(excludes_zero, sig_p)
})

test_that("lmm: CI half-width matches per-term t quantile times SE", {
  fit <- suppressWarnings(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "physician")
  )
  ct <- fit$coef_table
  t_crit   <- stats::qt(0.975, df = ct$df)
  expected <- t_crit * ct$se
  observed <- (ct$ci_upper - ct$ci_lower) / 2
  expect_equal(observed, expected, tolerance = 1e-8)
  # t quantile is strictly wider than the z quantile at finite df
  expect_true(all(t_crit > stats::qnorm(0.975)))
})

# BUG 46: transformed-scale SD units must be labelled log1p(days), not "days".
test_that("lmm: print labels residual/RE SD with log1p units when log-transformed", {
  fit <- suppressWarnings(suppressMessages(
    mysterycall_lmm(skewed_df, "wait_days", "scenario", "physician")
  ))
  out <- capture.output(print(fit))
  resid_line <- grep("Residual SD", out, value = TRUE)
  expect_match(resid_line, "log1p\\(days\\)")
  # raw-scale model keeps plain days
  fit_raw <- suppressWarnings(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "physician")
  )
  out_raw <- capture.output(print(fit_raw))
  resid_raw <- grep("Residual SD", out_raw, value = TRUE)
  expect_match(resid_raw, "SD = [0-9.]+ days")
  expect_false(grepl("log1p", resid_raw))
})

# BUG 47: fallback residual df (no lmerTest) is n - est_df, not n - est_df - 1.
test_that("lmm: fallback residual df does not double-count the intercept", {
  skip_if(requireNamespace("lmerTest", quietly = TRUE),
          "lmerTest present: Satterthwaite df path used, not the fallback")
  fit <- suppressWarnings(
    mysterycall_lmm(sym_df, "wait_days", "scenario", "physician")
  )
  # n = 60, scenario has 3 levels -> est_df = 1 (intercept) + 2 = 3
  expect_equal(unique(fit$coef_table$df), fit$n - 3L)
})
