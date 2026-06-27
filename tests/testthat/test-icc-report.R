testthat::local_edition(3)

# ── Shared test fixture ────────────────────────────────────────────────────────

make_icc_df <- function(seed = 42L,
                        callers     = c("Alice", "Bob", "Carol"),
                        n_per       = 20L,
                        probs       = c(0.70, 0.65, 0.68),
                        group_col   = FALSE) {
  set.seed(seed)
  n     <- length(callers) * n_per
  cids  <- rep(callers, each = n_per)
  outs  <- unlist(mapply(function(p) rbinom(n_per, 1L, p), probs,
                         SIMPLIFY = FALSE))
  df    <- data.frame(
    caller_id = cids,
    offered   = outs,
    stringsAsFactors = FALSE
  )
  if (group_col) {
    df$insurance <- rep(c("Medicaid", "BCBS"), length.out = n)
  }
  df
}

# ── 1. Return class ────────────────────────────────────────────────────────────

test_that("mysterycall_icc_report returns an object of class mysterycall_icc_report", {
  rpt <- mysterycall_icc_report(make_icc_df())
  expect_s3_class(rpt, "mysterycall_icc_report")
})

# ── 2. icc is numeric and in [0, 1] ───────────────────────────────────────────

test_that("icc element is numeric and bounded in [0, 1]", {
  rpt <- mysterycall_icc_report(make_icc_df())
  expect_true(is.numeric(rpt$icc))
  expect_length(rpt$icc, 1L)
  expect_gte(rpt$icc, 0)
  expect_lte(rpt$icc, 1)
})

# ── 3. kappa is numeric ────────────────────────────────────────────────────────

test_that("kappa element is numeric", {
  rpt <- mysterycall_icc_report(make_icc_df())
  expect_true(is.numeric(rpt$kappa))
  expect_length(rpt$kappa, 1L)
})

# ── 4. n_callers matches number of unique callers ─────────────────────────────

test_that("n_callers equals the number of distinct callers in data", {
  df  <- make_icc_df(callers = c("Alice", "Bob", "Carol"))
  rpt <- mysterycall_icc_report(df)
  expect_equal(rpt$n_callers, 3L)
})

test_that("n_callers reflects a two-caller data set correctly", {
  df  <- make_icc_df(callers = c("X", "Y"), probs = c(0.6, 0.8))
  rpt <- mysterycall_icc_report(df)
  expect_equal(rpt$n_callers, 2L)
})

# ── 5. n_calls matches nrow(data) for complete cases ──────────────────────────

test_that("n_calls equals nrow(data) when there are no missing values", {
  df  <- make_icc_df()
  rpt <- mysterycall_icc_report(df)
  expect_equal(rpt$n_calls, nrow(df))
})

# ── 6. sentence is a character string containing "ICC" ────────────────────────

test_that("sentence is a single character string", {
  rpt <- mysterycall_icc_report(make_icc_df())
  expect_true(is.character(rpt$sentence))
  expect_length(rpt$sentence, 1L)
})

test_that("sentence contains the substring 'ICC'", {
  rpt <- mysterycall_icc_report(make_icc_df())
  expect_match(rpt$sentence, "ICC", fixed = TRUE)
})

# ── 7. table has required columns ────────────────────────────────────────────

test_that("table has caller and accept_rate columns", {
  rpt <- mysterycall_icc_report(make_icc_df())
  expect_true(is.data.frame(rpt$table))
  expect_true("caller"      %in% names(rpt$table))
  expect_true("accept_rate" %in% names(rpt$table))
})

test_that("table has one row per distinct caller", {
  df  <- make_icc_df(callers = c("Alice", "Bob", "Carol"))
  rpt <- mysterycall_icc_report(df)
  expect_equal(nrow(rpt$table), 3L)
})

# ── 8. Error when data has no rows ───────────────────────────────────────────

test_that("error when data has zero rows", {
  df_empty <- make_icc_df()[0L, ]
  expect_error(
    mysterycall_icc_report(df_empty),
    regexp = "2 distinct callers"
  )
})

# ── 9. Error when caller_col not in data ────────────────────────────────────

test_that("error when caller_col is absent from data", {
  df <- make_icc_df()
  expect_error(
    mysterycall_icc_report(df, caller_col = "no_such_col"),
    regexp = "not found"
  )
})

# ── 10. Error when outcome_col not in data ───────────────────────────────────

test_that("error when outcome_col is absent from data", {
  df <- make_icc_df()
  expect_error(
    mysterycall_icc_report(df, outcome_col = "no_such_col"),
    regexp = "not found"
  )
})

# ── 11. Warning when outcome not strictly binary ──────────────────────────────

test_that("warning issued when outcome contains values outside {0, 1}", {
  set.seed(7L)
  df <- data.frame(
    caller_id = rep(c("Alice", "Bob"), each = 15L),
    offered   = c(rbinom(15L, 1L, 0.5), sample(2L:5L, 15L, replace = TRUE)),
    stringsAsFactors = FALSE
  )
  expect_warning(
    mysterycall_icc_report(df),
    regexp = "coercing"
  )
})

# ── 12. With 2 callers kappa is finite ───────────────────────────────────────

test_that("kappa is finite with exactly 2 callers", {
  set.seed(99L)
  df <- data.frame(
    caller_id = rep(c("P", "Q"), each = 30L),
    offered   = c(rbinom(30L, 1L, 0.55), rbinom(30L, 1L, 0.75)),
    stringsAsFactors = FALSE
  )
  rpt <- mysterycall_icc_report(df)
  expect_true(is.finite(rpt$kappa))
})

# ── 13. Works with group_col provided ────────────────────────────────────────

test_that("group_col produces a non-NULL group_results list", {
  df  <- make_icc_df(group_col = TRUE)
  rpt <- mysterycall_icc_report(df, group_col = "insurance")
  expect_false(is.null(rpt$group_results))
  expect_true(is.list(rpt$group_results))
})

test_that("group_results has one entry per group level", {
  df     <- make_icc_df(group_col = TRUE)
  rpt    <- mysterycall_icc_report(df, group_col = "insurance")
  groups <- sort(unique(df$insurance))
  expect_equal(sort(names(rpt$group_results)), groups)
})

test_that("each element of group_results is also a mysterycall_icc_report", {
  df  <- make_icc_df(group_col = TRUE)
  rpt <- mysterycall_icc_report(df, group_col = "insurance")
  for (g in rpt$group_results) {
    expect_s3_class(g, "mysterycall_icc_report")
  }
})
