library(testthat)
testthat::skip_if_not_installed("readr")

# ── mysterycall_normalize_file_format ───────────────────────────────────────────────
# All expected values manually verified via Rscript before writing.

test_that("mysterycall_normalize_file_format - 'csv' returns 'csv'", {
  expect_equal(mysterycall_normalize_file_format("csv"), "csv")
})

test_that("mysterycall_normalize_file_format - 'parquet' returns 'parquet'", {
  expect_equal(mysterycall_normalize_file_format("parquet"), "parquet")
})

test_that("mysterycall_normalize_file_format - invalid format stops", {
  expect_error(mysterycall_normalize_file_format("excel"))
})

test_that("mysterycall_normalize_file_format - infers csv from .csv path", {
  expect_equal(mysterycall_normalize_file_format(path = "data/physicians.csv"), "csv")
})

test_that("mysterycall_normalize_file_format - infers parquet from .parquet path", {
  expect_equal(mysterycall_normalize_file_format(path = "output/results.parquet"), "parquet")
})

test_that("mysterycall_normalize_file_format - unknown extension falls back to default 'csv'", {
  expect_equal(mysterycall_normalize_file_format(path = "file.xlsx"), "csv")
})

test_that("mysterycall_normalize_file_format - no args returns default 'csv'", {
  expect_equal(mysterycall_normalize_file_format(), "csv")
})

test_that("mysterycall_normalize_file_format - explicit format overrides path extension", {
  # format='parquet' wins over .csv extension
  expect_equal(mysterycall_normalize_file_format(format = "parquet", path = "file.csv"), "parquet")
})

# ── mysterycall_tempdir ─────────────────────────────────────────────────────────────

test_that("mysterycall_tempdir - returns a character string", {
  expect_type(mysterycall_tempdir(), "character")
})

test_that("mysterycall_tempdir - path contains 'mysterycall' subdirectory", {
  path <- mysterycall_tempdir()
  expect_true(grepl("mysterycall", path, fixed = TRUE))
})

test_that("mysterycall_tempdir - appends sub-path components correctly", {
  path <- mysterycall_tempdir("phase1", "output")
  expect_true(grepl("phase1", path, fixed = TRUE))
  expect_true(grepl("output", path, fixed = TRUE))
})

test_that("mysterycall_tempdir - create=TRUE creates the directory", {
  subdir <- paste0("test_create_", Sys.getpid())
  path <- mysterycall_tempdir(subdir, create = TRUE)
  expect_true(dir.exists(path))
})

test_that("mysterycall_tempdir - create=FALSE does not create directory", {
  subdir <- paste0("test_no_create_", Sys.getpid(), "_xyz")
  path <- mysterycall_tempdir(subdir, create = FALSE)
  # Should not exist (we've never created this unique name)
  expect_false(dir.exists(path))
})

test_that("mysterycall_tempdir - calling twice returns the same path", {
  p1 <- mysterycall_tempdir("stable_subdir")
  p2 <- mysterycall_tempdir("stable_subdir")
  expect_equal(p1, p2)
})

# ── mysterycall_write_table / mysterycall_read_table (CSV roundtrip) ──────────────────────

test_that("mysterycall_write_table + mysterycall_read_table - CSV roundtrip preserves rows and cols", {
  df <- data.frame(
    id   = 1:5,
    name = c("Alice", "Bob", "Carol", "Dan", "Eve"),
    score = c(1.1, 2.2, 3.3, 4.4, 5.5)
  )
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  mysterycall_write_table(df, tmp, format = "csv")
  df2 <- mysterycall_read_table(tmp, format = "csv")
  expect_equal(nrow(df2), 5L)
  expect_equal(ncol(df2), 3L)
  expect_equal(df2$score, df$score, tolerance = 1e-9)
})

test_that("mysterycall_write_table + mysterycall_read_table - column names survive roundtrip", {
  df <- data.frame(npi = "1234567890", subspecialty = "Gyn Onc")
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  mysterycall_write_table(df, tmp, format = "csv")
  df2 <- mysterycall_read_table(tmp, format = "csv")
  expect_equal(names(df2), c("npi", "subspecialty"))
})

test_that("mysterycall_write_table - creates the output file", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  mysterycall_write_table(data.frame(x = 1:3), tmp, format = "csv")
  expect_true(file.exists(tmp))
})

test_that("mysterycall_write_table - returns the path invisibly", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  result <- mysterycall_write_table(data.frame(x = 1), tmp, format = "csv")
  expect_equal(result, tmp)
})

test_that("mysterycall_write_table - non-append writes replace atomically", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  mysterycall_write_table(data.frame(x = 1:3), tmp, format = "csv")
  mysterycall_write_table(data.frame(x = 4:6), tmp, format = "csv")
  df2 <- mysterycall_read_table(tmp, format = "csv")

  expect_equal(df2$x, 4:6)
  tmp_sidecars <- list.files(dirname(tmp), pattern = "\\.tmp$", full.names = TRUE)
  expect_equal(length(tmp_sidecars), 0L)
})

test_that("mysterycall_read_table - infers CSV format from file extension", {
  df <- data.frame(a = 1:3)
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  readr::write_csv(df, tmp)
  df2 <- mysterycall_read_table(tmp)          # no format arg: inferred from extension
  expect_equal(nrow(df2), 3L)
})

test_that("mysterycall_write_table + mysterycall_read_table - empty data frame roundtrip", {
  df <- data.frame(npi = character(0), state = character(0))
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  mysterycall_write_table(df, tmp, format = "csv")
  df2 <- mysterycall_read_table(tmp, format = "csv")
  expect_equal(nrow(df2), 0L)
  expect_equal(names(df2), c("npi", "state"))
})

test_that("mysterycall_require_arrow - errors with install message when arrow absent", {
  # If arrow is installed skip this; we can still test the message format
  skip_if(requireNamespace("arrow", quietly = TRUE), "arrow is installed")
  expect_error(mysterycall_require_arrow(), "arrow")
})
test_that("mysterycall_read_table normalizes numeric-looking npi columns to character digits", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  writeLines(c("npi", "1922051358"), tmp)
  df <- mysterycall_read_table(tmp, format = "csv")
  expect_type(df$npi, "character")
  expect_equal(df$npi, "1922051358")
})

# Regression (bug 43): a missing numeric NPI must round-trip to NA_character_,
# not the literal string "NA" (which would collide across rows in joins).
test_that("mysterycall_read_table - missing numeric NPI stays NA, not 'NA'", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  writeLines(c("npi,x", "1234567893,a", "NA,b", "9876543210,c"), tmp)
  df <- mysterycall_read_table(tmp, format = "csv")
  expect_type(df$npi, "character")
  expect_true(is.na(df$npi[2]))
  expect_false(any(df$npi == "NA", na.rm = TRUE))
  expect_equal(df$npi[c(1L, 3L)], c("1234567893", "9876543210"))
})
