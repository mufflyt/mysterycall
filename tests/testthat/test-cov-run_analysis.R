library(testthat)
library(mysterycall)

# ---------------------------------------------------------------------------
# Shared fixture: full-featured data frame that exercises all pipeline steps
# ---------------------------------------------------------------------------
set.seed(124)
N_PHYS <- 20L
PHONES <- paste0("303555", sprintf("%04d", seq_len(N_PHYS)))

RUN_DF <- data.frame(
  id_number  = rep(paste0("NPI", seq_len(N_PHYS)), 2L),
  phone      = rep(PHONES, 2L),
  insurance  = c(rep("Medicaid", N_PHYS),
                 rep("Blue Cross/Blue Shield", N_PHYS)),
  reason_for_exclusions = rep("Able to contact", 2L * N_PHYS),
  business_days_until_appointment = c(rpois(N_PHYS, 5L), rpois(N_PHYS, 10L)),
  scenario   = sample(c("HIP scenario", "SHOULDER scenario"),
                      2L * N_PHYS, replace = TRUE),
  does_the_physician_accept_medicaid = sample(
    c("Yes they accept Medicaid", "No",
      "NA as this was a Blue Cross/Blue Shield call."),
    2L * N_PHYS, replace = TRUE
  ),
  physician_information = rep(paste0("Doctor", seq_len(N_PHYS), ", Test"), 2L),
  stringsAsFactors = FALSE
)

ALL_STEPS <- c("qc", "dedup", "clean_medicaid", "demographics",
               "scenarios", "acceptance_rates", "wait_times",
               "poisson", "sensitivity")

# ---------------------------------------------------------------------------
# 1. Happy path: return-value structure invariants
# ---------------------------------------------------------------------------
test_that("mysterycall_run_analysis returns a named list with required bookkeeping keys", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_run_analysis(RUN_DF, output_dir = NA, verbose = FALSE)
  ))

  expect_type(result, "list")

  # Three bookkeeping elements must always be present
  expect_true("steps_run"     %in% names(result))
  expect_true("steps_errored" %in% names(result))
  expect_true("data_deduped"  %in% names(result))

  # steps_run must echo back what was requested (default = all nine)
  expect_equal(result$steps_run, ALL_STEPS)

  # steps_errored must be a character vector (may be empty)
  expect_type(result$steps_errored, "character")

  # data_deduped must be a data frame
  expect_s3_class(result$data_deduped, "data.frame")
})

# ---------------------------------------------------------------------------
# 2. Single-step subset: only "poisson" requested
# ---------------------------------------------------------------------------
test_that("requesting only 'poisson' returns non-NULL poisson and NULL for all other steps", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_run_analysis(
      RUN_DF,
      steps      = "poisson",
      output_dir = NA,
      verbose    = FALSE
    )
  ))

  expect_false(is.null(result$poisson),
               label = "poisson slot must not be NULL when requested")
  expect_true("irr_table" %in% names(result$poisson),
              label = "poisson result must contain irr_table")
  expect_s3_class(result$poisson$irr_table, "data.frame")

  # All other nine-step slots must be NULL
  for (s in setdiff(ALL_STEPS, "poisson")) {
    expect_null(result[[s]],
                label = paste0("result$", s, " must be NULL when not in steps"))
  }
})

# ---------------------------------------------------------------------------
# 3. Edge case: 0-row data frame does not abort; pipeline returns list
# ---------------------------------------------------------------------------
test_that("0-row data frame does not cause an abort; returns a list", {
  empty_df <- RUN_DF[0L, ]
  result <- suppressMessages(suppressWarnings(
    mysterycall_run_analysis(
      empty_df,
      output_dir = NA,
      verbose    = FALSE
    )
  ))

  expect_type(result, "list")
  expect_s3_class(result$data_deduped, "data.frame")
  expect_equal(result$steps_run, ALL_STEPS)
})

# ---------------------------------------------------------------------------
# 4. Bad input: non-data-frame triggers an error immediately
# ---------------------------------------------------------------------------
test_that("passing a non-data-frame as data triggers an immediate error", {
  expect_error(
    mysterycall_run_analysis(list(a = 1, b = 2)),
    regexp = "data.frame|data frame",
    fixed  = FALSE
  )

  expect_error(
    mysterycall_run_analysis("not a data frame"),
    regexp = "data.frame|data frame",
    fixed  = FALSE
  )

  expect_error(
    mysterycall_run_analysis(NULL),
    regexp = "data.frame|data frame",
    fixed  = FALSE
  )
})

# ---------------------------------------------------------------------------
# 5. Missing columns: steps that require absent columns are skipped gracefully
# ---------------------------------------------------------------------------
test_that("missing outcome_col skips dependent steps and pipeline still returns a list", {
  # Drop business_days_until_appointment so that wait_times, poisson,
  # acceptance_rates, and sensitivity cannot run
  df_no_outcome <- RUN_DF[, setdiff(names(RUN_DF), "business_days_until_appointment")]

  result <- suppressMessages(suppressWarnings(
    mysterycall_run_analysis(
      df_no_outcome,
      outcome_col = "business_days_until_appointment",
      output_dir  = NA,
      verbose     = FALSE
    )
  ))

  expect_type(result, "list")
  expect_s3_class(result$data_deduped, "data.frame")

  # Steps that explicitly check for outcome_col before running must be NULL
  expect_null(result$wait_times, label = "wait_times must be NULL when outcome_col absent")
  expect_null(result$poisson,    label = "poisson must be NULL when outcome_col absent")

  # steps_errored must flag at least the steps that depend on outcome_col
  errored <- result$steps_errored
  expect_type(errored, "character")
  expect_true(
    any(c("wait_times", "poisson", "acceptance_rates") %in% errored),
    label = "at least one outcome_col-dependent step must appear in steps_errored"
  )
})
