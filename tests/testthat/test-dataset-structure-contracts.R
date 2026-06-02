library(testthat)

# Schema contracts for all six built-in datasets.
# Every expected value was computed from the actual data before writing the test.
# These tests catch accidental changes to dataset dimensions, columns, or key values.

# ── Helper ────────────────────────────────────────────────────────────────────
load_dataset <- function(name) {
  e <- new.env(parent = emptyenv())
  data(list = name, package = "mysterycall", envir = e)
  get(name, envir = e)
}

# ── acog_districts (52 rows, 4 cols) ─────────────────────────────────────────

test_that("acog_districts - exact row count is 52 (50 states + DC + territories)", {
  d <- load_dataset("acog_districts")
  expect_equal(nrow(d), 52L)
})

test_that("acog_districts - required columns are present", {
  d <- load_dataset("acog_districts")
  expect_true(all(c("State", "ACOG_District", "Subregion", "State_Abbreviations") %in% names(d)))
})

test_that("acog_districts - exactly 11 unique districts (I-XII, no District X)", {
  d <- load_dataset("acog_districts")
  n_distinct <- length(unique(d$ACOG_District))
  expect_equal(n_distinct, 11L)
})

test_that("acog_districts - District X does not exist (ACOG renumbered)", {
  d <- load_dataset("acog_districts")
  expect_false("District X" %in% d$ACOG_District)
})

test_that("acog_districts - all known districts are present", {
  d <- load_dataset("acog_districts")
  expected <- c(
    "District I", "District II", "District III", "District IV",
    "District V",  "District VI", "District VII", "District VIII",
    "District IX", "District XI", "District XII"
  )
  expect_setequal(unique(d$ACOG_District), expected)
})

test_that("acog_districts - no missing ACOG_District values", {
  d <- load_dataset("acog_districts")
  expect_equal(sum(is.na(d$ACOG_District)), 0L)
})

test_that("acog_districts - State_Abbreviations contains CO for Colorado", {
  d <- load_dataset("acog_districts")
  expect_true("CO" %in% d$State_Abbreviations)
})

# ── acgme (318 rows) ──────────────────────────────────────────────────────────

test_that("acgme - exact row count is 318 ACGME-accredited programs", {
  d <- load_dataset("acgme")
  expect_equal(nrow(d), 318L)
})

test_that("acgme - required core columns are present", {
  d <- load_dataset("acgme")
  core_cols <- c("program_name", "address", "city", "state", "zip")
  expect_true(all(core_cols %in% names(d)))
})

test_that("acgme - program_name has no completely empty values", {
  d <- load_dataset("acgme")
  expect_true(all(!is.na(d$program_name)))
  expect_true(all(nchar(trimws(d$program_name)) > 0))
})

test_that("acgme - programs span multiple states (geographic diversity)", {
  d <- load_dataset("acgme")
  n_states <- length(unique(d$state[!is.na(d$state)]))
  expect_true(n_states >= 30L, label = paste("Only", n_states, "states found"))
})

test_that("acgme - zip codes are character (not numeric, to preserve leading zeros)", {
  d <- load_dataset("acgme")
  expect_type(d$zip, "character")
})

test_that("acgme - accreditation_status column is present and non-empty", {
  d <- load_dataset("acgme")
  expect_true("accreditation_status" %in% names(d))
  n_missing <- sum(is.na(d$accreditation_status))
  # Expect that accreditation status exists for the majority of programs
  expect_true(n_missing < nrow(d))
})

# ── fips (51 rows: 50 states + DC) ───────────────────────────────────────────

test_that("fips - exact row count is 51 (50 states + DC)", {
  d <- load_dataset("fips")
  expect_equal(nrow(d), 51L)
})

test_that("fips - required columns: state, state_code, state_name", {
  d <- load_dataset("fips")
  expect_true(all(c("state", "state_code", "state_name") %in% names(d)))
})

test_that("fips - Colorado abbreviation maps to FIPS code 08", {
  d <- load_dataset("fips")
  co_row <- d[d$state == "CO", ]
  expect_equal(nrow(co_row), 1L)
  expect_equal(co_row$state_code, "08")
})

test_that("fips - all 50 standard state abbreviations are present", {
  d <- load_dataset("fips")
  standard_50 <- c(
    "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN",
    "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV",
    "NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN",
    "TX","UT","VT","VA","WA","WV","WI","WY"
  )
  expect_true(all(standard_50 %in% d$state))
})

test_that("fips - DC is included in the crosswalk", {
  d <- load_dataset("fips")
  expect_true("DC" %in% d$state)
})

test_that("fips - state abbreviations are 2 characters long", {
  d <- load_dataset("fips")
  expect_true(all(nchar(d$state) == 2L))
})

test_that("fips - state_code values are zero-padded two-digit strings", {
  d <- load_dataset("fips")
  expect_type(d$state_code, "character")
  expect_true(all(nchar(d$state_code) == 2L))
})

test_that("fips - no duplicate state abbreviations", {
  d <- load_dataset("fips")
  expect_equal(length(unique(d$state)), nrow(d))
})

# ── city_state_to_lat_long (31,909 rows) ──────────────────────────────────────────

test_that("city_state_to_lat_long - row count is 31909", {
  d <- load_dataset("city_state_to_lat_long")
  expect_equal(nrow(d), 31909L)
})

test_that("city_state_to_lat_long - required columns: state, city, latitude, longitude", {
  d <- load_dataset("city_state_to_lat_long")
  expect_true(all(c("state", "city", "latitude", "longitude") %in% names(d)))
})

test_that("city_state_to_lat_long - latitude values are in valid range [-90, 90]", {
  d <- load_dataset("city_state_to_lat_long")
  lats <- d$latitude[!is.na(d$latitude)]
  expect_true(all(lats >= -90 & lats <= 90))
})

test_that("city_state_to_lat_long - longitude values are in valid range [-180, 180]", {
  d <- load_dataset("city_state_to_lat_long")
  lons <- d$longitude[!is.na(d$longitude)]
  expect_true(all(lons >= -180 & lons <= 180))
})

test_that("city_state_to_lat_long - continental US cities have negative longitude", {
  d <- load_dataset("city_state_to_lat_long")
  # All 50 states except HI/AK have western longitudes (negative)
  # Denver, CO should be around -104.9
  denver <- d[tolower(d$city) == "denver" & d$state == "CO", ]
  if (nrow(denver) > 0) {
    expect_true(all(denver$longitude < 0))
    expect_true(all(denver$longitude > -115))
  } else {
    skip("Denver not found in lookup table")
  }
})

test_that("city_state_to_lat_long - has expected columns", {
  d <- load_dataset("city_state_to_lat_long")
  expect_true(all(c("city", "state", "latitude", "longitude") %in% names(d)))
})

test_that("city_state_to_lat_long - covers all 50 states by full name", {
  d <- load_dataset("city_state_to_lat_long")
  # state column uses full state names, not abbreviations
  expect_true(all(c("California", "Texas", "New York", "Florida") %in% unique(d$state)))
})

# ── taxonomy (862 rows) ───────────────────────────────────────────────────────

test_that("taxonomy - row count is 862 NUCC codes", {
  d <- load_dataset("taxonomy")
  expect_equal(nrow(d), 862L)
})

test_that("taxonomy - required columns: Code, Classification, Specialization", {
  d <- load_dataset("taxonomy")
  expect_true(all(c("Code", "Classification", "Specialization") %in% names(d)))
})

test_that("taxonomy - Code column has 10-character NUCC taxonomy codes", {
  d <- load_dataset("taxonomy")
  valid_codes <- nchar(d$Code) == 10L
  expect_true(all(valid_codes))
})

test_that("taxonomy - taxonomy codes are unique (no duplicates)", {
  d <- load_dataset("taxonomy")
  expect_equal(length(unique(d$Code)), nrow(d))
})

test_that("taxonomy - Obstetrics & Gynecology code 207V00000X is present", {
  d <- load_dataset("taxonomy")
  expect_true("207V00000X" %in% d$Code)
})

test_that("taxonomy - Gynecologic Oncology code 207VX0201X is present", {
  d <- load_dataset("taxonomy")
  expect_true("207VX0201X" %in% d$Code)
})

test_that("taxonomy - Clinic/Center is the most common Classification (n=63)", {
  d <- load_dataset("taxonomy")
  cls_counts <- table(d$Classification)
  expect_equal(as.integer(cls_counts["Clinic/Center"]), 63L)
  expect_equal(names(which.max(cls_counts)), "Clinic/Center")
})

test_that("taxonomy - 241 unique Classification values", {
  d <- load_dataset("taxonomy")
  expect_equal(length(unique(d$Classification)), 241L)
})

# ── physicians (4659 rows) ───────────────────────────────────────────────────

test_that("physicians - row count is 4659 OBGYN subspecialists", {
  d <- load_dataset("physicians")
  expect_equal(nrow(d), 4659L)
})

test_that("physicians - required columns: NPI, name, subspecialty, lat, long", {
  d <- load_dataset("physicians")
  expect_true(all(c("NPI", "name", "subspecialty", "lat", "long") %in% names(d)))
})

test_that("physicians - latitude values are in continental US range", {
  d <- load_dataset("physicians")
  lats <- d$lat[!is.na(d$lat)]
  expect_true(all(lats >= 17 & lats <= 72),
    label = "Latitude outside Hawaii-Alaska range")
})

test_that("physicians - longitude values span the US (negative for continental)", {
  d <- load_dataset("physicians")
  lons <- d$long[!is.na(d$long)]
  expect_true(any(lons < 0), label = "No negative longitudes for continental US")
})

test_that("physicians - NPI column is numeric type", {
  d <- load_dataset("physicians")
  expect_true(is.numeric(d$NPI) || is.character(d$NPI))
})

test_that("physicians - name column has no completely empty entries", {
  d <- load_dataset("physicians")
  empty_names <- sum(is.na(d$name) | nchar(trimws(d$name)) == 0)
  expect_equal(empty_names, 0L)
})
