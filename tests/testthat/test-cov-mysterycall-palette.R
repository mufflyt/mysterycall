library(testthat)
library(mysterycall)

# ---------------------------------------------------------------------------
# Tests for mysterycall_standard_labels()
# ---------------------------------------------------------------------------

test_that("mysterycall_standard_labels returns a named list with expected keys", {
  labels <- suppressMessages(suppressWarnings(mysterycall_standard_labels()))

  expect_type(labels, "list")

  expected_keys <- c("npi", "state", "city", "call_outcome",
                     "quality", "call_time", "hold_time", "eta")
  expect_named(labels, expected_keys, ignore.order = TRUE)
})

test_that("mysterycall_standard_labels values are non-empty character scalars", {
  labels <- suppressMessages(suppressWarnings(mysterycall_standard_labels()))

  for (key in names(labels)) {
    expect_type(labels[[key]], "character")
    expect_length(labels[[key]], 1L)
    expect_true(nchar(labels[[key]]) > 0L,
                info = paste("label for", key, "should be non-empty"))
  }

  # Spot-check a few specific values
  expect_equal(labels[["npi"]], "National Provider Identifier")
  expect_equal(labels[["state"]], "State")
  expect_equal(labels[["call_time"]], "Call Duration (minutes)")
})

# ---------------------------------------------------------------------------
# Tests for mysterycall_standard_palette()
# ---------------------------------------------------------------------------

test_that("mysterycall_standard_palette returns correct hex vectors for each name", {
  primary    <- suppressMessages(suppressWarnings(mysterycall_standard_palette("primary")))
  sequential <- suppressMessages(suppressWarnings(mysterycall_standard_palette("sequential")))
  diverging  <- suppressMessages(suppressWarnings(mysterycall_standard_palette("diverging")))

  # Return type
  expect_type(primary,    "character")
  expect_type(sequential, "character")
  expect_type(diverging,  "character")

  # Expected lengths
  expect_length(primary,    4L)
  expect_length(sequential, 4L)
  expect_length(diverging,  3L)

  # All values should look like hex color codes
  hex_pattern <- "^#[0-9A-Fa-f]{6}$"
  expect_true(all(grepl(hex_pattern, primary)),    info = "primary colors are hex")
  expect_true(all(grepl(hex_pattern, sequential)), info = "sequential colors are hex")
  expect_true(all(grepl(hex_pattern, diverging)),  info = "diverging colors are hex")
})

test_that("mysterycall_standard_palette default argument resolves to 'primary'", {
  default_pal <- suppressMessages(suppressWarnings(mysterycall_standard_palette()))
  primary_pal <- suppressMessages(suppressWarnings(mysterycall_standard_palette("primary")))

  expect_identical(default_pal, primary_pal)
})

test_that("mysterycall_standard_palette errors on an unrecognized palette name", {
  expect_error(
    suppressMessages(suppressWarnings(mysterycall_standard_palette("rainbow"))),
    regexp = "arg"   # match.arg produces "argument ... should be one of ..."
  )

  expect_error(
    suppressMessages(suppressWarnings(mysterycall_standard_palette(""))),
    regexp = "arg"
  )

  expect_error(
    suppressMessages(suppressWarnings(mysterycall_standard_palette(NA_character_))),
    regexp = NULL   # any error is acceptable for NA input
  )
})
