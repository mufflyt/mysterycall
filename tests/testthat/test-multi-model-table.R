# Tests for mysterycall_multi_model_table()
#
# All model objects are built with structure() — no model fitting required.
# Package uses Config/testthat/edition: 3 globally.

library(testthat)

# ── shared fixtures ────────────────────────────────────────────────────────────

make_logistic <- function(terms   = c("insuranceMedicaid", "scenarioNo appointment"),
                          ors     = c(1.45, 0.82),
                          ci_lo   = c(1.02, 0.61),
                          ci_hi   = c(2.05, 1.10),
                          p_fmt   = c("0.038", "0.189"),
                          refs    = list(insurance = "BCBS", scenario = "Appointment"),
                          n       = 200L,
                          aic     = 312.4) {
  structure(
    list(
      or_table = data.frame(
        term        = terms,
        or          = ors,
        ci_lower    = ci_lo,
        ci_upper    = ci_hi,
        p_value_fmt = p_fmt,
        stringsAsFactors = FALSE
      ),
      factor_refs = refs,
      n           = n,
      aic         = aic
    ),
    class = "mysterycall_logistic_model"
  )
}

make_poisson <- function(terms  = c("insuranceMedicaid", "regionSouth"),
                         irrs   = c(1.32, 0.91),
                         ci_lo  = c(1.05, 0.74),
                         ci_hi  = c(1.66, 1.12),
                         p_fmt  = c("0.017", "0.364"),
                         refs   = list(insurance = "BCBS", region = "North"),
                         n      = 185L,
                         aic    = 455.2) {
  structure(
    list(
      irr_table = data.frame(
        term        = terms,
        irr         = irrs,
        ci_lower    = ci_lo,
        ci_upper    = ci_hi,
        p_value_fmt = p_fmt,
        stringsAsFactors = FALSE
      ),
      factor_refs = refs,
      n           = n,
      aic         = aic
    ),
    class = "mysterycall_poisson_model"
  )
}

# Two logistic models that share all terms → simplest valid input
m1 <- make_logistic()
m2 <- make_logistic(
  terms = c("insuranceMedicaid", "scenarioNo appointment", "regionSouth"),
  ors   = c(1.38, 0.79, 1.21),
  ci_lo = c(0.97, 0.58, 0.88),
  ci_hi = c(1.96, 1.07, 1.66),
  p_fmt = c("0.072", "0.124", "0.238"),
  refs  = list(insurance = "BCBS", scenario = "Appointment", region = "North"),
  aic   = 308.1
)

two_logistic <- list(Unadjusted = m1, Adjusted = m2)

# ── 1. Returns data.frame ──────────────────────────────────────────────────────

test_that("multi_model_table: returns a data.frame", {
  out <- mysterycall_multi_model_table(models = two_logistic)
  expect_s3_class(out, "data.frame")
})

test_that("multi_model_table: has primary mysterycall_multi_model_table class", {
  out <- mysterycall_multi_model_table(models = two_logistic)
  expect_s3_class(out, "mysterycall_multi_model_table")
})

# ── 2. Has "Term" column plus one column per model name ───────────────────────

test_that("multi_model_table: first column is named Term", {
  out <- mysterycall_multi_model_table(models = two_logistic)
  expect_equal(names(out)[1L], "Term")
})

test_that("multi_model_table: model names become column headers", {
  out <- mysterycall_multi_model_table(models = two_logistic)
  expect_true("Unadjusted" %in% names(out))
  expect_true("Adjusted"   %in% names(out))
})

# ── 3. Number of columns = 1 + length(models) ─────────────────────────────────

test_that("multi_model_table: ncol equals 1 + number of models (two models)", {
  out <- mysterycall_multi_model_table(models = two_logistic)
  expect_equal(ncol(out), 3L)
})

test_that("multi_model_table: ncol equals 1 + number of models (three models)", {
  m3 <- make_logistic(
    terms = c("insuranceMedicaid"),
    ors   = 1.10, ci_lo = 0.81, ci_hi = 1.49, p_fmt = "0.535",
    refs  = list(insurance = "BCBS"), aic = 320.0
  )
  out <- mysterycall_multi_model_table(
    models = list(A = m1, B = m2, C = m3)
  )
  expect_equal(ncol(out), 4L)
})

# ── 4 & 5. include_n flag ─────────────────────────────────────────────────────

test_that("multi_model_table: include_n=TRUE adds an N row", {
  out <- mysterycall_multi_model_table(models = two_logistic, include_n = TRUE)
  expect_true("N" %in% out$Term)
})

test_that("multi_model_table: include_n=FALSE omits the N row", {
  out <- mysterycall_multi_model_table(models = two_logistic, include_n = FALSE)
  expect_false("N" %in% out$Term)
})

# ── 6 & 7. include_aic flag ───────────────────────────────────────────────────

test_that("multi_model_table: include_aic=TRUE adds an AIC row", {
  out <- mysterycall_multi_model_table(models = two_logistic, include_aic = TRUE)
  expect_true("AIC" %in% out$Term)
})

test_that("multi_model_table: include_aic=FALSE omits the AIC row", {
  out <- mysterycall_multi_model_table(models = two_logistic, include_aic = FALSE)
  expect_false("AIC" %in% out$Term)
})

# ── 8. Error: models not a named list ─────────────────────────────────────────

test_that("multi_model_table: errors when models is not a list", {
  expect_error(
    mysterycall_multi_model_table(models = "not_a_list"),
    "named list"
  )
})

test_that("multi_model_table: errors when models has no names", {
  expect_error(
    mysterycall_multi_model_table(models = list(m1, m2)),
    "non-empty name"
  )
})

test_that("multi_model_table: errors when any name is empty string", {
  bad <- setNames(list(m1, m2), c("A", ""))
  expect_error(
    mysterycall_multi_model_table(models = bad),
    "non-empty name"
  )
})

# ── 9. Error: models has length < 2 ───────────────────────────────────────────

test_that("multi_model_table: errors when models has only one element", {
  expect_error(
    mysterycall_multi_model_table(models = list(Only = m1)),
    "at least 2"
  )
})

# ── 10. All terms from both models appear as rows ─────────────────────────────

test_that("multi_model_table: every coefficient term from all models is in Term column", {
  out <- mysterycall_multi_model_table(models = two_logistic,
                                       include_n = FALSE, include_aic = FALSE)
  all_terms <- unique(c(m1$or_table$term, m2$or_table$term))
  for (trm in all_terms) {
    expect_true(trm %in% out$Term,
                label = paste("term present:", trm))
  }
})

# ── 11. Cell values contain parentheses (CI format) ───────────────────────────

test_that("multi_model_table: non-reference estimate cells contain parentheses", {
  out <- mysterycall_multi_model_table(models = two_logistic,
                                       include_n = FALSE, include_aic = FALSE)
  # Pull the Unadjusted column; keep only non-Ref, non-empty cells
  vals <- out[["Unadjusted"]]
  data_cells <- vals[!vals %in% c("Ref.", "", NA)]
  expect_true(
    length(data_cells) > 0L,
    label = "at least one non-reference cell exists"
  )
  expect_true(
    all(grepl("(", data_cells, fixed = TRUE)),
    label = "every data cell contains an opening parenthesis"
  )
})

test_that("multi_model_table: cell format matches 'est (lo to hi)' pattern", {
  out <- mysterycall_multi_model_table(models = two_logistic,
                                       include_n = FALSE, include_aic = FALSE)
  vals <- out[["Unadjusted"]]
  data_cells <- vals[!vals %in% c("Ref.", "", NA)]
  expect_true(
    all(grepl("^[0-9.]+\\s*\\([0-9.]+ to [0-9.]+\\)", data_cells)),
    label = "cells start with estimate (lower to upper) pattern"
  )
})

# ── 12. Mixed model types (logistic + poisson) ────────────────────────────────

test_that("multi_model_table: mixed types produce a warning", {
  mp <- make_poisson()
  expect_warning(
    mysterycall_multi_model_table(models = list(Logistic = m1, Poisson = mp)),
    regexp = "different types"
  )
})

test_that("multi_model_table: mixed types tag column names with type labels", {
  mp  <- make_poisson()
  out <- suppressWarnings(
    mysterycall_multi_model_table(models = list(Logistic = m1, Poisson = mp))
  )
  expect_true(any(grepl("\\[Logistic\\]", names(out))))
  expect_true(any(grepl("\\[Poisson\\]",  names(out))))
})

test_that("multi_model_table: mixed_types attribute is TRUE for mixed input", {
  mp  <- make_poisson()
  out <- suppressWarnings(
    mysterycall_multi_model_table(models = list(A = m1, B = mp))
  )
  expect_true(isTRUE(attr(out, "mixed_types")))
})

test_that("multi_model_table: mixed_types attribute is FALSE for uniform input", {
  out <- mysterycall_multi_model_table(models = two_logistic)
  expect_false(isTRUE(attr(out, "mixed_types")))
})

# ── 13. Print method ──────────────────────────────────────────────────────────

test_that("multi_model_table: print method returns the object invisibly", {
  out <- mysterycall_multi_model_table(models = two_logistic)
  ret <- capture.output(printed <- print(out))
  expect_identical(printed, out)
})

test_that("multi_model_table: print output contains the estimate label", {
  out  <- mysterycall_multi_model_table(models = two_logistic)
  text <- capture.output(print(out))
  expect_true(any(grepl("OR \\(95", text)))
})

test_that("multi_model_table: print output contains model column names", {
  out  <- mysterycall_multi_model_table(models = two_logistic)
  text <- capture.output(print(out))
  combined <- paste(text, collapse = " ")
  expect_true(grepl("Unadjusted", combined))
  expect_true(grepl("Adjusted",   combined))
})

# ── Negative estimates stay readable (SAMPL: "to", never a hyphen) ────────────

test_that("multi_model_table: a negative interval is not rendered as '--'", {
  skip_if_not_installed("lme4")
  set.seed(11)
  df <- data.frame(
    y   = rnorm(60, mean = 10),
    grp = rep(c("a", "b"), each = 30),
    id  = rep(paste0("p", 1:12), each = 5),
    stringsAsFactors = FALSE
  )
  df$y[df$grp == "b"] <- df$y[df$grp == "b"] - 2   # forces a negative beta
  df$cov <- rnorm(60)
  fit_u <- suppressWarnings(suppressMessages(
    mysterycall_lmm(df, outcome = "y", predictors = "grp", random_intercept = "id")
  ))
  fit_a <- suppressWarnings(suppressMessages(
    mysterycall_lmm(df, outcome = "y", predictors = c("grp", "cov"),
                    random_intercept = "id")
  ))
  out <- suppressWarnings(suppressMessages(
    mysterycall_multi_model_table(models = list(Unadjusted = fit_u, Adjusted = fit_a),
                                  include_n = FALSE, include_aic = FALSE)
  ))
  cells <- unlist(out[vapply(out, is.character, logical(1L))], use.names = FALSE)
  cells <- cells[!is.na(cells) & grepl("(", cells, fixed = TRUE)]
  expect_gt(length(cells), 0L)
  expect_false(any(grepl("--", cells, fixed = TRUE)))
  expect_true(all(grepl(" to ", cells, fixed = TRUE)))
})
