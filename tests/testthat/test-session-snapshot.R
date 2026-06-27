test_that("returns invisible character with class mysterycall_snapshot", {
  snap <- tempfile(fileext = ".txt")
  vis  <- withVisible(mysterycall_session_snapshot(file = snap, quiet = TRUE))

  expect_false(vis$visible)
  expect_type(vis$value, "character")
  expect_s3_class(vis$value, "mysterycall_snapshot")
  expect_equal(as.character(vis$value), snap)
})

test_that("file is created at the specified path", {
  snap <- tempfile(fileext = ".txt")
  mysterycall_session_snapshot(file = snap, quiet = TRUE)

  expect_true(file.exists(snap))
})

test_that("file contains R Version text", {
  snap <- tempfile(fileext = ".txt")
  mysterycall_session_snapshot(file = snap, quiet = TRUE)

  content <- readLines(snap, warn = FALSE)
  expect_true(any(grepl("R Version", content, fixed = TRUE)))
})

test_that("file contains SEEDS section and seed values when seeds provided", {
  snap  <- tempfile(fileext = ".txt")
  seeds <- c(bootstrap = 42L, imputation = 123L)
  mysterycall_session_snapshot(file = snap, seeds = seeds, quiet = TRUE)

  content <- readLines(snap, warn = FALSE)
  expect_true(any(grepl("=== SEEDS ===", content, fixed = TRUE)))
  expect_true(any(grepl("bootstrap", content, fixed = TRUE)))
  expect_true(any(grepl("imputation", content, fixed = TRUE)))
})

test_that("file contains NOTES section and note text when notes provided", {
  snap  <- tempfile(fileext = ".txt")
  notes <- "Primary sensitivity analysis."
  mysterycall_session_snapshot(file = snap, notes = notes, quiet = TRUE)

  content <- readLines(snap, warn = FALSE)
  expect_true(any(grepl("=== NOTES ===", content, fixed = TRUE)))
  expect_true(any(grepl("Primary sensitivity analysis.", content, fixed = TRUE)))
})

test_that("file contains LOADED PACKAGES section", {
  snap <- tempfile(fileext = ".txt")
  mysterycall_session_snapshot(file = snap, quiet = TRUE)

  content <- readLines(snap, warn = FALSE)
  expect_true(any(grepl("=== LOADED PACKAGES ===", content, fixed = TRUE)))
})

test_that("append=TRUE appends content to an existing file", {
  snap <- tempfile(fileext = ".txt")
  mysterycall_session_snapshot(file = snap, notes = "run 1", quiet = TRUE)
  n_first <- length(readLines(snap, warn = FALSE))

  mysterycall_session_snapshot(file = snap, notes = "run 2", append = TRUE, quiet = TRUE)
  content <- readLines(snap, warn = FALSE)

  expect_gt(length(content), n_first)
  expect_true(any(grepl("run 1", content, fixed = TRUE)))
  expect_true(any(grepl("run 2", content, fixed = TRUE)))
})

test_that("append=FALSE overwrites existing file", {
  snap <- tempfile(fileext = ".txt")
  mysterycall_session_snapshot(file = snap, notes = "run 1", quiet = TRUE)

  mysterycall_session_snapshot(file = snap, notes = "run 2", append = FALSE, quiet = TRUE)
  content <- readLines(snap, warn = FALSE)

  expect_false(any(grepl("run 1", content, fixed = TRUE)))
  expect_true(any(grepl("run 2", content, fixed = TRUE)))
})

test_that("quiet=TRUE suppresses message", {
  snap <- tempfile(fileext = ".txt")

  expect_silent(
    mysterycall_session_snapshot(file = snap, quiet = TRUE)
  )
})

test_that("quiet=FALSE emits a message containing the file path", {
  snap <- tempfile(fileext = ".txt")

  expect_message(
    mysterycall_session_snapshot(file = snap, quiet = FALSE),
    regexp = snap,
    fixed  = TRUE
  )
})

test_that("seeds are formatted as name: value pairs on the same line", {
  snap  <- tempfile(fileext = ".txt")
  seeds <- c(bootstrap = 42L, imputation = 123L)
  mysterycall_session_snapshot(file = snap, seeds = seeds, quiet = TRUE)

  content <- readLines(snap, warn = FALSE)
  # Each seed must appear on a line together with its integer value
  bootstrap_line  <- content[grepl("bootstrap",  content, fixed = TRUE)]
  imputation_line <- content[grepl("imputation", content, fixed = TRUE)]

  expect_true(length(bootstrap_line)  >= 1L)
  expect_true(length(imputation_line) >= 1L)
  expect_true(any(grepl("42",  bootstrap_line,  fixed = TRUE)))
  expect_true(any(grepl("123", imputation_line, fixed = TRUE)))
})

test_that("works end-to-end with a tempfile() path", {
  snap <- tempfile(fileext = ".txt")
  result <- mysterycall_session_snapshot(
    file  = snap,
    seeds = c(main = 7L),
    notes = "tempfile integration test",
    quiet = TRUE
  )

  expect_true(file.exists(snap))
  expect_equal(as.character(result), snap)
  content <- readLines(snap, warn = FALSE)
  expect_true(any(grepl("tempfile integration test", content, fixed = TRUE)))
})

test_that("creates parent directory automatically when it does not exist", {
  td   <- tempfile()           # path that does not yet exist
  snap <- file.path(td, "sub", "snapshot.txt")

  expect_no_error(
    mysterycall_session_snapshot(file = snap, quiet = TRUE)
  )
  expect_true(file.exists(snap))
})
