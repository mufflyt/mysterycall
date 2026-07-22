library(testthat)
library(mysterycall)

# ── crosswalk ─────────────────────────────────────────────────────────────────

test_that("crosswalk returns one row per known code with expected columns", {
  cw <- mysterycall_exclusion_crosswalk()
  expect_s3_class(cw, "tbl_df")
  expect_setequal(cw$code, c(0L, 1L, 2L, 3L, 5L, 6L, 7L, 8L, 9L, 10L))
  expect_true(all(c("code", "code_label", "label_category", "label_string",
                    "reached", "in_logistic", "in_waittime", "label_included")
                  %in% names(cw)))
})

test_that("the three divergent codes are exactly 7, 9, 10", {
  cw <- mysterycall_exclusion_crosswalk()
  divergent <- cw$code[cw$in_logistic & !cw$label_included]
  expect_setequal(divergent, c(7L, 9L, 10L))
})

test_that("only code 0 is label-included and wait-time-included", {
  cw <- mysterycall_exclusion_crosswalk()
  expect_equal(cw$code[cw$label_included], 0L)
  expect_equal(cw$code[cw$in_waittime], 0L)
})

test_that("logistic_include_codes reshapes the in_logistic column", {
  cw <- mysterycall_exclusion_crosswalk(logistic_include_codes = c(0L, 9L))
  expect_setequal(cw$code[cw$in_logistic], c(0L, 9L))
  # Now only code 9 diverges from the label path
  expect_setequal(cw$code[cw$in_logistic & !cw$label_included], 9L)
})

test_that("inclusion_value flows into the code-0 label_string", {
  cw <- mysterycall_exclusion_crosswalk(inclusion_value = "Reached office")
  expect_equal(cw$label_string[cw$code == 0L], "Reached office")
})

test_that("crosswalk rejects bad inputs", {
  expect_error(mysterycall_exclusion_crosswalk(inclusion_value = ""))
  expect_error(mysterycall_exclusion_crosswalk(inclusion_value = c("a", "b")))
  expect_error(mysterycall_exclusion_crosswalk(logistic_include_codes = c(0, NA)))
})

# ── reconcile: fixtures ───────────────────────────────────────────────────────

make_recon_df <- function() {
  data.frame(
    id         = 1:6,
    exclusions = c(0L, 0L, 9L, 7L, 5L, 10L),
    reason_for_exclusions = c(
      "Able to contact",
      "Able to contact",
      "Not accepting new patients",
      "Physician referral required before scheduling appointment",
      "Phone not answered or busy signal on repeat calls",
      "Must see midlevel first"
    ),
    stringsAsFactors = FALSE
  )
}

# ── reconcile: logistic set (the divergent one) ───────────────────────────────

test_that("logistic reconciliation flags codes 7/9/10 as code_only disagreements", {
  df <- make_recon_df()
  rec <- suppressMessages(mysterycall_reconcile_inclusion(df, id_col = "id"))

  expect_s3_class(rec, "mysterycall_reconciliation")
  expect_equal(rec$set, "logistic")
  expect_equal(rec$n, 6L)
  # rows 3 (code 9), 4 (code 7), 6 (code 10) disagree; all code_only
  expect_equal(rec$n_disagree, 3L)
  expect_setequal(rec$discrepancies$code, c(7L, 9L, 10L))
  expect_true(all(rec$discrepancies$disagreement_type == "code_only"))
  expect_true(all(rec$discrepancies$included_by_code))
  expect_true(all(!rec$discrepancies$included_by_label))
})

test_that("id_col is carried into the discrepancy table", {
  df <- make_recon_df()
  rec <- suppressMessages(mysterycall_reconcile_inclusion(df, id_col = "id"))
  expect_true("id" %in% names(rec$discrepancies))
  expect_setequal(rec$discrepancies$id, c(3L, 4L, 6L))
})

# ── reconcile: wait-time set (expected to agree) ──────────────────────────────

test_that("wait-time reconciliation agrees when label 'Able to contact' == code 0", {
  df <- make_recon_df()
  rec <- suppressMessages(
    mysterycall_reconcile_inclusion(df, id_col = "id", set = "waittime")
  )
  # code 0 rows are included by both; 9/7/5/10 excluded by both -> full agreement
  expect_equal(rec$n_disagree, 0L)
  expect_equal(rec$agree_rate, 1)
})

# ── reconcile: label_only direction ───────────────────────────────────────────

test_that("a code the integer path excludes but the label includes is label_only", {
  # Code 5 (phone not answered) mislabeled as 'Able to contact'
  df <- data.frame(
    id         = 1:2,
    exclusions = c(0L, 5L),
    reason_for_exclusions = c("Able to contact", "Able to contact"),
    stringsAsFactors = FALSE
  )
  rec <- suppressMessages(mysterycall_reconcile_inclusion(df, id_col = "id"))
  expect_equal(rec$n_disagree, 1L)
  expect_equal(rec$discrepancies$disagreement_type, "label_only")
  expect_equal(rec$discrepancies$code, 5L)
})

# ── reconcile: per-code breakdown ─────────────────────────────────────────────

test_that("by_code reports label classification per code", {
  df <- make_recon_df()
  rec <- suppressMessages(mysterycall_reconcile_inclusion(df))
  code0 <- rec$by_code[rec$by_code$code == 0L, ]
  expect_equal(code0$n, 2L)
  expect_equal(code0$n_label_included, 2L)
  expect_true(code0$crosswalk_included)

  code9 <- rec$by_code[rec$by_code$code == 9L, ]
  expect_equal(code9$n_label_included, 0L)
  expect_false(code9$crosswalk_included)
})

# ── reconcile: label/code integrity check ─────────────────────────────────────

test_that("label_mismatches catches a label string inconsistent with its code", {
  # Code 9 carries the wrong-number label string
  df <- data.frame(
    id         = 1:2,
    exclusions = c(0L, 9L),
    reason_for_exclusions = c(
      "Able to contact",
      "Number contacted did not correspond to expected office/specialty"
    ),
    stringsAsFactors = FALSE
  )
  rec <- suppressMessages(mysterycall_reconcile_inclusion(df, id_col = "id"))
  expect_false(is.null(rec$label_mismatches))
  expect_equal(rec$label_mismatches$code, 9L)
  expect_equal(rec$label_mismatches$actual_label,
               "Number contacted did not correspond to expected office/specialty")
})

test_that("no label_mismatches when strings are consistent", {
  df <- make_recon_df()
  rec <- suppressMessages(mysterycall_reconcile_inclusion(df))
  expect_null(rec$label_mismatches)
})

# ── reconcile: robustness ─────────────────────────────────────────────────────

test_that("non-integer code strings warn and are treated as excluded", {
  df <- data.frame(
    exclusions = c("0", "junk"),
    reason_for_exclusions = c("Able to contact", "Able to contact"),
    stringsAsFactors = FALSE
  )
  expect_warning(
    rec <- suppressMessages(mysterycall_reconcile_inclusion(df)),
    regexp = "could not be coerced"
  )
  # junk code -> included_by_code FALSE, label says included -> label_only
  expect_equal(rec$n_disagree, 1L)
})

test_that("NA label is treated as not-included", {
  df <- data.frame(
    exclusions = c(0L, 0L),
    reason_for_exclusions = c("Able to contact", NA),
    stringsAsFactors = FALSE
  )
  rec <- suppressMessages(mysterycall_reconcile_inclusion(df))
  # second row: code 0 (included) but NA label (excluded) -> disagree
  expect_equal(rec$n_disagree, 1L)
})

test_that("missing columns and bad args error clearly", {
  df <- make_recon_df()
  expect_error(mysterycall_reconcile_inclusion(df, code_col = "nope"),
               regexp = "not found")
  expect_error(mysterycall_reconcile_inclusion(df, id_col = "nope"),
               regexp = "not found")
  expect_error(mysterycall_reconcile_inclusion(df, set = "bogus"))
  expect_error(mysterycall_reconcile_inclusion(42))
})

# ── print method ──────────────────────────────────────────────────────────────

test_that("print method runs and returns invisibly", {
  df <- make_recon_df()
  rec <- suppressMessages(mysterycall_reconcile_inclusion(df))
  expect_output(print(rec), "Inclusion Reconciliation")
  expect_output(print(rec), "code_only")
  expect_invisible(print(rec))
})
