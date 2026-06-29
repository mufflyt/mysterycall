library(testthat)
library(mysterycall)

# ---------------------------------------------------------------------------
# Tests for the acog_districts dataset
# ---------------------------------------------------------------------------

test_that("acog_districts dataset loads and has expected structure", {
  suppressMessages(suppressWarnings(data(acog_districts, package = "mysterycall")))

  expect_true(exists("acog_districts"))
  expect_s3_class(acog_districts, "data.frame")

  # Exact column names required by the documentation
  expect_named(
    acog_districts,
    c("State", "ACOG_District", "Subregion", "State_Abbreviations"),
    ignore.order = FALSE
  )

  # Dataset should have 52 rows (50 states + DC + one territory)
  expect_gte(nrow(acog_districts), 50L)
})

test_that("acog_districts contains valid US state abbreviations", {
  suppressMessages(suppressWarnings(data(acog_districts, package = "mysterycall")))

  abbrs <- acog_districts$State_Abbreviations

  # Every abbreviation must be exactly two upper-case letters
  expect_true(
    all(grepl("^[A-Z]{2}$", abbrs)),
    info = paste("Non-conforming abbreviations:", paste(abbrs[!grepl("^[A-Z]{2}$", abbrs)], collapse = ", "))
  )

  # No NAs in State_Abbreviations
  expect_false(anyNA(abbrs))
})

test_that("acog_districts has no NAs in required columns", {
  suppressMessages(suppressWarnings(data(acog_districts, package = "mysterycall")))

  expect_false(anyNA(acog_districts$State))
  expect_false(anyNA(acog_districts$ACOG_District))
  expect_false(anyNA(acog_districts$State_Abbreviations))
})

test_that("ACOG_District values follow the expected 'District X' pattern", {
  suppressMessages(suppressWarnings(data(acog_districts, package = "mysterycall")))

  districts <- acog_districts$ACOG_District
  # Every value must start with "District"
  expect_true(
    all(grepl("^District", districts)),
    info = paste("Unexpected district values:", paste(unique(districts[!grepl("^District", districts)]), collapse = ", "))
  )

  # There should be multiple distinct districts
  expect_gte(length(unique(districts)), 5L)
})

# ---------------------------------------------------------------------------
# Tests for mysterycall_map_acog_districts()
# ---------------------------------------------------------------------------

test_that("mysterycall_map_acog_districts() errors when given a non-existent file path", {
  skip("mysterycall_map_acog_districts moved to mysterymaps package")
})

test_that("mysterycall_map_acog_districts() errors when sf is unavailable (mocked)", {
  # If sf is not installed, the function should error with an informative message
  skip_if(requireNamespace("sf", quietly = TRUE), "sf is installed; skip unavailability test")

  expect_error(
    suppressMessages(suppressWarnings(mysterycall_map_acog_districts())),
    regexp = "sf"
  )
})

test_that("mysterycall_map_acog_districts() returns an sf object with expected columns", {
  skip("mysterycall_map_acog_districts moved to mysterymaps package")
})
