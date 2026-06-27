# tests/testthat/test-interaction-screen.R
# testthat 3rd edition

# ── helpers ───────────────────────────────────────────────────────────────────

make_factor_df <- function(seed = 1L, n = 120L) {
  set.seed(seed)
  n_phys <- 20L
  data.frame(
    business_days_until_appointment = rpois(n, 10),
    insurance = factor(rep(c("BCBS", "Medicaid"), n / 2)),
    gender    = factor(rep(c("M", "F"), n / 2)),
    setting   = factor(sample(c("Academic", "Private"), n, replace = TRUE)),
    last      = rep(paste0("Dr", seq_len(n_phys)), each = n / n_phys),
    stringsAsFactors = FALSE
  )
}

# ── structural tests ──────────────────────────────────────────────────────────

test_that("interaction_screen: returns named list with required elements", {
  skip_if_not_installed("lmerTest")
  df  <- make_factor_df()
  res <- suppressMessages(
    mysterycall_interaction_screen(df, output_dir = NA)
  )
  expect_named(res,
    c("interaction_results", "aic_results", "best_interaction",
      "n_pairs_tested", "sentence"))
})

test_that("interaction_screen: $interaction_results has expected columns", {
  skip_if_not_installed("lmerTest")
  df  <- make_factor_df()
  res <- suppressMessages(
    mysterycall_interaction_screen(df, output_dir = NA)
  )
  expect_true(all(c("Interaction", "P_Value") %in%
                    names(res$interaction_results)))
})

test_that("interaction_screen: $aic_results has expected columns", {
  skip_if_not_installed("lmerTest")
  df  <- make_factor_df()
  res <- suppressMessages(
    mysterycall_interaction_screen(df, output_dir = NA)
  )
  expect_true(all(c("Interaction", "AIC") %in% names(res$aic_results)))
})

test_that("interaction_screen: $sentence is non-empty character", {
  skip_if_not_installed("lmerTest")
  df  <- make_factor_df()
  res <- suppressMessages(
    mysterycall_interaction_screen(df, output_dir = NA)
  )
  expect_type(res$sentence, "character")
  expect_gt(nchar(res$sentence), 0L)
})

test_that("interaction_screen: $n_pairs_tested is integer >= 0", {
  skip_if_not_installed("lmerTest")
  df  <- make_factor_df()
  res <- suppressMessages(
    mysterycall_interaction_screen(df, output_dir = NA)
  )
  expect_type(res$n_pairs_tested, "integer")
  expect_gte(res$n_pairs_tested, 0L)
})

# ── adversarial tests ─────────────────────────────────────────────────────────

test_that("interaction_screen: error when outcome_col not found", {
  df <- make_factor_df()
  expect_error(
    mysterycall_interaction_screen(df, outcome_col = "missing",
                                   output_dir = NA),
    "not found"
  )
})

test_that("interaction_screen: error when random_effect not found", {
  df <- make_factor_df()
  expect_error(
    mysterycall_interaction_screen(df, random_effect = "badcol",
                                   output_dir = NA),
    "not found"
  )
})

test_that("interaction_screen: fewer than 2 factor cols -> 0 pairs, informative message", {
  # Only one factor column (insurance); gender and setting are not factors here
  df <- data.frame(
    business_days_until_appointment = rpois(30, 10),
    insurance = factor(rep(c("BCBS", "Medicaid"), 15)),
    gender    = rep(c("M", "F"), 15),   # character, not factor
    last      = rep(paste0("Dr", 1:5), each = 6),
    stringsAsFactors = FALSE
  )
  expect_message(
    res <- mysterycall_interaction_screen(df, output_dir = NA),
    "fewer than 2"
  )
  expect_equal(res$n_pairs_tested, 0L)
})

test_that("interaction_screen: max_pairs cap respected", {
  skip_if_not_installed("lmerTest")
  # Create 5 factor predictors -> 10 possible pairs; cap at 3
  set.seed(1)
  n <- 60L
  df <- data.frame(
    business_days_until_appointment = rpois(n, 10),
    f1 = factor(rep(c("A", "B"), n / 2)),
    f2 = factor(rep(c("X", "Y"), n / 2)),
    f3 = factor(sample(c("P", "Q"), n, replace = TRUE)),
    f4 = factor(sample(c("U", "V"), n, replace = TRUE)),
    f5 = factor(sample(c("C", "D"), n, replace = TRUE)),
    last = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_interaction_screen(df, max_pairs = 3L, output_dir = NA)
  )
  expect_lte(res$n_pairs_tested, 3L)
})

test_that("interaction_screen: error when data is not a data frame", {
  expect_error(
    mysterycall_interaction_screen(list(a = 1), output_dir = NA),
    "data frame"
  )
})

# ── semantic tests ────────────────────────────────────────────────────────────

test_that("interaction_screen: $aic_results sorted ascending by AIC", {
  skip_if_not_installed("lmerTest")
  df  <- make_factor_df()
  res <- suppressMessages(
    mysterycall_interaction_screen(df, output_dir = NA)
  )
  if (nrow(res$aic_results) > 1L) {
    aic_vals <- res$aic_results$AIC[!is.na(res$aic_results$AIC)]
    expect_true(all(diff(aic_vals) >= 0))
  } else {
    succeed()
  }
})

test_that("interaction_screen: $best_interaction is NULL or single-row tibble", {
  skip_if_not_installed("lmerTest")
  df  <- make_factor_df()
  res <- suppressMessages(
    mysterycall_interaction_screen(df, output_dir = NA)
  )
  if (!is.null(res$best_interaction)) {
    expect_s3_class(res$best_interaction, "tbl_df")
    expect_equal(nrow(res$best_interaction), 1L)
  } else {
    succeed()
  }
})

test_that("interaction_screen: $n_pairs_tested matches combn count for small data", {
  skip_if_not_installed("lmerTest")
  df <- make_factor_df(n = 60L)
  # 3 factor cols (insurance, gender, setting) -> 3 pairs
  res <- suppressMessages(
    mysterycall_interaction_screen(df, max_pairs = 100L, output_dir = NA)
  )
  expect_equal(res$n_pairs_tested, 3L)
})

test_that("interaction_screen: sentence mentions AIC when interactions found", {
  skip_if_not_installed("lmerTest")
  df  <- make_factor_df()
  res <- suppressMessages(
    mysterycall_interaction_screen(df, output_dir = NA)
  )
  if (!is.null(res$best_interaction)) {
    expect_match(res$sentence, "AIC")
  } else {
    succeed()
  }
})

# ── p_adjust_method tests ─────────────────────────────────────────────────────

test_that("interaction_screen: p_adjust_method='BH' adds P_Value_Adjusted column", {
  skip_if_not_installed("lmerTest")
  df  <- make_factor_df()
  res <- suppressMessages(
    mysterycall_interaction_screen(df, alpha = 1, p_adjust_method = "BH",
                                   output_dir = NA)
  )
  # alpha=1 ensures all pairs appear in interaction_results
  expect_true("P_Value_Adjusted" %in% names(res$interaction_results))
})

test_that("interaction_screen: p_adjust_method='bonferroni' gives adjusted >= raw p", {
  skip_if_not_installed("lmerTest")
  df  <- make_factor_df()
  res <- suppressMessages(
    mysterycall_interaction_screen(df, alpha = 1,
                                   p_adjust_method = "bonferroni",
                                   output_dir = NA)
  )
  expect_true("P_Value_Adjusted" %in% names(res$interaction_results))
  if (nrow(res$interaction_results) > 0L) {
    # Bonferroni always inflates (adjusted >= raw)
    expect_true(all(
      res$interaction_results$P_Value_Adjusted >=
        res$interaction_results$P_Value
    ))
  } else {
    succeed()
  }
})

test_that("interaction_screen: p_adjust_method='none' produces no P_Value_Adjusted column", {
  skip_if_not_installed("lmerTest")
  df  <- make_factor_df()
  res <- suppressMessages(
    mysterycall_interaction_screen(df, p_adjust_method = "none",
                                   output_dir = NA)
  )
  expect_false("P_Value_Adjusted" %in% names(res$interaction_results))
})

test_that("interaction_screen: p_adjust_method='invalid_xyz' errors", {
  skip_if_not_installed("lmerTest")
  df  <- make_factor_df()
  expect_error(
    suppressMessages(
      mysterycall_interaction_screen(df, p_adjust_method = "invalid_xyz",
                                     output_dir = NA)
    )
  )
})
