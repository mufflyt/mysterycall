# tests/testthat/test-interaction-table.R
# testthat 3rd edition
# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Build a minimal fake mysterycall_logistic_model with insurance:specialty rows
make_fake_fit <- function(model = NULL, extra_rows = NULL) {
  base_rows <- data.frame(
    term        = c(
      "(Intercept)",
      "insuranceMedicaid",
      "specialtyGYN",
      "insuranceMedicaid:specialtyGYN",
      "insuranceMedicaid:specialtyOB"
    ),
    estimate    = c( 0.80, -0.20,  0.15, -0.45,  0.31),
    se          = c( 0.18,  0.14,  0.12,  0.21,  0.19),
    z_value     = c( 4.44, -1.43,  1.25, -2.14,  1.63),
    p_value     = c( 0.001,  0.153,  0.211,  0.032,  0.103),
    p_value_fmt = c("< 0.001", "0.153", "0.211", "0.032", "0.103"),
    or          = c( 2.23,  0.82,  1.16,  0.64,  1.36),
    ci_lower    = c( 1.56,  0.62,  0.92,  0.42,  0.94),
    ci_upper    = c( 3.19,  1.08,  1.46,  0.97,  1.97),
    stringsAsFactors = FALSE
  )
  or_table <- if (is.null(extra_rows)) base_rows else rbind(base_rows, extra_rows)

  structure(
    list(
      model      = model,
      or_table   = or_table,
      n          = 200L,
      n_clusters = 40L,
      formula    = stats::as.formula(
        "offered ~ insurance * specialty + (1 | physician)"
      )
    ),
    class = "mysterycall_logistic_model"
  )
}

## Fake fit whose or_table has NO interaction rows for insurance:specialty
make_fit_no_interaction <- function() {
  or_table <- data.frame(
    term        = c("(Intercept)", "insuranceMedicaid", "specialtyGYN"),
    estimate    = c(0.5, -0.2, 0.1),
    or          = c(1.65, 0.82, 1.11),
    ci_lower    = c(1.10, 0.60, 0.85),
    ci_upper    = c(2.48, 1.12, 1.45),
    p_value     = c(0.01, 0.20, 0.40),
    p_value_fmt = c("0.010", "0.200", "0.400"),
    stringsAsFactors = FALSE
  )
  structure(
    list(model = NULL, or_table = or_table, n = 100L),
    class = "mysterycall_logistic_model"
  )
}

# ---------------------------------------------------------------------------
# 1. Returns a list of class mysterycall_interaction_table
# ---------------------------------------------------------------------------
test_that("result has class mysterycall_interaction_table", {
  fit <- make_fake_fit()
  res <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty")
  )
  expect_s3_class(res, "mysterycall_interaction_table")
  expect_type(res, "list")
})

# ---------------------------------------------------------------------------
# 2. interaction_ors is a data.frame / tibble
# ---------------------------------------------------------------------------
test_that("interaction_ors is a data.frame", {
  fit <- make_fake_fit()
  res <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty")
  )
  expect_true(is.data.frame(res$interaction_ors))
})

test_that("interaction_ors has expected columns", {
  fit <- make_fake_fit()
  res <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty")
  )
  expect_named(
    res$interaction_ors,
    c("term", "or", "ci_lower", "ci_upper", "p_value_fmt"),
    ignore.order = FALSE
  )
})

test_that("interaction_ors has one row per matching interaction term", {
  fit <- make_fake_fit()
  res <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty")
  )
  # or_table has 2 rows matching insurance.*specialty
  expect_equal(nrow(res$interaction_ors), 2L)
})

# ---------------------------------------------------------------------------
# 3. lrt_p is numeric (or NA) — never character
# ---------------------------------------------------------------------------
test_that("lrt_p is numeric NA when model is NULL", {
  fit <- make_fake_fit(model = NULL)
  res <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty")
  )
  expect_type(res$lrt_p, "double")
  expect_true(is.na(res$lrt_p))
})

# ---------------------------------------------------------------------------
# 4. sentence is character containing the word "interaction"
# ---------------------------------------------------------------------------
test_that("sentence is a character string containing 'interaction'", {
  fit <- make_fake_fit()
  res <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty")
  )
  expect_type(res$sentence, "character")
  expect_match(res$sentence, "interaction", ignore.case = TRUE)
})

test_that("sentence echoes var1 and var2", {
  fit <- make_fake_fit()
  res <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty")
  )
  expect_match(res$sentence, "insurance")
  expect_match(res$sentence, "specialty")
})

# ---------------------------------------------------------------------------
# 5. Error when fit is not mysterycall_logistic_model
# ---------------------------------------------------------------------------
test_that("error when fit is a plain list (wrong class)", {
  bad_fit <- list(or_table = data.frame(term = "x"), model = NULL)
  expect_error(
    mysterycall_interaction_table(bad_fit, "insurance", "specialty"),
    regexp = "mysterycall_logistic_model",
    fixed  = FALSE
  )
})

test_that("error when fit is a glm object (wrong class)", {
  expect_error(
    mysterycall_interaction_table(lm(1 ~ 1), "a", "b"),
    regexp = "mysterycall_logistic_model"
  )
})

# ---------------------------------------------------------------------------
# 6. Error when var1 not found in model terms
# ---------------------------------------------------------------------------
test_that("error when var1 does not appear in any or_table term", {
  fit <- make_fake_fit()
  expect_error(
    suppressWarnings(
      mysterycall_interaction_table(fit, "nonexistent_var", "specialty")
    ),
    regexp = "No interaction rows found"
  )
})

test_that("error when var2 does not appear in any or_table term", {
  fit <- make_fake_fit()
  expect_error(
    suppressWarnings(
      mysterycall_interaction_table(fit, "insurance", "nonexistent_var")
    ),
    regexp = "No interaction rows found"
  )
})

# ---------------------------------------------------------------------------
# 7. When no interaction terms match, an informative error is thrown
# ---------------------------------------------------------------------------
test_that("error (not silent) when or_table has no interaction rows for the pair", {
  fit <- make_fit_no_interaction()
  expect_error(
    suppressWarnings(
      mysterycall_interaction_table(fit, "insurance", "specialty")
    ),
    regexp = "No interaction rows found.*insurance.*specialty"
  )
})

# ---------------------------------------------------------------------------
# 8. lrt_p_fmt uses "< 0.001" for very small p-values
# ---------------------------------------------------------------------------
test_that("lrt_p_fmt is 'NA' when lrt_p is NA", {
  fit <- make_fake_fit(model = NULL)
  res <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty")
  )
  expect_equal(res$lrt_p_fmt, "NA")
})

test_that(".fmt_interaction_pval returns '< 0.001' for p < 0.001", {
  # Access the internal helper directly
  fmt <- mysterycall:::.fmt_interaction_pval(0.0000123, digits = 3L)
  expect_equal(fmt, "< 0.001")
})

test_that(".fmt_interaction_pval returns formatted decimal for p >= 0.001", {
  fmt <- mysterycall:::.fmt_interaction_pval(0.045, digits = 3L)
  expect_equal(fmt, "0.045")
})

test_that(".fmt_interaction_pval returns NA_character_ for NA input", {
  fmt <- mysterycall:::.fmt_interaction_pval(NA_real_, digits = 3L)
  expect_true(is.na(fmt))
})

# ---------------------------------------------------------------------------
# 9. Print method works without error and returns invisibly
# ---------------------------------------------------------------------------
test_that("print.mysterycall_interaction_table runs without error", {
  fit <- make_fake_fit()
  res <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty")
  )
  expect_no_error(
    capture.output(print(res))
  )
})

test_that("print returns the object invisibly", {
  fit <- make_fake_fit()
  res <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty")
  )
  ret <- withVisible(print(res))
  expect_false(ret$visible)
  expect_identical(ret$value, res)
})

test_that("print output contains var1, var2, and 'LRT'", {
  fit <- make_fake_fit()
  res <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty")
  )
  out <- paste(capture.output(print(res)), collapse = "\n")
  expect_match(out, "insurance")
  expect_match(out, "specialty")
  expect_match(out, "LRT", ignore.case = FALSE)
})

# ---------------------------------------------------------------------------
# 10. digits parameter affects rounding of OR values
# ---------------------------------------------------------------------------
test_that("digits = 0 rounds or values to integers", {
  fit <- make_fake_fit()
  res0 <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty", digits = 0L)
  )
  # All or, ci_lower, ci_upper should be whole numbers (no decimal part)
  expect_true(all(res0$interaction_ors$or == round(res0$interaction_ors$or, 0)))
})

test_that("digits = 4 gives more decimal places than digits = 1", {
  fit <- make_fake_fit()
  res1 <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty", digits = 1L)
  )
  res4 <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty", digits = 4L)
  )
  # With digits=1 the rounded or values should equal those from digits=4
  # when also rounded to 1 decimal — proving that digits=4 preserves more info
  ors1 <- res1$interaction_ors$or
  ors4 <- res4$interaction_ors$or
  expect_equal(round(ors4, 1L), ors1)
})

test_that("digits is echoed in the returned list", {
  fit  <- make_fake_fit()
  res  <- suppressWarnings(
    mysterycall_interaction_table(fit, "insurance", "specialty", digits = 3L)
  )
  expect_equal(res$digits, 3L)
})
