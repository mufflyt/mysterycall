# Phase-1 to phase-2 column contract.
#
# mysterycall_run_workflow() renames incoming phase-2 columns to short standard
# names. mysterycall_run_analysis() takes the documented long names as its
# defaults. Where the two disagree and no alias is resolved, the analysis does
# not error -- it silently skips the step that needed the column. A missing
# exclusion column means the exclusion-dependent work quietly does not happen,
# and the run still reports success.
#
# That is the failure mode these tests exist to prevent. They are a regression
# guard: the contract is sound today, and the point is to notice the day it
# stops being sound, either because a new rename is added or because a new
# consumer of a renamed column is written without alias resolution.

fixture_path <- testthat::test_path("..", "fixtures", "canonical_study.R")
skip_if_not(file.exists(fixture_path), "canonical study fixture not found")
source(fixture_path)

# The rename map as mysterycall_run_workflow() declares it. Kept here
# deliberately rather than read from the function: if someone edits the map,
# this copy must be updated too, and that edit is the review moment.
RENAME_MAP <- c(
  physician_information  = "physician_info",
  able_to_contact_office = "contact_office",
  are_we_including       = "included_in_study",
  reason_for_exclusions  = "exclusion_reasons",
  appointment_date       = "appt_date",
  number_of_transfers    = "transfer_count",
  call_time              = "call_duration",
  hold_time              = "hold_duration",
  person_completing      = "completed_by"
)

test_that("the workflow rename map still matches the source of truth", {
  wf <- testthat::test_path("..", "..", "R", "run_mystery_caller_workflow.R")
  skip_if_not(file.exists(wf), "workflow source not found")
  src <- paste(readLines(wf, warn = FALSE), collapse = "\n")

  # Every pair this test relies on must still appear in the workflow's
  # declared vectors. If a rename is added or changed there without updating
  # this map, the rest of the file would be testing a contract that no longer
  # exists.
  for (long in names(RENAME_MAP)) {
    expect_true(grepl(paste0('"', long, '"'), src, fixed = TRUE),
                info = paste("long name absent from workflow source:", long))
    expect_true(grepl(paste0('"', RENAME_MAP[[long]], '"'), src, fixed = TRUE),
                info = paste("short name absent from workflow source:", RENAME_MAP[[long]]))
  }
})

test_that(".mc_resolve_col prefers the primary and falls back to an alias", {
  resolve <- mysterycall:::.mc_resolve_col

  long  <- data.frame(reason_for_exclusions = "Able to contact", stringsAsFactors = FALSE)
  short <- data.frame(exclusion_reasons     = "Able to contact", stringsAsFactors = FALSE)
  both  <- data.frame(reason_for_exclusions = "Able to contact",
                      exclusion_reasons     = "Able to contact", stringsAsFactors = FALSE)

  expect_equal(resolve(long,  "reason_for_exclusions", "exclusion_reasons"),
               "reason_for_exclusions")
  expect_equal(resolve(short, "reason_for_exclusions", "exclusion_reasons"),
               "exclusion_reasons")
  # When both are present the caller's explicit choice must win, otherwise a
  # stray alias column could silently redirect the analysis.
  expect_equal(resolve(both,  "reason_for_exclusions", "exclusion_reasons"),
               "reason_for_exclusions")
  # With neither present it returns the primary, so the caller sees a missing
  # column rather than a surprising substitution.
  expect_equal(resolve(data.frame(x = 1), "reason_for_exclusions", "exclusion_reasons"),
               "reason_for_exclusions")
})

test_that("every renamed column consumed by run_analysis has alias resolution", {
  ra <- testthat::test_path("..", "..", "R", "run_analysis.R")
  skip_if_not(file.exists(ra), "run_analysis source not found")
  src <- readLines(ra, warn = FALSE)
  src <- src[!grepl("^\\s*#", src)]          # ignore comments
  body <- paste(src, collapse = "\n")

  unresolved <- character(0)
  for (long in names(RENAME_MAP)) {
    short <- RENAME_MAP[[long]]
    consumed <- grepl(paste0("\\b", long, "\\b"), body)
    if (!consumed) next                      # not used; no contract to honour
    resolved <- grepl(paste0("\\b", short, "\\b"), body)
    if (!resolved) unresolved <- c(unresolved, paste0(long, " -> ", short))
  }

  expect_equal(
    unresolved, character(0),
    info = paste0(
      "run_analysis() consumes these columns under their long names but never ",
      "mentions the short name the workflow renames them to, so piping the ",
      "workflow's output in would silently skip the dependent step: ",
      paste(unresolved, collapse = "; ")
    )
  )
})

test_that("the canonical study survives the workflow rename intact", {
  long_names  <- mc_canonical_study()$study
  short_names <- mc_canonical_study_workflow_names()

  expect_equal(nrow(long_names), nrow(short_names))

  # Renaming must move values, not drop or reorder them.
  expect_true("reason_for_exclusions" %in% names(long_names))
  expect_true("exclusion_reasons"     %in% names(short_names))
  expect_equal(unname(long_names$reason_for_exclusions),
               unname(short_names$exclusion_reasons))

  expect_true("physician_information" %in% names(long_names))
  expect_true("physician_info"        %in% names(short_names))
  expect_equal(unname(long_names$physician_information),
               unname(short_names$physician_info))

  # Columns the workflow does not rename must be untouched.
  for (col in c("id_number", "insurance", "business_days_until_appointment")) {
    expect_true(col %in% names(short_names), info = col)
    expect_equal(unname(long_names[[col]]), unname(short_names[[col]]), info = col)
  }
})

test_that("exclusion filtering yields the same denominator under either naming", {
  # The concrete consequence of a broken contract: the exclusion-dependent
  # denominator changes depending on which naming the data arrives in. It must
  # not.
  CONTACT <- "Able to contact"
  long_names  <- mc_canonical_study()$study
  short_names <- mc_canonical_study_workflow_names()

  n_long  <- sum(long_names$reason_for_exclusions == CONTACT)
  n_short <- sum(short_names$exclusion_reasons    == CONTACT)

  expect_equal(n_long, n_short)
  expect_gt(n_long, 0)
})
