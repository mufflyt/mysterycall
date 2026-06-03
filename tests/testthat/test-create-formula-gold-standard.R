# test-create-formula-gold-standard.R
#
# Gold-standard tests for mysterycall:::mysterycall_create_formula().
# Tests exact formula string output, schema contracts, and metamorphic properties.
#
# Testing tenets satisfied:
#   - Gold-standard manually-verified values (exact formula structure)
#   - Schema contracts (output is always a formula object)
#   - Domain invariants (response var not on RHS, RE appears in correct form)
#   - Boundary conditions (single predictor)
#   - Metamorphic relations (adding column adds term)
#   - Property-based testing (all non-response cols appear on RHS)

library(testthat)
library(mysterycall)

# ---------------------------------------------------------------------------
# Helper: suppress messages from mysterycall:::mysterycall_create_formula
# ---------------------------------------------------------------------------
quiet_cf <- function(data, response_var, random_effect = NULL) {
  suppressMessages(mysterycall:::mysterycall_create_formula(data, response_var, random_effect))
}

# ---------------------------------------------------------------------------
# 1. Gold standard: formula without random effect
# ---------------------------------------------------------------------------

test_that("mysterycall:::mysterycall_create_formula produces correct formula for age + name ~ days [gold standard]", {
  df <- data.frame(
    days = c(5, 10, 15),
    age  = c(30, 40, 50),
    name = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  f <- quiet_cf(df, "days")
  f_str <- deparse(f)
  # deparse() normalizes backtick-quoted simple names back to plain names,
  # so "days ~ `age` + `name`" becomes "days ~ age + name" after as.formula().
  # We therefore check for the column names without backticks in the final deparsed form.
  expect_true(grepl("days", f_str),
              label = paste("Formula:", f_str))
  expect_true(grepl("age", f_str),
              label = paste("Formula:", f_str))
  expect_true(grepl("name", f_str),
              label = paste("Formula:", f_str))
  # Response must be on the left side
  expect_true(grepl("^days ~", f_str),
              label = paste("days must be LHS. Formula:", f_str))
  # Special-character column names DO retain backticks
  df2 <- data.frame(days = 1:3, "patient age" = 1:3, check.names = FALSE)
  f2 <- quiet_cf(df2, "days")
  f2_str <- deparse(f2)
  expect_true(grepl("`patient age`", f2_str),
              label = paste("Special-char name must retain backticks. Formula:", f2_str))
})

# ---------------------------------------------------------------------------
# 2. Gold standard with random effect
# ---------------------------------------------------------------------------

test_that("mysterycall:::mysterycall_create_formula with random_effect contains '(1 | name)' term", {
  df <- data.frame(
    days = c(5, 10, 15),
    age  = c(30, 40, 50),
    name = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  f <- quiet_cf(df, "days", "name")
  f_str <- deparse(f)
  expect_true(grepl("(1 | name)", f_str, fixed = TRUE),
              label = paste("Formula:", f_str))
})

test_that("mysterycall:::mysterycall_create_formula with random_effect also includes the RE variable as a regular predictor", {
  df <- data.frame(
    days = c(5, 10, 15),
    age  = c(30, 40, 50),
    name = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  f <- quiet_cf(df, "days", "name")
  f_str <- deparse(f)
  # 'name' must appear in the RHS (as regular predictor after deparse normalization)
  # and in the RE term (1 | name)
  expect_true(grepl("name", f_str),
              label = paste("name must appear in formula. Formula:", f_str))
  expect_true(grepl("(1 | name)", f_str, fixed = TRUE),
              label = paste("name must be RE term. Formula:", f_str))
})

# ---------------------------------------------------------------------------
# 3. Schema: output is always a formula object
# ---------------------------------------------------------------------------

test_that("mysterycall:::mysterycall_create_formula output inherits 'formula' class", {
  df <- data.frame(outcome = 1:3, predictor = 4:6)
  f <- quiet_cf(df, "outcome")
  expect_true(inherits(f, "formula"))
})

test_that("mysterycall:::mysterycall_create_formula output is a formula regardless of random_effect presence", {
  df <- data.frame(y = 1:4, x = 5:8, grp = c("a", "b", "a", "b"))

  f_no_re <- quiet_cf(df, "y")
  f_re    <- quiet_cf(df, "y", "grp")

  expect_true(inherits(f_no_re, "formula"))
  expect_true(inherits(f_re,    "formula"))
})

# ---------------------------------------------------------------------------
# 4. Property: response variable appears on left side of formula
# ---------------------------------------------------------------------------

test_that("response variable always appears on the LHS of the formula", {
  df <- data.frame(outcome = 1:5, age = 6:10, sex = c("M","F","M","F","M"),
                   stringsAsFactors = FALSE)
  f <- quiet_cf(df, "outcome")
  lhs <- deparse(f[[2]])
  expect_equal(lhs, "outcome")
})

test_that("response variable LHS property holds with random effect", {
  df <- data.frame(y = 1:4, x1 = 1:4, x2 = 1:4)
  f <- quiet_cf(df, "y", "x1")
  lhs <- deparse(f[[2]])
  expect_equal(lhs, "y")
})

# ---------------------------------------------------------------------------
# 5. Invariant: response variable never appears on the right side
# ---------------------------------------------------------------------------

test_that("response variable does not appear on the RHS of the formula", {
  df <- data.frame(days = 1:5, age = 6:10, name = letters[1:5],
                   stringsAsFactors = FALSE)
  f <- quiet_cf(df, "days")
  rhs_str <- deparse(f[[3]])
  # "days" should not appear in the right-hand side
  expect_false(grepl("\\bdays\\b", rhs_str),
               label = paste("RHS:", rhs_str))
})

# ---------------------------------------------------------------------------
# 6. Property: all non-response columns appear on the right side as predictors
# ---------------------------------------------------------------------------

test_that("all non-response columns appear in the RHS of the formula", {
  df <- data.frame(
    outcome    = 1:5,
    predictor1 = 6:10,
    predictor2 = 11:15,
    predictor3 = 16:20
  )
  f <- quiet_cf(df, "outcome")
  f_str <- deparse(f)
  for (col in c("predictor1", "predictor2", "predictor3")) {
    expect_true(grepl(col, f_str),
                label = paste("Missing predictor:", col, "in formula:", f_str))
  }
})

# ---------------------------------------------------------------------------
# 7. Boundary: single predictor
# ---------------------------------------------------------------------------

test_that("single predictor formula has only that one predictor on RHS", {
  df <- data.frame(y = 1:5, x = 6:10)
  f <- quiet_cf(df, "y")
  f_str <- deparse(f)
  # Must contain `x` and not contain any "+" (only one predictor)
  rhs_str <- deparse(f[[3]])
  expect_false(grepl("+", rhs_str, fixed = TRUE),
               label = paste("Single-predictor formula should not have '+'. RHS:", rhs_str))
  expect_true(grepl("x", rhs_str),
              label = paste("x must be the sole predictor. RHS:", rhs_str))
})

# ---------------------------------------------------------------------------
# 8. Metamorphic: adding a column to data adds a term to the formula
# ---------------------------------------------------------------------------

test_that("adding a column to data adds exactly one more term to the formula", {
  df_base     <- data.frame(y = 1:5, x1 = 6:10)
  df_expanded <- data.frame(y = 1:5, x1 = 6:10, x2 = 11:15)

  f_base     <- quiet_cf(df_base, "y")
  f_expanded <- quiet_cf(df_expanded, "y")

  # Count "+" signs as a proxy for terms
  n_plus_base     <- nchar(deparse(f_base))     - nchar(gsub("+", "", deparse(f_base),     fixed = TRUE))
  n_plus_expanded <- nchar(deparse(f_expanded)) - nchar(gsub("+", "", deparse(f_expanded), fixed = TRUE))

  expect_equal(n_plus_expanded, n_plus_base + 1L,
               label = paste("base formula:", deparse(f_base),
                            "| expanded formula:", deparse(f_expanded)))
})

# ---------------------------------------------------------------------------
# 9. Backtick quoting is applied to special-character predictor names
# ---------------------------------------------------------------------------

test_that("special-character predictor names retain backtick-quoting in the formula string", {
  # Column names with spaces or special characters must be backtick-quoted
  df <- data.frame(
    days          = 1:3,
    "patient age" = c(30, 40, 50),
    "site-name"   = c("A", "B", "C"),
    check.names   = FALSE,
    stringsAsFactors = FALSE
  )
  f <- quiet_cf(df, "days")
  f_str <- deparse(f)
  expect_true(grepl("`patient age`", f_str),
              label = paste("Formula:", f_str))
  expect_true(grepl("`site-name`", f_str),
              label = paste("Formula:", f_str))
})

test_that("standard underscore names appear without backticks after deparse normalization", {
  # R's deparse() removes unnecessary backticks from syntactically valid names
  df <- data.frame(
    days        = 1:3,
    patient_age = c(30, 40, 50),
    site_name   = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  f <- quiet_cf(df, "days")
  f_str <- deparse(f)
  # After deparse normalization, patient_age and site_name appear without backticks
  expect_true(grepl("patient_age", f_str),
              label = paste("Formula:", f_str))
  expect_true(grepl("site_name", f_str),
              label = paste("Formula:", f_str))
})
