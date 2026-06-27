# tests/testthat/test-run-analysis.R
# Tests for mysterycall_run_analysis() pipeline orchestrator

# ---------------------------------------------------------------------------
# Shared test data (set.seed(1) for reproducibility)
# ---------------------------------------------------------------------------
set.seed(1)
n_phys  <- 20L
phones  <- paste0("555-", sprintf("%04d", seq_len(n_phys)))
df_full <- data.frame(
  id_number  = rep(paste0("NPI", seq_len(n_phys)), 2L),
  phone      = rep(phones, 2L),
  insurance  = c(rep("Medicaid", n_phys),
                 rep("Blue Cross/Blue Shield", n_phys)),
  reason_for_exclusions = sample(
    c("Able to contact", "Not available"),
    2L * n_phys, replace = TRUE, prob = c(0.8, 0.2)
  ),
  business_days_until_appointment = rpois(2L * n_phys, lambda = 14L),
  scenario   = sample(
    c("HIP scenario", "SHOULDER scenario", "KNEE scenario"),
    2L * n_phys, replace = TRUE
  ),
  does_the_physician_accept_medicaid = sample(
    c("Yes they accept Medicaid", "No",
      "NA as this was a Blue Cross/Blue Shield call."),
    2L * n_phys, replace = TRUE
  ),
  state = sample(
    c("Colorado", "Texas", "Florida", "Georgia", "California"),
    2L * n_phys, replace = TRUE
  ),
  stringsAsFactors = FALSE
)

all_steps <- c("qc", "dedup", "clean_medicaid", "demographics",
               "scenarios", "acceptance_rates", "wait_times",
               "poisson", "sensitivity")

# ---------------------------------------------------------------------------
# 1. Returns list
# ---------------------------------------------------------------------------
test_that("mysterycall_run_analysis returns a list", {
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, output_dir = NA)
  )
  expect_type(result, "list")
})

# ---------------------------------------------------------------------------
# 2. steps_run matches input steps argument
# ---------------------------------------------------------------------------
test_that("steps_run equals the steps argument that was passed", {
  my_steps <- c("qc", "dedup")
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, steps = my_steps, output_dir = NA)
  )
  expect_equal(result$steps_run, my_steps)
})

# ---------------------------------------------------------------------------
# 3. data_deduped is a data frame
# ---------------------------------------------------------------------------
test_that("data_deduped element is a data frame", {
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, output_dir = NA)
  )
  expect_s3_class(result$data_deduped, "data.frame")
})

# ---------------------------------------------------------------------------
# 4. Single-step subset works
# ---------------------------------------------------------------------------
test_that("running only the qc step returns non-NULL qc and NULL for unrun steps", {
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, steps = "qc", output_dir = NA)
  )
  expect_false(is.null(result$qc))
  expect_null(result$demographics)
  expect_null(result$dedup)
  expect_null(result$poisson)
})

# ---------------------------------------------------------------------------
# 5. Bad outcome_col makes wait_times NULL; rest of pipeline continues
# ---------------------------------------------------------------------------
test_that("bad outcome_col sets wait_times to NULL but pipeline continues", {
  result <- suppressMessages(
    mysterycall_run_analysis(
      df_full,
      outcome_col = "NONEXISTENT_COL",
      output_dir  = NA
    )
  )
  expect_null(result$wait_times)
  # Steps that do not depend on outcome_col should still produce results
  expect_false(is.null(result$qc))
  expect_false(is.null(result$dedup))
  expect_false(is.null(result$demographics))
  expect_false(is.null(result$scenarios))
})

# ---------------------------------------------------------------------------
# 6. verbose=FALSE suppresses orchestrator progress messages
# ---------------------------------------------------------------------------
test_that("verbose=FALSE suppresses orchestrator [step] progress messages", {
  captured <- character(0)
  withCallingHandlers(
    mysterycall_run_analysis(
      df_full, steps = "qc", verbose = FALSE, output_dir = NA
    ),
    message = function(m) {
      captured <<- c(captured, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  # The orchestrator's progress message starts with "[qc]"; it should be absent
  expect_false(any(startsWith(captured, "[qc]")))
})

# ---------------------------------------------------------------------------
# 7. output_dir=NA writes no CSV files (no "written to:" messages emitted)
# ---------------------------------------------------------------------------
test_that("output_dir=NA produces no file-write messages", {
  write_msgs <- character(0)
  withCallingHandlers(
    mysterycall_run_analysis(df_full, output_dir = NA, verbose = FALSE),
    message = function(m) {
      msg <- conditionMessage(m)
      if (grepl("written to:", msg, fixed = TRUE))
        write_msgs <<- c(write_msgs, msg)
      invokeRestart("muffleMessage")
    }
  )
  expect_equal(length(write_msgs), 0L)
})

# ---------------------------------------------------------------------------
# 8. Full pipeline on valid data: all 9 step slots are non-NULL
# ---------------------------------------------------------------------------
test_that("full pipeline on valid data yields non-NULL results for all 9 steps", {
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, output_dir = NA)
  )
  for (s in all_steps) {
    expect_false(
      is.null(result[[s]]),
      label = paste0("result$", s, " must not be NULL")
    )
  }
})

# ---------------------------------------------------------------------------
# 9. poisson slot contains irr_table
# ---------------------------------------------------------------------------
test_that("poisson step slot contains an irr_table element", {
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, steps = "poisson", output_dir = NA)
  )
  expect_false(is.null(result$poisson))
  expect_true("irr_table" %in% names(result$poisson))
  expect_s3_class(result$poisson$irr_table, "data.frame")
})

# ---------------------------------------------------------------------------
# 10. demographics slot contains summary_sentence
# ---------------------------------------------------------------------------
test_that("demographics step slot contains a summary_sentence element", {
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, steps = "demographics", output_dir = NA)
  )
  expect_false(is.null(result$demographics))
  expect_true("summary_sentence" %in% names(result$demographics))
  expect_type(result$demographics$summary_sentence, "character")
})

# ---------------------------------------------------------------------------
# 11. acceptance_rates slot contains paragraph
# ---------------------------------------------------------------------------
test_that("acceptance_rates step slot contains a paragraph element", {
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, steps = "acceptance_rates", output_dir = NA)
  )
  expect_false(is.null(result$acceptance_rates))
  expect_true("paragraph" %in% names(result$acceptance_rates))
  expect_type(result$acceptance_rates$paragraph, "character")
})

# ---------------------------------------------------------------------------
# 12. scenarios slot contains sentence
# ---------------------------------------------------------------------------
test_that("scenarios step slot contains a sentence element", {
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, steps = "scenarios", output_dir = NA)
  )
  expect_false(is.null(result$scenarios))
  expect_true("sentence" %in% names(result$scenarios))
  expect_type(result$scenarios$sentence, "character")
})

# ---------------------------------------------------------------------------
# 13. sensitivity slot contains n_both
# ---------------------------------------------------------------------------
test_that("sensitivity step slot contains an n_both element", {
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, steps = "sensitivity", output_dir = NA)
  )
  expect_false(is.null(result$sensitivity))
  expect_true("n_both" %in% names(result$sensitivity))
  expect_type(result$sensitivity$n_both, "integer")
})

# ---------------------------------------------------------------------------
# 14. steps="qc" only: poisson slot is NULL
# ---------------------------------------------------------------------------
test_that("steps='qc' only: poisson slot is NULL", {
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, steps = "qc", output_dir = NA)
  )
  expect_null(result$poisson)
})

# ---------------------------------------------------------------------------
# 15. data=NULL errors immediately with informative message
# ---------------------------------------------------------------------------
test_that("data=NULL throws an error immediately", {
  expect_error(
    mysterycall_run_analysis(NULL),
    regexp = "data.*must be a data frame",
    fixed  = FALSE
  )
})

# ---------------------------------------------------------------------------
# Bonus: steps_errored is a character vector in the return value
# ---------------------------------------------------------------------------
test_that("steps_errored is a character vector in the return value", {
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, output_dir = NA)
  )
  expect_type(result$steps_errored, "character")
})

# ---------------------------------------------------------------------------
# Bonus: empty steps vector returns all-NULL step slots
# ---------------------------------------------------------------------------
test_that("steps=character(0) returns NULL for every step slot", {
  result <- suppressMessages(
    mysterycall_run_analysis(df_full, steps = character(0), output_dir = NA)
  )
  for (s in all_steps) {
    expect_null(result[[s]],
                label = paste0("result$", s, " should be NULL when steps=character(0)"))
  }
  expect_equal(result$steps_run, character(0))
})
