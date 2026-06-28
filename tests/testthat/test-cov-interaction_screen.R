library(testthat)
library(mysterycall)

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------

# Enough rows for lmerTest::lmer() to converge with two factor predictors
# and a random intercept.
make_screen_df <- function(n_per_cell = 8L) {
  set.seed(122)
  insurance <- rep(c("Medicaid", "BCBS"), each = n_per_cell * 2L)
  gender    <- rep(rep(c("M", "F"), each = n_per_cell), 2L)
  last      <- paste0("Dr", rep(seq_len(n_per_cell * 2L),
                                length.out = length(insurance)))
  days      <- rpois(length(insurance), lambda = 8)
  data.frame(
    business_days_until_appointment = days,
    insurance = factor(insurance),
    gender    = factor(gender),
    last      = last,
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

test_that("mysterycall_interaction_screen returns correct list structure", {
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("tibble")

  df  <- make_screen_df()
  res <- suppressMessages(suppressWarnings(
    mysterycall_interaction_screen(df, output_dir = NA)
  ))

  expect_type(res, "list")
  expect_named(res, c("interaction_results", "aic_results",
                      "best_interaction", "n_pairs_tested", "sentence"),
               ignore.order = FALSE)

  # interaction_results must be a tibble with the right columns
  expect_s3_class(res$interaction_results, "tbl_df")
  expect_true(all(c("Interaction", "P_Value") %in% names(res$interaction_results)))

  # aic_results must be a tibble with the right columns
  expect_s3_class(res$aic_results, "tbl_df")
  expect_true(all(c("Interaction", "AIC") %in% names(res$aic_results)))

  # n_pairs_tested must be a non-negative integer
  expect_true(is.numeric(res$n_pairs_tested) || is.integer(res$n_pairs_tested))
  expect_gte(res$n_pairs_tested, 0L)

  # sentence must be a non-empty character scalar
  expect_type(res$sentence, "character")
  expect_length(res$sentence, 1L)
  expect_gt(nchar(res$sentence), 0L)
})

test_that("mysterycall_interaction_screen drops NA rows in outcome_col", {
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("tibble")

  df <- make_screen_df()
  # Inject NAs into the outcome column
  df$business_days_until_appointment[c(1L, 5L, 10L)] <- NA

  res <- suppressMessages(suppressWarnings(
    mysterycall_interaction_screen(df, output_dir = NA)
  ))

  # Function should still complete successfully
  expect_type(res, "list")
  expect_named(res, c("interaction_results", "aic_results",
                      "best_interaction", "n_pairs_tested", "sentence"))
})

test_that("mysterycall_interaction_screen returns empty results with <2 factor cols", {
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("tibble")

  set.seed(122)
  df_no_factors <- data.frame(
    business_days_until_appointment = rpois(30L, 8),
    insurance = rep(c("Medicaid", "BCBS"), 15L),   # character, not factor
    last      = rep(paste0("Dr", 1:5), 6L),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(suppressWarnings(
    mysterycall_interaction_screen(df_no_factors, output_dir = NA)
  ))

  expect_equal(res$n_pairs_tested, 0L)
  expect_equal(nrow(res$interaction_results), 0L)
  expect_equal(nrow(res$aic_results), 0L)
  expect_null(res$best_interaction)
})

test_that("mysterycall_interaction_screen errors on bad input", {
  # non-data-frame
  expect_error(
    mysterycall_interaction_screen(list(a = 1)),
    regexp = "data frame"
  )

  # missing outcome column
  df <- make_screen_df()
  expect_error(
    mysterycall_interaction_screen(df, outcome_col = "nonexistent_col",
                                   output_dir = NA),
    regexp = "nonexistent_col"
  )

  # missing random_effect column
  expect_error(
    mysterycall_interaction_screen(df, random_effect = "missing_re",
                                   output_dir = NA),
    regexp = "missing_re"
  )
})

test_that("mysterycall_interaction_screen respects p_adjust_method = 'BH'", {
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("tibble")

  df  <- make_screen_df()
  res <- suppressMessages(suppressWarnings(
    mysterycall_interaction_screen(df, p_adjust_method = "BH", output_dir = NA)
  ))

  # When adjustment is applied the result tibble must contain P_Value_Adjusted
  if (nrow(res$interaction_results) > 0L) {
    expect_true("P_Value_Adjusted" %in% names(res$interaction_results))
    expect_true(all(res$interaction_results$P_Value_Adjusted >= 0))
    expect_true(all(res$interaction_results$P_Value_Adjusted <= 1))
  }

  # sentence must mention AIC or "No significant interactions"
  expect_true(
    grepl("AIC", res$sentence, fixed = TRUE) ||
      grepl("No significant", res$sentence, fixed = TRUE)
  )
})
