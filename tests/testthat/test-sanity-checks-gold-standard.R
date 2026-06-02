library(testthat)

# All expected values hand-verified before writing.
# These tests exercise purely computational logic — no API calls, no files.

# ── mysterycall_check_no_limits ─────────────────────────────────────────────────────

test_that("mysterycall_check_no_limits - non-suspicious row count returns invisible TRUE", {
  df <- data.frame(x = 1:42)   # 42 is not in the suspicious list
  result <- suppressWarnings(mysterycall:::mysterycall_check_no_limits(df, "test_data"))
  expect_true(isTRUE(result))
})

test_that("mysterycall_check_no_limits - returns invisible (not printed)", {
  df <- data.frame(x = 1:42)
  # Must test invisibility on the call itself, not on an already-bound variable
  expect_false(withVisible(suppressWarnings(mysterycall:::mysterycall_check_no_limits(df, "test")))$visible)
})

test_that("mysterycall_check_no_limits - exactly 100 rows triggers SUSPICIOUS warning", {
  df <- data.frame(x = 1:100)
  expect_warning(
    mysterycall:::mysterycall_check_no_limits(df, "api_result"),
    "SUSPICIOUS"
  )
})

test_that("mysterycall_check_no_limits - exactly 1000 rows triggers SUSPICIOUS warning", {
  df <- data.frame(x = seq_len(1000))
  expect_warning(
    mysterycall:::mysterycall_check_no_limits(df, "api_result"),
    "SUSPICIOUS"
  )
})

test_that("mysterycall_check_no_limits - zero rows warns about ZERO rows", {
  df <- data.frame(x = integer(0))
  expect_warning(
    mysterycall:::mysterycall_check_no_limits(df, "empty_result"),
    "ZERO"
  )
})

test_that("mysterycall_check_no_limits - min_expected violation warns with row counts", {
  # Use 7 rows (not in suspicious_counts) so only the min_expected warning fires
  df <- data.frame(x = 1:7)
  expect_warning(
    mysterycall:::mysterycall_check_no_limits(df, "sparse", min_expected = 50),
    "only 7"
  )
})

test_that("mysterycall_check_no_limits - max_expected violation warns when exceeded", {
  # Use 47 rows (not suspicious) to test max_expected path cleanly
  df <- data.frame(x = 1:47)
  expect_warning(
    mysterycall:::mysterycall_check_no_limits(df, "bloated", max_expected = 20),
    "47"
  )
})

test_that("mysterycall_check_no_limits - non-data-frame input stops", {
  expect_error(
    mysterycall:::mysterycall_check_no_limits("not a data frame", "test"),
    class = "simpleError"
  )
})

test_that("mysterycall_check_no_limits - min and max both satisfied: no warning", {
  df <- data.frame(x = 1:42)
  expect_no_warning(
    mysterycall:::mysterycall_check_no_limits(df, "ok", min_expected = 10, max_expected = 200)
  )
})

# ── mysterycall_check_no_data_loss ──────────────────────────────────────────────────

test_that("mysterycall_check_no_data_loss - exact match returns invisible TRUE", {
  result <- suppressWarnings(mysterycall:::mysterycall_check_no_data_loss(100, 100, "cleaning"))
  expect_true(isTRUE(result))
})

test_that("mysterycall_check_no_data_loss - accepts data frames instead of integers", {
  before_df <- data.frame(x = 1:80)
  after_df  <- data.frame(x = 1:80)
  result <- suppressWarnings(mysterycall:::mysterycall_check_no_data_loss(before_df, after_df, "test"))
  expect_true(isTRUE(result))
})

test_that("mysterycall_check_no_data_loss - data loss stops with DATA LOSS in message", {
  expect_error(
    mysterycall:::mysterycall_check_no_data_loss(100, 80, "dedup", expected_change = 0, tolerance = 0),
    "DATA LOSS"
  )
})

test_that("mysterycall_check_no_data_loss - expected decrease within tolerance passes", {
  # Removing 10 rows on purpose, tolerance 0 → exact match required
  result <- suppressWarnings(
    mysterycall:::mysterycall_check_no_data_loss(100, 90, "dedup", expected_change = -10, tolerance = 0)
  )
  expect_true(isTRUE(result))
})

test_that("mysterycall_check_no_data_loss - unexpected row increase warns", {
  expect_warning(
    mysterycall:::mysterycall_check_no_data_loss(50, 200, "join", expected_change = 0, tolerance = 0),
    regexp = "INCREASE|increase|added|Added",
    ignore.case = TRUE
  )
})

test_that("mysterycall_check_no_data_loss - data loss within tolerance passes", {
  # Lost 3 rows but tolerance is 5 → should pass
  result <- suppressWarnings(
    mysterycall:::mysterycall_check_no_data_loss(100, 97, "filter", expected_change = 0, tolerance = 5)
  )
  expect_true(isTRUE(result))
})

# ── mysterycall_check_api_response ──────────────────────────────────────────────────

test_that("mysterycall_check_api_response - exact row count match returns invisible TRUE", {
  df <- data.frame(lat = 1:25, lon = 1:25)
  result <- mysterycall:::mysterycall_check_api_response(df, expected = 25, api_name = "Geocoder")
  expect_true(isTRUE(result))
})

test_that("mysterycall_check_api_response - mismatch stops with informative message", {
  df <- data.frame(x = 1:8)
  expect_error(
    mysterycall:::mysterycall_check_api_response(df, expected = 10, api_name = "GoogleMaps"),
    "mismatch"
  )
})

test_that("mysterycall_check_api_response - non-data-frame stops with class info", {
  expect_error(
    mysterycall:::mysterycall_check_api_response("not a df", expected = 1, api_name = "test"),
    class = "simpleError"
  )
})

test_that("mysterycall_check_api_response - zero expected with zero rows passes", {
  df <- data.frame(x = integer(0))
  result <- mysterycall:::mysterycall_check_api_response(df, expected = 0, api_name = "empty")
  expect_true(isTRUE(result))
})

# ── mysterycall_scan_for_limits ─────────────────────────────────────────────────────

test_that("mysterycall_scan_for_limits - returns a data frame with required columns", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  writeLines("x <- 1", file.path(tmp_dir, "test.R"))
  on.exit(unlink(tmp_dir, recursive = TRUE))
  result <- suppressWarnings(mysterycall:::mysterycall_scan_for_limits(tmp_dir))
  expect_s3_class(result, "data.frame")
  expect_true(all(c("file", "line", "severity", "pattern", "code") %in% names(result)))
})

test_that("mysterycall_scan_for_limits - non-existent directory stops", {
  expect_error(
    mysterycall:::mysterycall_scan_for_limits("/no/such/directory"),
    "does not exist"
  )
})

test_that("mysterycall_scan_for_limits - detects slice_head pattern in temp file", {
  tmp <- tempfile(fileext = ".R")
  # Write pipe-style slice_head which matches the regex slice_head\s*(\s*n\s*=\s*[0-9]+
  writeLines("result <- data |> slice_head(n = 100)", tmp)
  on.exit(unlink(tmp))
  result <- suppressWarnings(
    mysterycall:::mysterycall_scan_for_limits(dirname(tmp), exclude_pattern = NULL)
  )
  # Should find at least one CRITICAL hit from the temp file
  relevant <- result[result$file == basename(tmp), ]
  expect_true(nrow(relevant) >= 1L)
  expect_true(any(relevant$severity == "CRITICAL"))
})

test_that("mysterycall_scan_for_limits - exclude_pattern removes matched files", {
  tmp <- tempfile(fileext = "_exclude_me.R")
  writeLines("x <- head(data, 10)", tmp)
  on.exit(unlink(tmp))
  result_with    <- suppressWarnings(mysterycall:::mysterycall_scan_for_limits(dirname(tmp)))
  result_without <- suppressWarnings(
    mysterycall:::mysterycall_scan_for_limits(dirname(tmp), exclude_pattern = "_exclude_me")
  )
  excluded_hits <- result_without[result_without$file == basename(tmp), ]
  expect_equal(nrow(excluded_hits), 0L)
})
