# ── mysterycall_results_paragraph ────────────────────────────────────────────

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------

or_tbl_basic <- data.frame(
  term     = c("(Intercept)", "insuranceMedicaid", "insuranceUninsured"),
  or       = c(2.10, 0.62, 0.41),
  ci_lower = c(1.20, 0.41, 0.22),
  ci_upper = c(3.68, 0.94, 0.76),
  p_value  = c(0.008, 0.024, 0.0004),
  stringsAsFactors = FALSE
)

call_paragraph <- function(...) {
  mysterycall_results_paragraph(
    or_tbl_basic,
    ref_group    = "commercial insurance",
    exposure_col = "insurance",
    ...
  )
}

# ---------------------------------------------------------------------------
# 1. Return type
# ---------------------------------------------------------------------------

test_that("results_paragraph: returns a single character string", {
  out <- call_paragraph()
  expect_type(out, "character")
  expect_length(out, 1L)
})

# ---------------------------------------------------------------------------
# 2. OR value appears in output
# ---------------------------------------------------------------------------

test_that("results_paragraph: OR value appears in output", {
  out <- call_paragraph()
  expect_match(out, "0\\.62", fixed = FALSE)
  expect_match(out, "0\\.41", fixed = FALSE)
})

# ---------------------------------------------------------------------------
# 3. OR < 1 → "less likely"
# ---------------------------------------------------------------------------

test_that("results_paragraph: OR < 1 produces 'less likely'", {
  out <- call_paragraph()
  expect_match(out, "less likely")
})

# ---------------------------------------------------------------------------
# 4. OR > 1 → "more likely"
# ---------------------------------------------------------------------------

test_that("results_paragraph: OR > 1 produces 'more likely'", {
  tbl <- data.frame(
    term     = c("(Intercept)", "insurancePPO"),
    or       = c(1.0, 1.75),
    ci_lower = c(0.8, 1.10),
    ci_upper = c(1.2, 2.78),
    p_value  = c(0.90, 0.018),
    stringsAsFactors = FALSE
  )
  out <- mysterycall_results_paragraph(tbl, "commercial insurance", "insurance")
  expect_match(out, "more likely")
})

# ---------------------------------------------------------------------------
# 5. Accepts plain data.frame
# ---------------------------------------------------------------------------

test_that("results_paragraph: accepts plain data.frame with required columns", {
  expect_no_error(call_paragraph())
})

# ---------------------------------------------------------------------------
# 6. Accepts mysterycall_logistic_model structure
# ---------------------------------------------------------------------------

test_that("results_paragraph: accepts list with class mysterycall_logistic_model", {
  fake_model <- structure(
    list(or_table = or_tbl_basic),
    class = "mysterycall_logistic_model"
  )
  out <- mysterycall_results_paragraph(
    fake_model,
    ref_group    = "commercial insurance",
    exposure_col = "insurance"
  )
  expect_type(out, "character")
  expect_length(out, 1L)
})

# ---------------------------------------------------------------------------
# 7. Intercept term is excluded from output
# ---------------------------------------------------------------------------

test_that("results_paragraph: intercept term is not narrated", {
  out <- call_paragraph()
  expect_false(grepl("(Intercept)", out, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# 8. Only terms matching exposure_col are included
# ---------------------------------------------------------------------------

test_that("results_paragraph: terms not matching exposure_col are excluded", {
  tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid", "age"),
    or       = c(2.10, 0.62, 1.03),
    ci_lower = c(1.20, 0.41, 0.99),
    ci_upper = c(3.68, 0.94, 1.07),
    p_value  = c(0.008, 0.024, 0.08),
    stringsAsFactors = FALSE
  )
  out <- mysterycall_results_paragraph(tbl, "commercial insurance", "insurance")
  # "age" should not appear; only the insurance level should
  expect_false(grepl("age", out, fixed = TRUE))
  expect_match(out, "Medicaid")
})

# ---------------------------------------------------------------------------
# 9. p < 0.001 renders as "p < 0.001"
# ---------------------------------------------------------------------------

test_that("results_paragraph: p < 0.001 renders as 'p < 0.001'", {
  tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(2.10, 0.55),
    ci_lower = c(1.20, 0.30),
    ci_upper = c(3.68, 0.80),
    p_value  = c(0.008, 0.0001),
    stringsAsFactors = FALSE
  )
  out <- mysterycall_results_paragraph(tbl, "commercial insurance", "insurance")
  expect_match(out, "p < 0.001", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# 10. Error on non-character ref_group
# ---------------------------------------------------------------------------

test_that("results_paragraph: errors when ref_group is not character", {
  expect_error(
    mysterycall_results_paragraph(or_tbl_basic, ref_group = 42L, exposure_col = "insurance"),
    regexp = "character"
  )
})

# ---------------------------------------------------------------------------
# 11. Error on missing required columns
# ---------------------------------------------------------------------------

test_that("results_paragraph: errors when required columns are missing", {
  bad_tbl <- data.frame(
    term  = c("insuranceMedicaid"),
    or    = c(0.62),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_results_paragraph(bad_tbl, "commercial insurance", "insurance"),
    regexp = "missing required column"
  )
})

# ---------------------------------------------------------------------------
# 12. Custom outcome_label appears in output
# ---------------------------------------------------------------------------

test_that("results_paragraph: custom outcome_label appears in output", {
  out <- call_paragraph(outcome_label = "specialist referral")
  expect_match(out, "specialist referral", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# 13. OR ~ 1 produces "similar odds" sentence
# ---------------------------------------------------------------------------

test_that("results_paragraph: OR near 1 produces 'similar odds'", {
  tbl <- data.frame(
    term     = "insuranceOther",
    or       = 1.00,
    ci_lower = 0.78,
    ci_upper = 1.28,
    p_value  = 0.95,
    stringsAsFactors = FALSE
  )
  out <- mysterycall_results_paragraph(tbl, "commercial insurance", "insurance")
  expect_match(out, "similar odds")
})

# ---------------------------------------------------------------------------
# 14. Multiple matching terms → multiple sentences (space-separated)
# ---------------------------------------------------------------------------

test_that("results_paragraph: multiple terms produce multiple sentences", {
  out <- call_paragraph()
  # two non-intercept insurance rows → two sentences, each ending with "."
  sentences <- strsplit(out, "\\. ")[[1L]]
  expect_gte(length(sentences), 2L)
})

# ---------------------------------------------------------------------------
# 15. Error when no terms match exposure_col
# ---------------------------------------------------------------------------

test_that("results_paragraph: errors when no term matches exposure_col", {
  expect_error(
    mysterycall_results_paragraph(or_tbl_basic, "commercial insurance", "payor"),
    regexp = "No coefficient found"
  )
})
