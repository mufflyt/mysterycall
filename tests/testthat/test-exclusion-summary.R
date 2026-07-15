# tests/testthat/test-exclusion-summary.R
# testthat 3rd edition — mysterycall_exclusion_summary()

# ---------------------------------------------------------------------------
# Shared helper: canonical dataset used across most tests
# Total = 27: 10 included, 5 no-answer, 3 voicemail, 2 wrong-number,
#             4 referral-required, 2 not-accepting, 1 on-hold
# n_unreachable = 10, n_reached = 17, n_included = 10, pct_reached ~ 62.96
# ---------------------------------------------------------------------------
make_excl_df <- function() {
  reasons <- c(
    "Able to contact",
    "Phone not answered or busy signal on repeat calls",
    "Went to voicemail",
    "Number contacted did not correspond to expected office/specialty",
    "Physician referral required before scheduling appointment",
    "Not accepting new patients",
    "Greater than 5 minutes on hold"
  )
  n_each <- c(10L, 5L, 3L, 2L, 4L, 2L, 1L)
  data.frame(
    reason_for_exclusions = rep(reasons, n_each),
    stringsAsFactors      = FALSE
  )
}

# ---------------------------------------------------------------------------
# 1. Returns list of class mysterycall_exclusion_summary
# ---------------------------------------------------------------------------
test_that("returns list of class mysterycall_exclusion_summary", {
  result <- mysterycall_exclusion_summary(make_excl_df())
  expect_s3_class(result, "mysterycall_exclusion_summary")
  expect_type(result, "list")
})

# ---------------------------------------------------------------------------
# 2. total equals nrow(data)
# ---------------------------------------------------------------------------
test_that("total equals nrow(data)", {
  df     <- make_excl_df()
  result <- mysterycall_exclusion_summary(df)
  expect_equal(result$total, nrow(df))
  expect_type(result$total, "integer")
})

# ---------------------------------------------------------------------------
# 3. n_reached + n_unreachable == total
# ---------------------------------------------------------------------------
test_that("n_reached + n_unreachable equals total", {
  result <- mysterycall_exclusion_summary(make_excl_df())
  expect_equal(result$n_reached + result$n_unreachable, result$total)
})

# ---------------------------------------------------------------------------
# 4. pct_reached in [0, 100]
# ---------------------------------------------------------------------------
test_that("pct_reached is in [0, 100]", {
  result <- mysterycall_exclusion_summary(make_excl_df())
  expect_gte(result$pct_reached, 0)
  expect_lte(result$pct_reached, 100)
})

# ---------------------------------------------------------------------------
# 5. paragraph is a single non-empty character string
# ---------------------------------------------------------------------------
test_that("paragraph is a single non-empty character string", {
  result <- mysterycall_exclusion_summary(make_excl_df())
  expect_type(result$paragraph, "character")
  expect_length(result$paragraph, 1L)
  expect_true(nzchar(result$paragraph))
})

# ---------------------------------------------------------------------------
# 6. table is a data.frame with required columns
# ---------------------------------------------------------------------------
test_that("table is a data.frame with columns category, label, n, pct", {
  result <- mysterycall_exclusion_summary(make_excl_df())
  expect_s3_class(result$table, "data.frame")
  expect_true(all(c("category", "label", "n", "pct") %in% names(result$table)))
  expect_type(result$table$n,   "integer")
  expect_type(result$table$pct, "double")
})

# ---------------------------------------------------------------------------
# 7. counts is a named integer vector with all six canonical keys
# ---------------------------------------------------------------------------
test_that("counts is a named integer vector with all six keys", {
  result <- mysterycall_exclusion_summary(make_excl_df())
  expect_type(result$counts, "integer")
  expect_named(result$counts, c(
    "phone_not_answered", "voicemail", "wrong_number",
    "referral_required", "not_accepting", "on_hold"
  ))
})

# ---------------------------------------------------------------------------
# 8. Missing exclusion categories in data produce zero counts (not NA or error)
# ---------------------------------------------------------------------------
test_that("absent exclusion categories produce zero counts", {
  # Only included + phone_not_answered rows present; five categories absent
  df <- data.frame(
    reason_for_exclusions = c(
      rep("Able to contact", 8L),
      rep("Phone not answered or busy signal on repeat calls", 3L)
    ),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_exclusion_summary(df)
  expect_equal(result$counts[["phone_not_answered"]], 3L)
  expect_equal(result$counts[["voicemail"]],          0L)
  expect_equal(result$counts[["wrong_number"]],       0L)
  expect_equal(result$counts[["referral_required"]],  0L)
  expect_equal(result$counts[["not_accepting"]],      0L)
  expect_equal(result$counts[["on_hold"]],            0L)
})

# ---------------------------------------------------------------------------
# 9. Custom exclusion_categories override works
# ---------------------------------------------------------------------------
test_that("custom exclusion_categories override works", {
  df <- data.frame(
    call_outcome = c(
      rep("contacted",  5L),
      rep("no_answer",  3L),
      rep("vm",         2L),
      rep("wrong_num",  1L),
      rep("ref_req",    1L),
      rep("not_acc",    1L),
      rep("hold",       1L)
    ),
    stringsAsFactors = FALSE
  )
  custom_cats <- c(
    phone_not_answered = "no_answer",
    voicemail          = "vm",
    wrong_number       = "wrong_num",
    referral_required  = "ref_req",
    not_accepting      = "not_acc",
    on_hold            = "hold"
  )
  result <- mysterycall_exclusion_summary(
    data                 = df,
    exclusion_col        = "call_outcome",
    inclusion_value      = "contacted",
    exclusion_categories = custom_cats
  )
  expect_equal(result$total,                         nrow(df))
  expect_equal(result$counts[["phone_not_answered"]], 3L)
  expect_equal(result$counts[["voicemail"]],          2L)
  expect_equal(result$counts[["wrong_number"]],       1L)
  expect_equal(result$n_included,                    5L)
})

# ---------------------------------------------------------------------------
# 10. Error when exclusion_col is absent from data
# ---------------------------------------------------------------------------
test_that("error when exclusion_col is not in data", {
  df <- data.frame(other_col = letters[1:5], stringsAsFactors = FALSE)
  expect_error(
    mysterycall_exclusion_summary(df, exclusion_col = "reason_for_exclusions"),
    regexp = "not found"
  )
})

# ---------------------------------------------------------------------------
# 11. n_included <= n_reached
# ---------------------------------------------------------------------------
test_that("n_included is at most n_reached", {
  result <- mysterycall_exclusion_summary(make_excl_df())
  expect_lte(result$n_included, result$n_reached)
})

# ---------------------------------------------------------------------------
# 12. Print method writes the paragraph to console
# ---------------------------------------------------------------------------
test_that("print method cats the paragraph", {
  result <- mysterycall_exclusion_summary(make_excl_df())
  out    <- capture.output(print(result))
  joined <- paste(out, collapse = " ")
  expect_true(nzchar(joined))
  expect_true(grepl("phone calls", joined, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# 13. id_col deduplicates before counting
# ---------------------------------------------------------------------------
test_that("id_col deduplication reduces total and adjusts counts", {
  # Provider 1 attempted 5 times (included); provider 2 attempted 3 times (voicemail)
  df <- data.frame(
    npi                   = c(rep(1L, 5L), rep(2L, 3L)),
    reason_for_exclusions = c(
      rep("Able to contact", 5L),
      rep("Went to voicemail", 3L)
    ),
    stringsAsFactors = FALSE
  )
  result_dedup    <- mysterycall_exclusion_summary(df, id_col = "npi")
  result_no_dedup <- mysterycall_exclusion_summary(df)

  # 2 unique providers, not 8 call rows
  expect_equal(result_dedup$total, 2L)
  expect_lt(result_dedup$total, result_no_dedup$total)
  # After dedup: one voicemail row, one included row
  expect_equal(result_dedup$counts[["voicemail"]], 1L)
  expect_equal(result_dedup$n_included,            1L)
})

# ---------------------------------------------------------------------------
# 14. n_unreachable equals sum of the three unreachable-group counts
# ---------------------------------------------------------------------------
test_that("n_unreachable equals sum of unreachable-group counts", {
  result <- mysterycall_exclusion_summary(make_excl_df())
  expected <- result$counts[["phone_not_answered"]] +
              result$counts[["voicemail"]] +
              result$counts[["wrong_number"]]
  expect_equal(result$n_unreachable, expected)
})

# ---------------------------------------------------------------------------
# 15. Arithmetic correctness with known counts
# ---------------------------------------------------------------------------
test_that("arithmetic is correct against hand-calculated values", {
  result <- mysterycall_exclusion_summary(make_excl_df())
  # total = 27, n_unreachable = 10, n_reached = 17, n_included = 10
  expect_equal(result$total,         27L)
  expect_equal(result$n_unreachable, 10L)
  expect_equal(result$n_reached,     17L)
  expect_equal(result$n_included,    10L)
  expect_equal(round(result$pct_reached, 4L), round(17 / 27 * 100, 4L))
})

# Regression (bug 22): reason strings outside the known set (typos/unmapped
# codes) must NOT be counted as included; they land in an "unrecognized" bucket.
test_that("unrecognized reason strings are not counted as included", {
  df <- data.frame(
    reason_for_exclusions = c(
      rep("Able to contact",   100L),
      rep("Went to voicemail",  10L),
      rep("Deceased",            5L)   # not a known category
    ),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_exclusion_summary(df)

  expect_equal(result$total,          115L)
  expect_equal(result$n_included,     100L)   # NOT 105
  expect_equal(result$n_unrecognized,   5L)
  # Table rows still account for every record.
  expect_equal(sum(result$table$n),   115L)
  expect_true("unrecognized" %in% result$table$category)
})
