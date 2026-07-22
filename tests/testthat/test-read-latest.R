library(testthat)
library(mysterycall)

# Helper: create a directory of files with controlled modification times.
# `ages` is a named list of file -> age-in-seconds (older = larger).
make_dir <- function(files_ages) {
  dir <- tempfile("mc_latest_")
  dir.create(dir)
  now <- Sys.time()
  for (nm in names(files_ages)) {
    p <- file.path(dir, nm)
    utils::write.csv(data.frame(x = seq_len(nchar(nm))), p, row.names = FALSE)
    Sys.setFileTime(p, now - files_ages[[nm]])
  }
  dir
}

# ── selection ─────────────────────────────────────────────────────────────────

test_that("read=FALSE returns the newest matching file path", {
  dir <- make_dir(list(
    "export_2026-07-01.csv" = 7200,  # 2h old
    "export_2026-07-20.csv" = 60     # 1min old  <- newest
  ))
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  path <- suppressMessages(
    mysterycall_read_latest(dir, "\\.csv$", read = FALSE)
  )

  expect_equal(basename(path), "export_2026-07-20.csv")
})

test_that("read=TRUE returns file contents with the path attribute attached", {
  skip_if_not_installed("readr")

  dir <- make_dir(list(
    "old.csv" = 7200,
    "new.csv" = 60
  ))
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  df <- suppressMessages(
    mysterycall_read_latest(dir, "\\.csv$", read = TRUE)
  )

  expect_s3_class(df, "data.frame")
  expect_equal(basename(attr(df, "path")), "new.csv")
  # new.csv has 7 characters -> 7 rows
  expect_equal(nrow(df), 7L)
})

test_that("pattern filters candidates before choosing the newest", {
  # The newest file overall (.txt) must NOT be chosen when pattern is csv-only.
  dir <- make_dir(list(
    "roster.csv"    = 3600,  # older, but matches
    "scratch.txt"   = 10     # newest, but excluded by pattern
  ))
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  path <- suppressMessages(
    mysterycall_read_latest(dir, "\\.csv$", read = FALSE)
  )

  expect_equal(basename(path), "roster.csv")
})

# ── loud failures ─────────────────────────────────────────────────────────────

test_that("errors (never returns NA) when nothing matches", {
  dir <- make_dir(list("data.parquet" = 60))
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  expect_error(
    suppressMessages(mysterycall_read_latest(dir, "\\.csv$", read = FALSE)),
    regexp = "No files match"
  )
})

test_that("errors when the directory does not exist", {
  missing <- tempfile("does_not_exist_")
  expect_error(
    mysterycall_read_latest(missing, read = FALSE),
    regexp = "does not exist"
  )
})

# ── announcement ──────────────────────────────────────────────────────────────

test_that("announces the chosen file and candidate count", {
  dir <- make_dir(list(
    "a.csv" = 7200,
    "b.csv" = 3600,
    "c.csv" = 60
  ))
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  expect_message(
    mysterycall_read_latest(dir, "\\.csv$", read = FALSE),
    regexp = "chose 'c.csv'.*beat 2 other candidate"
  )
})

test_that("quiet=TRUE suppresses the announcement", {
  dir <- make_dir(list("a.csv" = 60))
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  expect_no_message(
    mysterycall_read_latest(dir, "\\.csv$", read = FALSE, quiet = TRUE)
  )
})

# ── staleness ─────────────────────────────────────────────────────────────────

test_that("warns when the newest match is older than max_age_days", {
  dir <- make_dir(list("stale.csv" = 60 * 60 * 24 * 5))  # 5 days old
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  expect_warning(
    suppressMessages(
      mysterycall_read_latest(dir, "\\.csv$", read = FALSE, max_age_days = 1)
    ),
    regexp = "days old"
  )
})

test_that("no staleness warning when the newest match is fresh", {
  dir <- make_dir(list("fresh.csv" = 60))  # 1 min old
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  expect_no_warning(
    suppressMessages(
      mysterycall_read_latest(dir, "\\.csv$", read = FALSE, max_age_days = 1)
    )
  )
})

# ── ties ──────────────────────────────────────────────────────────────────────

test_that("warns when two files share the newest modification time", {
  dir <- tempfile("mc_tie_")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  t <- Sys.time()
  for (nm in c("tie_a.csv", "tie_b.csv")) {
    p <- file.path(dir, nm)
    utils::write.csv(data.frame(x = 1), p, row.names = FALSE)
    Sys.setFileTime(p, t)
  }

  expect_warning(
    suppressMessages(mysterycall_read_latest(dir, "\\.csv$", read = FALSE)),
    regexp = "share the newest modification time"
  )
})

# ── recursion ─────────────────────────────────────────────────────────────────

test_that("recursive=TRUE searches subdirectories", {
  dir <- tempfile("mc_rec_")
  dir.create(file.path(dir, "sub"), recursive = TRUE)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  p <- file.path(dir, "sub", "nested.csv")
  utils::write.csv(data.frame(x = 1), p, row.names = FALSE)

  # Non-recursive finds nothing -> errors
  expect_error(
    suppressMessages(
      mysterycall_read_latest(dir, "\\.csv$", read = FALSE, recursive = FALSE)
    ),
    regexp = "No files match"
  )

  # Recursive finds the nested file
  path <- suppressMessages(
    mysterycall_read_latest(dir, "\\.csv$", read = FALSE, recursive = TRUE)
  )
  expect_equal(basename(path), "nested.csv")
})

# ── input validation ──────────────────────────────────────────────────────────

test_that("invalid arguments are rejected", {
  dir <- make_dir(list("a.csv" = 60))
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  expect_error(mysterycall_read_latest(dir, read = "yes"))
  expect_error(mysterycall_read_latest(dir, max_age_days = -1))
  expect_error(mysterycall_read_latest(123))
})
