library(testthat)

# mysterycall_run_workflow() renames incoming columns to short "standard" names
# (reason_for_exclusions -> exclusion_reasons). mysterycall_run_analysis()
# documents the long names as defaults. These tests pin the reconciliation so
# the two functions chain without silently dropping exclusion-dependent steps.

test_that(".mc_resolve_col prefers the primary, then an alias, else the primary", {
  d_long  <- data.frame(reason_for_exclusions = "x", stringsAsFactors = FALSE)
  d_short <- data.frame(exclusion_reasons = "x", stringsAsFactors = FALSE)
  d_none  <- data.frame(other = "x", stringsAsFactors = FALSE)

  # primary present -> primary, even when an alias is also present
  d_both <- data.frame(
    reason_for_exclusions = "x", exclusion_reasons = "y",
    stringsAsFactors = FALSE
  )
  expect_equal(
    mysterycall:::.mc_resolve_col(d_long, "reason_for_exclusions", "exclusion_reasons"),
    "reason_for_exclusions"
  )
  expect_equal(
    mysterycall:::.mc_resolve_col(d_both, "reason_for_exclusions", "exclusion_reasons"),
    "reason_for_exclusions"
  )
  # primary absent, alias present -> alias
  expect_equal(
    mysterycall:::.mc_resolve_col(d_short, "reason_for_exclusions", "exclusion_reasons"),
    "exclusion_reasons"
  )
  # neither present -> primary unchanged (preserves the existing skip path)
  expect_equal(
    mysterycall:::.mc_resolve_col(d_none, "reason_for_exclusions", "exclusion_reasons"),
    "reason_for_exclusions"
  )
  # no aliases supplied -> primary unchanged
  expect_equal(
    mysterycall:::.mc_resolve_col(d_none, "reason_for_exclusions"),
    "reason_for_exclusions"
  )
})

test_that("run_analysis resolves the workflow's short exclusion column", {
  # Data as mysterycall_run_workflow() would emit it: the short standard name.
  df <- data.frame(
    exclusion_reasons               = c("Able to contact", "No"),
    business_days_until_appointment = c(5, 10),
    stringsAsFactors = FALSE
  )

  msgs <- testthat::capture_messages(
    suppressWarnings(
      mysterycall_run_analysis(df, steps = "qc", output_dir = NA, verbose = TRUE)
    )
  )

  # The exclusion column was resolved to the workflow alias ...
  expect_true(any(grepl("workflow alias 'exclusion_reasons'", msgs, fixed = TRUE)))
  # ... so the exclusion-dependent QC step was NOT silently skipped.
  expect_false(any(grepl("exclusion_discrepancy skipped", msgs, fixed = TRUE)))
})
