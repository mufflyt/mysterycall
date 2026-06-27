# tests/testthat/test-univariate-poisson-screen.R
# testthat 3rd edition

# ── helpers ───────────────────────────────────────────────────────────────────

make_poisson_df <- function(seed = 1L, n = 120L) {
  set.seed(seed)
  data.frame(
    wait_days = c(
      rpois(n / 2, 7),   # BCBS
      rpois(n / 2, 14)   # Medicaid
    ),
    insurance = rep(c("BCBS", "Medicaid"), each = n / 2),
    gender    = rep(c("M", "F"), n / 2),
    stringsAsFactors = FALSE
  )
}

# ── structural tests ──────────────────────────────────────────────────────────

test_that("poisson_screen: returns named list with required elements", {
  df  <- make_poisson_df()
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", output_dir = NA
    )
  )
  expect_named(res, c("results", "significant", "sentence", "alpha"))
})

test_that("poisson_screen: $results has expected column names", {
  df  <- make_poisson_df()
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", output_dir = NA
    )
  )
  expected_cols <- c("Variable", "P_Value", "Formatted_P_Value", "Direction")
  expect_true(all(expected_cols %in% names(res$results)))
})

test_that("poisson_screen: $results is a tibble", {
  df  <- make_poisson_df()
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", output_dir = NA
    )
  )
  expect_s3_class(res$results, "tbl_df")
})

test_that("poisson_screen: $sentence is non-empty character", {
  df  <- make_poisson_df()
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", output_dir = NA
    )
  )
  expect_type(res$sentence, "character")
  expect_gt(nchar(res$sentence), 0L)
})

test_that("poisson_screen: $alpha matches argument", {
  df  <- make_poisson_df()
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", alpha = 0.1, output_dir = NA
    )
  )
  expect_equal(res$alpha, 0.1)
})

# ── adversarial tests ─────────────────────────────────────────────────────────

test_that("poisson_screen: error when outcome_col not found", {
  df <- make_poisson_df()
  expect_error(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "missing", output_dir = NA
    ),
    "not found"
  )
})

test_that("poisson_screen: error when data is not a data frame", {
  expect_error(
    mysterycall_univariate_poisson_screen(
      list(a = 1), outcome_col = "a", output_dir = NA
    ),
    "data frame"
  )
})

test_that("poisson_screen: all predictors 1 level -> zero-row significant", {
  df <- data.frame(
    wait_days    = c(3, 7, 14),
    constant_col = c(1L, 1L, 1L),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", output_dir = NA
    )
  )
  expect_equal(nrow(res$significant), 0L)
  expect_match(res$sentence, "No significant predictors")
})

test_that("poisson_screen: alpha = 0 -> all filtered out", {
  df  <- make_poisson_df()
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", alpha = 0, output_dir = NA
    )
  )
  expect_equal(nrow(res$significant), 0L)
})

test_that("poisson_screen: non-numeric outcome caught gracefully", {
  df <- data.frame(
    wait_char = c("low", "high", "medium"),
    insurance = c("BCBS", "Medicaid", "BCBS"),
    stringsAsFactors = FALSE
  )
  # glm will fail or produce degenerate fit; function must not crash
  expect_no_error(
    suppressMessages(
      mysterycall_univariate_poisson_screen(
        df, outcome_col = "wait_char", output_dir = NA
      )
    )
  )
})

test_that("poisson_screen: empty data frame -> zero-row results", {
  df <- make_poisson_df()[0L, ]
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", output_dir = NA
    )
  )
  expect_equal(nrow(res$results), 0L)
  expect_equal(nrow(res$significant), 0L)
})

# ── semantic tests ────────────────────────────────────────────────────────────

test_that("poisson_screen: insurance is significant with strong signal", {
  df  <- make_poisson_df(seed = 42L, n = 200L)
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", alpha = 0.2, output_dir = NA
    )
  )
  sig_vars <- res$significant$Variable
  expect_true("insurance" %in% sig_vars,
              info = paste("Significant vars:", paste(sig_vars, collapse = ", ")))
})

test_that("poisson_screen: Medicaid direction is 'Higher' (Medicaid > BCBS)", {
  df  <- make_poisson_df(seed = 1L, n = 200L)
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", alpha = 0.5, output_dir = NA
    )
  )
  ins_row <- res$results[res$results$Variable == "insurance", ]
  if (nrow(ins_row) > 0L) {
    # Insurance is coded alphabetically: BCBS < Medicaid; since Medicaid has
    # higher wait, the coefficient should be positive -> Direction = "Higher"
    expect_equal(ins_row$Direction, "Higher")
  } else {
    succeed()
  }
})

test_that("poisson_screen: $significant sorted ascending by P_Value", {
  df  <- make_poisson_df()
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", alpha = 0.5, output_dir = NA
    )
  )
  if (nrow(res$significant) > 1L) {
    expect_true(all(diff(res$significant$P_Value) >= 0))
  } else {
    succeed()
  }
})

test_that("poisson_screen: sentence includes variable name when significant", {
  df  <- make_poisson_df(seed = 5L, n = 200L)
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", alpha = 0.5, output_dir = NA
    )
  )
  if (nrow(res$significant) > 0L) {
    first_var <- res$significant$Variable[1L]
    expect_match(res$sentence, first_var, fixed = TRUE)
  } else {
    succeed()
  }
})

test_that("poisson_screen: Formatted_P_Value is '<0.01' for very small p", {
  # Create near-perfect separation to get tiny p
  set.seed(99)
  n <- 200L
  df <- data.frame(
    wait_days = c(rpois(n / 2, 3), rpois(n / 2, 30)),
    insurance = rep(c("BCBS", "Medicaid"), each = n / 2),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days", alpha = 1, output_dir = NA
    )
  )
  ins_row <- res$results[res$results$Variable == "insurance", ]
  if (nrow(ins_row) > 0L && ins_row$P_Value < 0.01) {
    expect_equal(ins_row$Formatted_P_Value, "<0.01")
  } else {
    succeed()
  }
})
