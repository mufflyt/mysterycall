# Tests for mysterycall_interaction_sentences()
#
# Guards:
#   - All model-fitting tests: skip_if_not_installed("emmeans")
#   - glmerMod tests additionally: skip_if_not_installed("lme4")
#
# Edition: testthat 3 (uses local_mocked_bindings, expect_s3_class, etc.)

library(testthat)

# ── fixtures ──────────────────────────────────────────────────────────────────

# Simple data suitable for lm() — no lme4 dependency.
make_lm_data <- function(seed = 42L) {
  set.seed(seed)
  data.frame(
    y        = rnorm(60),
    scenario = rep(c("Urgent", "Routine"), each = 30L),
    ins      = rep(c("Medicaid", "BCBS", "Medicare"), times = 20L),
    stringsAsFactors = FALSE
  )
}

make_lm_fit <- function() {
  df <- make_lm_data()
  lm(y ~ scenario * ins, data = df)
}

# ── 1. return class ───────────────────────────────────────────────────────────

test_that("returns a list of class mysterycall_interaction_sentences", {
  skip_if_not_installed("emmeans")

  res <- mysterycall_interaction_sentences(make_lm_fit(), "scenario", "ins")

  expect_type(res, "list")
  expect_s3_class(res, "mysterycall_interaction_sentences")
})

# ── 2. sentences is a named character vector ───────────────────────────────────

test_that("sentences is a named character vector with one entry per var1 level", {
  skip_if_not_installed("emmeans")

  res <- mysterycall_interaction_sentences(make_lm_fit(), "scenario", "ins")

  expect_type(res$sentences, "character")
  expect_false(is.null(names(res$sentences)))
  expect_length(res$sentences, 2L)   # "Urgent" and "Routine"
})

# ── 3. names(sentences) match var1 levels ─────────────────────────────────────

test_that("names(sentences) match unique levels of var1 in the data", {
  skip_if_not_installed("emmeans")

  df  <- make_lm_data()
  fit <- lm(y ~ scenario * ins, data = df)
  res <- mysterycall_interaction_sentences(fit, "scenario", "ins")

  expect_setequal(names(res$sentences), unique(df$scenario))
})

# ── 4. paragraph combines all sentences ───────────────────────────────────────

test_that("paragraph is a single character string that contains each sentence", {
  skip_if_not_installed("emmeans")

  res <- mysterycall_interaction_sentences(make_lm_fit(), "scenario", "ins")

  expect_type(res$paragraph, "character")
  expect_length(res$paragraph, 1L)
  expect_true(nzchar(res$paragraph))

  for (s in res$sentences) {
    expect_true(
      grepl(substr(s, 1L, 40L), res$paragraph, fixed = TRUE),
      info = paste("sentence fragment not found in paragraph:", substr(s, 1L, 40L))
    )
  }
})

# ── 5. emmeans_table is a data.frame ─────────────────────────────────────────

test_that("emmeans_table is a data.frame with nlevels(var1) x nlevels(var2) rows", {
  skip_if_not_installed("emmeans")

  df  <- make_lm_data()
  fit <- lm(y ~ scenario * ins, data = df)
  res <- mysterycall_interaction_sentences(fit, "scenario", "ins")

  expect_s3_class(res$emmeans_table, "data.frame")
  # 2 scenario levels x 3 ins levels = 6 rows
  expect_equal(nrow(res$emmeans_table), 6L)
})

# ── 6. result list has all expected elements ──────────────────────────────────

test_that("result list has expected named elements with correct metadata", {
  skip_if_not_installed("emmeans")

  res <- mysterycall_interaction_sentences(
    make_lm_fit(), "scenario", "ins",
    type = "response"
  )

  expect_named(
    res,
    c("sentences", "emmeans_table", "paragraph", "var1", "var2", "type"),
    ignore.order = TRUE
  )
  expect_equal(res$var1, "scenario")
  expect_equal(res$var2, "ins")
  expect_equal(res$type, "response")
})

# ── 7. error when emmeans is not available ────────────────────────────────────

test_that("error when emmeans is not available gives an informative message", {
  # requireNamespace is a base function with no binding in the mysterycall
  # namespace, so local_mocked_bindings cannot patch it.  mockery::stub()
  # replaces the lookup inside the target function directly.
  skip_if_not_installed("mockery")

  mockery::stub(
    mysterycall_interaction_sentences,
    "requireNamespace",
    function(pkg, quietly = FALSE) {
      if (identical(pkg, "emmeans")) return(FALSE)
      base::requireNamespace(pkg, quietly = quietly)
    }
  )

  expect_error(
    mysterycall_interaction_sentences(list(), "a", "b"),
    regexp = "emmeans",
    ignore.case = TRUE
  )
})

# ── 8. error when var1 is absent from the model (informative message) ─────────

test_that("error when var1 is not in the model gives an informative message", {
  skip_if_not_installed("emmeans")

  df  <- make_lm_data()
  fit <- lm(y ~ ins, data = df)   # scenario absent from model

  expect_error(
    mysterycall_interaction_sentences(fit, "scenario", "ins"),
    regexp = "emmeans::emmeans\\(\\) failed|not found",
    ignore.case = TRUE
  )
})

# ── 9. var1 == var2 validation (no emmeans dependency) ────────────────────────

test_that("var1 identical to var2 raises an informative error", {
  expect_error(
    mysterycall_interaction_sentences(list(), "scenario", "scenario"),
    regexp = "must be different"
  )
})

# ── 10. works with glmerMod object ────────────────────────────────────────────

test_that("works correctly with a glmerMod (Poisson GLMM) from lme4", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("lme4")

  set.seed(42L)
  df <- data.frame(
    y         = rpois(120L, lambda = 5L),
    scenario  = rep(c("Urgent", "Routine"), each = 60L),
    insurance = rep(c("Medicaid", "BCBS", "Medicare"), times = 40L),
    physician = rep(paste0("Dr", 1:10), each = 12L),
    stringsAsFactors = FALSE
  )

  fit <- lme4::glmer(
    y ~ scenario * insurance + (1 | physician),
    data   = df,
    family = poisson()
  )

  res <- mysterycall_interaction_sentences(fit, "scenario", "insurance")

  expect_s3_class(res, "mysterycall_interaction_sentences")
  expect_s3_class(res$emmeans_table, "data.frame")
  expect_setequal(names(res$sentences), unique(df$scenario))
  expect_length(res$sentences, 2L)
})

# ── 11. print method ──────────────────────────────────────────────────────────

test_that("print method writes paragraph to console and returns x invisibly", {
  skip_if_not_installed("emmeans")

  res    <- mysterycall_interaction_sentences(make_lm_fit(), "scenario", "ins")
  output <- capture.output(ret <- print(res))

  # At least one non-empty line appeared on stdout
  expect_true(any(nzchar(output)))

  # print() must return the object invisibly (identical, not just equal)
  expect_identical(ret, res)
})

# ── 12. outcome_label appears in every sentence and in the paragraph ──────────

test_that("outcome_label is embedded in each sentence and in the paragraph", {
  skip_if_not_installed("emmeans")

  label <- "days to appointment"
  res   <- mysterycall_interaction_sentences(
    make_lm_fit(), "scenario", "ins",
    outcome_label = label
  )

  for (s in res$sentences) {
    expect_true(
      grepl(label, s, fixed = TRUE),
      info = paste("outcome_label missing from sentence:", s)
    )
  }
  expect_true(grepl(label, res$paragraph, fixed = TRUE))
})
