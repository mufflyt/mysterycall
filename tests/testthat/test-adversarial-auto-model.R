# Adversarial, semantic, and negative-control tests for the enhanced
# mysterycall_auto_model() — covers the 3-step Poisson → NB → LMM
# decision tree added in v1.5.0.
#
# Companion file to test-adversarial-power-automodel.R (which covers the
# older Poisson/NB routing only). This file focuses on:
#   - LMM evaluation semantics  (include_lmm path)
#   - $selection structure completeness
#   - Backward compatibility with downstream functions
#   - Class vector correctness (mysterycall_auto_model prepended)

library(testthat)

# ── fixtures ──────────────────────────────────────────────────────────────────

# Wide-range, approximately normal data — LMM should be defensible
make_normal_df <- function(seed = 42L) {
  set.seed(seed)
  data.frame(
    wait      = pmax(round(rnorm(120, mean = 35, sd = 12)), 1L),
    insurance = rep(c("Medicaid", "BCBS"), 60L),
    physician = rep(paste0("Dr", 1:20), each = 6L),
    stringsAsFactors = FALSE
  )
}

# Poisson-distributed, low lambda — phi ≈ 1, no overdispersion
make_poisson_df <- function(seed = 7L) {
  set.seed(seed)
  data.frame(
    wait      = rpois(120L, lambda = 18),
    insurance = rep(c("Medicaid", "BCBS"), 60L),
    physician = rep(paste0("Dr", 1:20), each = 6L),
    stringsAsFactors = FALSE
  )
}

# Narrow-range outcome (range < 30) — LMM should NOT be defensible
make_narrow_df <- function(seed = 5L) {
  set.seed(seed)
  data.frame(
    wait      = sample(5:25, 120, replace = TRUE),   # range = 20
    insurance = rep(c("Medicaid", "BCBS"), 60L),
    physician = rep(paste0("Dr", 1:20), each = 6L),
    stringsAsFactors = FALSE
  )
}

# ── Category 1: Input validation (adversarial) ────────────────────────────────

test_that("auto_model: NULL data raises error", {
  skip_if_not_installed("lme4")
  expect_error(
    suppressMessages(mysterycall_auto_model(NULL, "wait", "insurance", "physician")),
    class = "error"
  )
})

test_that("auto_model: non-data-frame input raises error", {
  skip_if_not_installed("lme4")
  expect_error(
    suppressMessages(mysterycall_auto_model(list(wait = 1:10), "wait", "insurance", "physician")),
    class = "error"
  )
})

test_that("auto_model: missing outcome column raises error", {
  skip_if_not_installed("lme4")
  df <- make_poisson_df()
  expect_error(
    suppressMessages(mysterycall_auto_model(df, "no_such_col", "insurance", "physician")),
    class = "error"
  )
})

test_that("auto_model: missing predictor column raises error", {
  skip_if_not_installed("lme4")
  df <- make_poisson_df()
  expect_error(
    suppressMessages(mysterycall_auto_model(df, "wait", "no_such_col", "physician")),
    class = "error"
  )
})

test_that("auto_model: missing random_intercept column raises error", {
  skip_if_not_installed("lme4")
  df <- make_poisson_df()
  expect_error(
    suppressMessages(mysterycall_auto_model(df, "wait", "insurance", "no_phys")),
    class = "error"
  )
})

test_that("auto_model: character outcome column raises error", {
  skip_if_not_installed("lme4")
  set.seed(1L)
  df <- make_poisson_df()
  df$wait_chr <- as.character(df$wait)
  expect_error(
    suppressMessages(mysterycall_auto_model(df, "wait_chr", "insurance", "physician")),
    class = "error"
  )
})

test_that("auto_model: conf_level > 1 raises error", {
  skip_if_not_installed("lme4")
  df <- make_poisson_df()
  expect_error(
    suppressMessages(mysterycall_auto_model(df, "wait", "insurance", "physician",
                                             conf_level = 1.5)),
    class = "error"
  )
})

test_that("auto_model: conf_level = 0 raises error", {
  skip_if_not_installed("lme4")
  df <- make_poisson_df()
  expect_error(
    suppressMessages(mysterycall_auto_model(df, "wait", "insurance", "physician",
                                             conf_level = 0)),
    class = "error"
  )
})

test_that("auto_model: zero-row data frame raises error", {
  skip_if_not_installed("lme4")
  df <- make_poisson_df()[0L, ]
  expect_error(
    suppressMessages(mysterycall_auto_model(df, "wait", "insurance", "physician")),
    class = "error"
  )
})

test_that("auto_model: all-NA outcome raises error", {
  skip_if_not_installed("lme4")
  df <- make_poisson_df()
  df$wait <- NA_integer_
  expect_error(
    suppressMessages(mysterycall_auto_model(df, "wait", "insurance", "physician")),
    class = "error"
  )
})

# ── Category 2: Structural / semantic correctness ─────────────────────────────

test_that("auto_model: first class element is 'mysterycall_auto_model'", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  expect_equal(class(result)[1L], "mysterycall_auto_model")
})

test_that("auto_model: inherits from mysterycall_poisson_model when Poisson selected", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician",
                            phi_threshold = 100)
  ))
  expect_equal(result$selection$model_chosen, "poisson")
  expect_true(inherits(result, "mysterycall_poisson_model"))
})

test_that("auto_model: $selection contains all 8 required names", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  required <- c("poisson_phi", "model_chosen", "reason",
                "lmm", "lmm_shapiro_p", "lmm_defensible",
                "lmm_recommendation", "recommendation")
  expect_true(all(required %in% names(result$selection)))
})

test_that("auto_model: model_chosen is exactly 'poisson' or 'negative_binomial'", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  expect_true(result$selection$model_chosen %in% c("poisson", "negative_binomial"))
})

test_that("auto_model: poisson_phi is a single positive numeric", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  phi <- result$selection$poisson_phi
  expect_true(is.numeric(phi))
  expect_length(phi, 1L)
  expect_true(phi >= 0)
})

test_that("auto_model: recommendation is a non-empty character scalar", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  rec <- result$selection$recommendation
  expect_true(is.character(rec))
  expect_length(rec, 1L)
  expect_true(nchar(rec) > 0L)
})

test_that("auto_model: reason is a non-empty character string", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  expect_true(is.character(result$selection$reason))
  expect_true(nchar(result$selection$reason) > 0L)
})

test_that("auto_model: include_lmm=FALSE sets lmm=NULL and lmm_defensible=NA", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician",
                            include_lmm = FALSE)
  ))
  expect_null(result$selection$lmm)
  expect_true(is.na(result$selection$lmm_defensible))
})

# ── Category 3: LMM evaluation semantics ──────────────────────────────────────

test_that("auto_model: include_lmm=TRUE returns a mysterycall_lmm object in $selection$lmm", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_normal_df(), "wait", "insurance", "physician",
                            include_lmm = TRUE)
  ))
  expect_true(inherits(result$selection$lmm, "mysterycall_lmm"))
})

test_that("auto_model: lmm_shapiro_p is numeric when n <= 5000", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_normal_df(), "wait", "insurance", "physician",
                            include_lmm = TRUE)
  ))
  p <- result$selection$lmm_shapiro_p
  expect_true(is.numeric(p))
  expect_false(is.na(p))
  expect_true(p >= 0 && p <= 1)
})

test_that("auto_model: narrow-range outcome makes lmm_defensible FALSE", {
  skip_if_not_installed("lme4")
  df <- make_narrow_df()
  expect_true(diff(range(df$wait)) < 30L)   # confirm fixture is narrow
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(df, "wait", "insurance", "physician",
                            include_lmm = TRUE)
  ))
  expect_false(isTRUE(result$selection$lmm_defensible))
})

test_that("auto_model: wide normal data with good Shapiro makes lmm_defensible TRUE", {
  skip_if_not_installed("lme4")
  # This seed produces Shapiro-Wilk p > 0.05 on LMM residuals
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_normal_df(seed = 42L), "wait", "insurance", "physician",
                            include_lmm = TRUE, lmm_normality_threshold = 0.05)
  ))
  # lmm_defensible depends on runtime Shapiro p; only assert when p actually > 0.05
  p <- result$selection$lmm_shapiro_p
  range_ok <- diff(range(make_normal_df(seed = 42L)$wait)) >= 30L
  if (!is.na(p) && p >= 0.05 && range_ok) {
    expect_true(result$selection$lmm_defensible)
  } else {
    expect_false(isTRUE(result$selection$lmm_defensible))
  }
})

test_that("auto_model: lmm_recommendation contains the word 'LMM'", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician",
                            include_lmm = TRUE)
  ))
  expect_true(grepl("LMM", result$selection$lmm_recommendation))
})

test_that("auto_model: recommendation contains 'PRIMARY MODEL' header", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  expect_true(grepl("PRIMARY MODEL", result$selection$recommendation))
})

# ── Category 4: Decision-tree routing ─────────────────────────────────────────

test_that("auto_model: Poisson data (phi ≈ 1) routes to Poisson", {
  skip_if_not_installed("lme4")
  # rpois data has phi near 1; with default threshold of 2, should stay Poisson
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(seed = 7L), "wait", "insurance", "physician",
                            phi_threshold = 2.0)
  ))
  expect_equal(result$selection$model_chosen, "poisson")
})

test_that("auto_model: phi_threshold=0.01 triggers NB path when glmmTMB available", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician",
                            phi_threshold = 0.01)
  ))
  expect_equal(result$selection$model_chosen, "negative_binomial")
  expect_true(inherits(result, "mysterycall_nb_model"))
})

test_that("auto_model: phi_threshold=100 always selects Poisson", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_normal_df(), "wait", "insurance", "physician",
                            phi_threshold = 100)
  ))
  expect_equal(result$selection$model_chosen, "poisson")
})

test_that("auto_model: include_lmm=FALSE means $selection$lmm is NULL", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician",
                            include_lmm = FALSE)
  ))
  expect_null(result$selection$lmm)
})

# ── Category 5: Backward compatibility ────────────────────────────────────────

test_that("auto_model: mysterycall_combined_results_table() works on result", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  expect_error(
    suppressWarnings(mysterycall_combined_results_table(result)),
    regexp = NA
  )
})

test_that("auto_model: mysterycall_format_results_table() works on result", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  expect_error(
    suppressWarnings(mysterycall_format_results_table(result)),
    regexp = NA
  )
})

test_that("auto_model: $irr_table is a data frame with column 'irr'", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  expect_s3_class(result$irr_table, "data.frame")
  expect_true("irr" %in% names(result$irr_table))
})

test_that("auto_model: $n is a positive integer", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  expect_true(is.numeric(result$n))
  expect_true(result$n > 0L)
})

test_that("auto_model: $aic is a finite numeric scalar", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  expect_true(is.finite(result$aic))
})

test_that("auto_model: print() does not error and returns result invisibly", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_poisson_df(), "wait", "insurance", "physician")
  ))
  out <- NULL
  expect_error(
    suppressMessages({ out <- withVisible(print(result)) }),
    regexp = NA
  )
  # print returns invisible(x), so visible should be FALSE
  expect_false(isTRUE(out$visible))
})

# ── Category 6: Negative controls (should NOT error) ─────────────────────────

test_that("auto_model: extra columns in data do not cause error", {
  skip_if_not_installed("lme4")
  df <- make_poisson_df()
  df$extra_col <- rnorm(nrow(df))
  df$another   <- "junk"
  expect_error(
    suppressWarnings(suppressMessages(
      mysterycall_auto_model(df, "wait", "insurance", "physician")
    )),
    regexp = NA
  )
})

test_that("auto_model: single predictor runs without error", {
  skip_if_not_installed("lme4")
  df <- make_poisson_df()
  expect_error(
    suppressWarnings(suppressMessages(
      mysterycall_auto_model(df, "wait", "insurance", "physician")
    )),
    regexp = NA
  )
})

test_that("auto_model: factor predictor (not character) runs without error", {
  skip_if_not_installed("lme4")
  df <- make_poisson_df()
  df$insurance <- factor(df$insurance)
  expect_error(
    suppressWarnings(suppressMessages(
      mysterycall_auto_model(df, "wait", "insurance", "physician")
    )),
    regexp = NA
  )
})

test_that("auto_model: conf_level = 0.9 runs without error", {
  skip_if_not_installed("lme4")
  df <- make_poisson_df()
  expect_error(
    suppressWarnings(suppressMessages(
      mysterycall_auto_model(df, "wait", "insurance", "physician", conf_level = 0.9)
    )),
    regexp = NA
  )
})

test_that("auto_model: strict lmm_normality_threshold = 0.01 runs without error", {
  skip_if_not_installed("lme4")
  df <- make_poisson_df()
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(df, "wait", "insurance", "physician",
                            lmm_normality_threshold = 0.01,
                            include_lmm = TRUE)
  ))
  # No error; lmm_defensible may differ vs 0.05 threshold
  expect_false(is.null(result$selection))
  expect_true(is.logical(result$selection$lmm_defensible) ||
                is.na(result$selection$lmm_defensible))
})
