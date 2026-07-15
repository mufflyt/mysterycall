library(testthat)

# ---------------------------------------------------------------------------
# BUG 1 — the narrative CI must keep its sign. abs()-ing the bounds turned a
# zero-crossing (null) CI into one bounded away from zero, misreporting a
# non-significant estimate as a positive effect.
# ---------------------------------------------------------------------------

# A protective/zero-crossing exposure: IRR 1.04 with a CI that spans 1.0.
zero_cross_tbl <- data.frame(
  term        = c("(Intercept)", "ent_typeFacialPlastics"),
  irr         = c(1.00, 1.04),
  ci_lower    = c(NA,   0.72),   # baseline 23 -> days_ci_lower ~ -6.4 (< 0)
  ci_upper    = c(NA,   1.50),   # baseline 23 -> days_ci_upper ~ +11.4 (> 0)
  p_value_fmt = c(NA,   "0.852"),
  stringsAsFactors = FALSE
)

test_that("zero-crossing CI is printed signed, not abs()'d", {
  res <- mysterycall_irr_to_days(
    zero_cross_tbl, baseline_mean = 23,
    exposure_col = "ent_type", ref_group = "General",
    exposure_descriptor = NULL
  )
  s <- res$sentences[1]

  # Signed table bounds straddle zero.
  expect_lt(res$table$days_ci_lower[1], 0)
  expect_gt(res$table$days_ci_upper[1], 0)

  # The sentence must contain the NEGATIVE lower bound (the old abs() bug
  # flipped it positive) and flag the non-significance.
  expect_match(s, "-6\\.", fixed = FALSE)          # negative lower bound survives
  expect_match(s, "difference not statistically significant")
  # The old bug printed "6.5 to 11.4" (both positive); ensure that exact
  # positive-only rendering is gone.
  expect_false(grepl("CI 6\\.[0-9] to 11", s))
})

test_that("a fully-positive CI keeps signs and is not flagged non-significant", {
  pos_tbl <- data.frame(
    term        = c("(Intercept)", "insuranceMedicaid"),
    irr         = c(1.00, 1.28),
    ci_lower    = c(NA,   1.05),
    ci_upper    = c(NA,   1.56),
    p_value_fmt = c(NA,   "0.014"),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_irr_to_days(
    pos_tbl, baseline_mean = 21, exposure_col = "insurance", ref_group = "BCBS"
  )
  s <- res$sentences[1]
  expect_gt(res$table$days_ci_lower[1], 0)
  expect_false(grepl("not statistically significant", s))
})

# ---------------------------------------------------------------------------
# BUG 2 — wording must be parameterizable for non-insurance exposures.
# ---------------------------------------------------------------------------

ent_tbl <- data.frame(
  term        = c("(Intercept)", "ent_typeLaryngology"),
  irr         = c(1.00, 1.20),
  ci_lower    = c(NA,   1.02),
  ci_upper    = c(NA,   1.41),
  p_value_fmt = c(NA,   "0.028"),
  stringsAsFactors = FALSE
)

test_that("exposure_descriptor = NULL drops the nonsensical '-insured' infix", {
  res <- mysterycall_irr_to_days(
    ent_tbl, baseline_mean = 23, exposure_col = "ent_type",
    ref_group = "General", exposure_descriptor = NULL, subject = "callers"
  )
  expect_match(res$sentences[1], "^Laryngology callers waited")
  expect_false(grepl("-insured", res$sentences[1]))
})

test_that("default wording is unchanged (backward compatible)", {
  res <- mysterycall_irr_to_days(
    ent_tbl, baseline_mean = 23, exposure_col = "ent_type", ref_group = "General"
  )
  expect_match(res$sentences[1], "^Laryngology-insured callers waited")
})

test_that("subject noun is configurable", {
  res <- mysterycall_irr_to_days(
    ent_tbl, baseline_mean = 23, exposure_col = "ent_type",
    ref_group = "General", exposure_descriptor = NULL, subject = "patients"
  )
  expect_match(res$sentences[1], "^Laryngology patients waited")
})

test_that("invalid wording arguments error clearly", {
  expect_error(
    mysterycall_irr_to_days(ent_tbl, baseline_mean = 23, subject = c("a", "b")),
    "`subject`"
  )
  expect_error(
    mysterycall_irr_to_days(ent_tbl, baseline_mean = 23,
                            exposure_descriptor = c("x", "y")),
    "`exposure_descriptor`"
  )
})

# ---------------------------------------------------------------------------
# BUG 2 (results_paragraph) — subject noun is configurable there too.
# ---------------------------------------------------------------------------

or_tbl <- data.frame(
  term     = c("(Intercept)", "ent_typePediatrics"),
  or       = c(2.10, 2.26),
  ci_lower = c(1.20, 1.40),
  ci_upper = c(3.68, 3.65),
  p_value  = c(0.008, 0.001),
  stringsAsFactors = FALSE
)

test_that("results_paragraph subject noun is configurable and defaults to callers", {
  default_out <- mysterycall_results_paragraph(or_tbl, "General", "ent_type")
  expect_match(default_out, "Pediatrics callers were")

  patient_out <- mysterycall_results_paragraph(
    or_tbl, "General", "ent_type", subject = "patients"
  )
  expect_match(patient_out, "Pediatrics patients were")
})
