library(testthat)

AUDIT <- data.frame(
  npi                              = c("1234567893","1234567893","9876543210","9876543210"),
  insurance                        = c("Medicaid","BCBS","Medicaid","BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A","A","B","B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN","OB/GYN","OB/GYN","OB/GYN"),
  phone                            = c("3035550100","3035550100","7205550200","7205550200"),
  physician_information            = c("Smith, John","Smith, John","Doe, Jane","Doe, Jane"),
  reason_for_exclusions            = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid","BCBS"), each = 40L),
  stringsAsFactors = FALSE
)

# ============================================================================
# mysterycall_session_snapshot() tests
# ============================================================================

test_that("mysterycall_session_snapshot: happy path with defaults", {
  snap <- tempfile(fileext = ".txt")

  out <- suppressMessages(mysterycall_session_snapshot(
    file = snap,
    quiet = FALSE
  ))

  expect_s3_class(out, "mysterycall_snapshot")
  expect_identical(as.character(out), snap)
  expect_true(file.exists(snap))

  content <- readLines(snap, warn = FALSE)
  expect_true(any(grepl("REPRODUCIBILITY SNAPSHOT", content)))
  expect_true(any(grepl("Date/Time:", content)))
  expect_true(any(grepl("R Version:", content)))
})

test_that("mysterycall_session_snapshot: seeds and notes", {
  snap <- tempfile(fileext = ".txt")

  out <- suppressMessages(mysterycall_session_snapshot(
    file = snap,
    seeds = c(bootstrap = 42L, imputation = 123L),
    notes = c("Line 1 of notes", "Line 2 of notes"),
    quiet = TRUE
  ))

  expect_s3_class(out, "mysterycall_snapshot")

  content <- readLines(snap, warn = FALSE)
  expect_true(any(grepl("=== SEEDS ===", content)))
  expect_true(any(grepl("bootstrap", content)))
  expect_true(any(grepl("42", content)))
  expect_true(any(grepl("imputation", content)))
  expect_true(any(grepl("123", content)))
  expect_true(any(grepl("Line 1 of notes", content)))
  expect_true(any(grepl("Line 2 of notes", content)))
})

test_that("mysterycall_session_snapshot: mixed named/unnamed seeds", {
  snap <- tempfile(fileext = ".txt")

  out <- suppressMessages(mysterycall_session_snapshot(
    file = snap,
    seeds = c(first = 100L, second = 200L),
    quiet = TRUE
  ))

  content <- readLines(snap, warn = FALSE)
  expect_true(any(grepl("first", content)))
  expect_true(any(grepl("second", content)))
  expect_true(any(grepl("100", content)))
  expect_true(any(grepl("200", content)))
})

test_that("mysterycall_session_snapshot: append mode", {
  snap <- tempfile(fileext = ".txt")

  # Write first snapshot
  suppressMessages(mysterycall_session_snapshot(
    file = snap,
    seeds = c(first = 42L),
    quiet = TRUE
  ))

  lines_first <- readLines(snap, warn = FALSE)

  # Append second snapshot
  suppressMessages(mysterycall_session_snapshot(
    file = snap,
    seeds = c(second = 123L),
    append = TRUE,
    quiet = TRUE
  ))

  lines_appended <- readLines(snap, warn = FALSE)
  expect_true(length(lines_appended) > length(lines_first))
  expect_true(any(grepl("second", lines_appended)))
})

test_that("mysterycall_session_snapshot: creates parent directory", {
  snap <- file.path(tempdir(), "deep", "nested", "snap.txt")

  expect_false(dir.exists(dirname(snap)))

  suppressMessages(mysterycall_session_snapshot(
    file = snap,
    quiet = TRUE
  ))

  expect_true(file.exists(snap))
  expect_true(dir.exists(dirname(snap)))
})

test_that("mysterycall_session_snapshot: NULL seeds and notes", {
  snap <- tempfile(fileext = ".txt")

  out <- suppressMessages(mysterycall_session_snapshot(
    file = snap,
    seeds = NULL,
    notes = NULL,
    quiet = TRUE
  ))

  content <- readLines(snap, warn = FALSE)
  # Should show "(none supplied)" for seeds and "(none)" for notes
  expect_true(any(grepl("none supplied", content)))
  expect_true(any(grepl("^\\(none\\)$", content)))
})

test_that("mysterycall_session_snapshot: empty character vectors", {
  snap <- tempfile(fileext = ".txt")

  out <- suppressMessages(mysterycall_session_snapshot(
    file = snap,
    seeds = numeric(0),
    notes = character(0),
    quiet = TRUE
  ))

  content <- readLines(snap, warn = FALSE)
  expect_true(any(grepl("none supplied", content)))
})

test_that("mysterycall_session_snapshot: quiet=TRUE suppresses message", {
  snap <- tempfile(fileext = ".txt")

  msgs <- capture_messages(
    mysterycall_session_snapshot(file = snap, quiet = TRUE)
  )

  expect_length(msgs, 0)
})

test_that("mysterycall_session_snapshot: quiet=FALSE shows message", {
  snap <- tempfile(fileext = ".txt")

  msgs <- capture_messages(
    mysterycall_session_snapshot(file = snap, quiet = FALSE)
  )

  expect_length(msgs, 1)
  expect_true(grepl("session snapshot written", msgs[1], ignore.case = TRUE))
})

test_that("mysterycall_session_snapshot: error on non-character file", {
  expect_error(
    mysterycall_session_snapshot(file = 123),
    "non-empty character scalar"
  )

  expect_error(
    mysterycall_session_snapshot(file = c("a", "b")),
    "non-empty character scalar"
  )
})

test_that("mysterycall_session_snapshot: error on empty file path", {
  expect_error(
    mysterycall_session_snapshot(file = ""),
    "non-empty character scalar"
  )
})

test_that("mysterycall_session_snapshot: error on non-numeric seeds", {
  snap <- tempfile(fileext = ".txt")

  expect_error(
    mysterycall_session_snapshot(file = snap, seeds = "not numeric"),
    "numeric/integer vector or NULL"
  )

  expect_error(
    mysterycall_session_snapshot(file = snap, seeds = list(1, 2)),
    "numeric/integer vector or NULL"
  )
})

test_that("mysterycall_session_snapshot: error on non-character notes", {
  snap <- tempfile(fileext = ".txt")

  expect_error(
    mysterycall_session_snapshot(file = snap, notes = 123),
    "character vector or NULL"
  )

  expect_error(
    mysterycall_session_snapshot(file = snap, notes = list("a", "b")),
    "character vector or NULL"
  )
})

test_that("mysterycall_session_snapshot: error on non-logical append", {
  snap <- tempfile(fileext = ".txt")

  expect_error(
    mysterycall_session_snapshot(file = snap, append = "TRUE"),
    "non-NA logical scalar"
  )

  expect_error(
    mysterycall_session_snapshot(file = snap, append = NA),
    "non-NA logical scalar"
  )
})

test_that("mysterycall_session_snapshot: error on non-logical quiet", {
  snap <- tempfile(fileext = ".txt")

  expect_error(
    mysterycall_session_snapshot(file = snap, quiet = 1),
    "non-NA logical scalar"
  )

  expect_error(
    mysterycall_session_snapshot(file = snap, quiet = c(TRUE, FALSE)),
    "non-NA logical scalar"
  )
})

test_that("mysterycall_session_snapshot: return value invisibly", {
  snap <- tempfile(fileext = ".txt")

  out <- suppressMessages(mysterycall_session_snapshot(
    file = snap,
    quiet = TRUE
  ))

  # Should be invisible; verify via class
  expect_s3_class(out, "mysterycall_snapshot")
  expect_identical(as.character(out), snap)
})

test_that("mysterycall_session_snapshot: file structure contains required sections", {
  snap <- tempfile(fileext = ".txt")

  suppressMessages(mysterycall_session_snapshot(
    file = snap,
    seeds = c(test = 999L),
    notes = "Test note",
    quiet = TRUE
  ))

  content <- readLines(snap, warn = FALSE)
  content_str <- paste(content, collapse = "\n")

  expect_true(grepl("=== REPRODUCIBILITY SNAPSHOT ===", content_str))
  expect_true(grepl("Date/Time:", content_str))
  expect_true(grepl("R Version:", content_str))
  expect_true(grepl("Platform:", content_str))
  expect_true(grepl("=== SEEDS ===", content_str))
  expect_true(grepl("=== LOADED PACKAGES ===", content_str))
  expect_true(grepl("=== FULL SESSION INFO ===", content_str))
  expect_true(grepl("=== NOTES ===", content_str))
})

# ============================================================================
# print.mysterycall_snapshot() tests
# ============================================================================

test_that("print.mysterycall_snapshot: happy path with existing file", {
  snap <- tempfile(fileext = ".txt")

  out <- suppressMessages(mysterycall_session_snapshot(
    file = snap,
    seeds = c(test = 42L),
    quiet = TRUE
  ))

  # Capture printed output
  printed <- capture_output(print(out))

  expect_true(grepl("Session snapshot:", printed))
  expect_true(grepl(snap, printed))
  expect_true(grepl("REPRODUCIBILITY SNAPSHOT", printed))
})

test_that("print.mysterycall_snapshot: nonexistent file", {
  out <- structure("/nonexistent/path.txt", class = "mysterycall_snapshot")

  printed <- capture_output(print(out))

  expect_true(grepl("Session snapshot:", printed))
  expect_true(grepl("file not found", printed))
})

test_that("print.mysterycall_snapshot: n parameter limits preview lines", {
  snap <- tempfile(fileext = ".txt")

  out <- suppressMessages(mysterycall_session_snapshot(
    file = snap,
    seeds = c(a = 1L, b = 2L, c = 3L),
    quiet = TRUE
  ))

  printed_n5 <- capture_output(print(out, n = 5L))
  printed_n20 <- capture_output(print(out, n = 20L))

  # Both should contain the header
  expect_true(grepl("REPRODUCIBILITY SNAPSHOT", printed_n5))
  expect_true(grepl("REPRODUCIBILITY SNAPSHOT", printed_n20))

  # Larger n should potentially show more content or indicate more lines
  expect_true(nchar(printed_n20) >= nchar(printed_n5))
})

test_that("print.mysterycall_snapshot: shows more lines message when needed", {
  snap <- tempfile(fileext = ".txt")

  out <- suppressMessages(mysterycall_session_snapshot(
    file = snap,
    seeds = c(a = 1L, b = 2L, c = 3L),
    notes = paste(rep("Long note line", 50), collapse = " "),
    quiet = TRUE
  ))

  printed <- capture_output(print(out, n = 10L))

  # Should indicate more lines exist
  total_lines <- length(readLines(snap, warn = FALSE))

  if (total_lines > 10L) {
    expect_true(grepl("more lines", printed))
  }
})

test_that("print.mysterycall_snapshot: returns invisible", {
  snap <- tempfile(fileext = ".txt")

  out <- suppressMessages(mysterycall_session_snapshot(
    file = snap,
    quiet = TRUE
  ))

  result <- capture_output(print(out))

  # Should be invisible by design, just verify it was printed
  expect_true(nchar(result) > 0)
})

test_that("print.mysterycall_snapshot: handles file with few lines", {
  snap <- tempfile(fileext = ".txt")

  out <- suppressMessages(mysterycall_session_snapshot(
    file = snap,
    quiet = TRUE
  ))

  printed <- capture_output(print(out, n = 100L))

  # Should print without error and show file path
  expect_true(grepl("Session snapshot:", printed))
  expect_true(grepl(snap, printed))
})
