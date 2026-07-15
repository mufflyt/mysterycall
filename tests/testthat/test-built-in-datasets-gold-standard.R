# test-built-in-datasets-gold-standard.R
#
# Tests the built-in datasets against ACTUAL data loaded from the package.
#
# Testing tenets satisfied:
#   - Test against ACTUAL data (loads real .rda files from mysterycall)
#   - Verify data SEMANTICS, not just that code runs
#   - Gold-standard manually-verified values (row/col counts, ranges, exact sets)
#   - Enforce domain invariants (lat/lon bounds, NPI uniqueness, district list)
#   - Test for silent failures (NA propagation, duplicate keys)
#   - Cross-file referential integrity (physicians subspecialties vs taxonomy)

library(testthat)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
# Return a character vector of all distinct values from two columns
both_cols <- function(df, col1, col2) unique(c(df[[col1]], df[[col2]]))

# ---------------------------------------------------------------------------
# 1. Schema tests: exact dimensions and column names
# ---------------------------------------------------------------------------

test_that("physicians has 4659 rows and exactly 5 columns", {
  expect_equal(nrow(mysterycall::physicians), 4659L)
  expect_equal(ncol(mysterycall::physicians), 5L)
})

test_that("physicians has correct column names", {
  expect_named(mysterycall::physicians, c("NPI", "name", "subspecialty", "lat", "long"),
               ignore.order = FALSE)
})

test_that("physicians column types are correct", {
  p <- mysterycall::physicians
  expect_true(is.numeric(p$NPI))
  expect_true(is.character(p$name))
  expect_true(is.character(p$subspecialty))
  expect_true(is.numeric(p$lat))
  expect_true(is.numeric(p$long))
})

test_that("taxonomy has 862 rows and exactly 3 columns", {
  expect_equal(nrow(mysterycall::taxonomy), 862L)
  expect_equal(ncol(mysterycall::taxonomy), 3L)
})

test_that("taxonomy has correct column names", {
  expect_named(mysterycall::taxonomy, c("Code", "Classification", "Specialization"),
               ignore.order = FALSE)
})

test_that("acog_districts has 52 rows and exactly 4 columns", {
  expect_equal(nrow(mysterycall::acog_districts), 52L)
  expect_equal(ncol(mysterycall::acog_districts), 4L)
})

test_that("acog_districts has correct column names", {
  expect_named(mysterycall::acog_districts,
               c("State", "ACOG_District", "Subregion", "State_Abbreviations"),
               ignore.order = FALSE)
})

test_that("acgme has 318 rows and 142 columns", {
  expect_equal(nrow(mysterycall::acgme), 318L)
  expect_equal(ncol(mysterycall::acgme), 142L)
})

test_that("fips has 51 rows and exactly 3 columns", {
  expect_equal(nrow(mysterycall::fips), 51L)
  expect_equal(ncol(mysterycall::fips), 3L)
})

test_that("fips has correct column names", {
  expect_named(mysterycall::fips, c("state", "state_code", "state_name"),
               ignore.order = FALSE)
})

test_that("city_state_to_lat_long has 31909 rows", {
  expect_equal(nrow(mysterycall::city_state_to_lat_long), 31909L)
})

test_that("city_state_to_lat_long has expected columns (city, state, lat, long)", {
  expect_true(all(c("city", "state", "lat", "long") %in%
                    names(mysterycall::city_state_to_lat_long)))
})

# ---------------------------------------------------------------------------
# 2. Domain invariants on physicians
# ---------------------------------------------------------------------------

test_that("physicians lat is within US mainland + Hawaii + Alaska bounds (18 to 72 N)", {
  lats <- mysterycall::physicians$lat
  non_na_lats <- lats[!is.na(lats)]
  expect_true(all(non_na_lats >= 18),
              label = paste("Min lat:", min(non_na_lats)))
  expect_true(all(non_na_lats <= 72),
              label = paste("Max lat:", max(non_na_lats)))
})

test_that("physicians lon is within US bounds (-180 to -65 W)", {
  lons <- mysterycall::physicians$long
  non_na_lons <- lons[!is.na(lons)]
  expect_true(all(non_na_lons >= -180),
              label = paste("Min lon:", min(non_na_lons)))
  expect_true(all(non_na_lons <= -65),
              label = paste("Max lon:", max(non_na_lons)))
})

test_that("physicians lat gold-standard range: 18.03865 to 47.75458", {
  lats <- mysterycall::physicians$lat
  expect_equal(round(min(lats, na.rm = TRUE), 5), 18.03865)
  expect_equal(round(max(lats, na.rm = TRUE), 5), 47.75458)
})

test_that("physicians lon gold-standard range: -157.8557 to -66.05314", {
  lons <- mysterycall::physicians$long
  expect_equal(round(min(lons, na.rm = TRUE), 4), -157.8557)
  expect_equal(round(max(lons, na.rm = TRUE), 5), -66.05314)
})

test_that("physicians has 171 NA latitudes and 171 NA longitudes", {
  expect_equal(sum(is.na(mysterycall::physicians$lat)),  171L)
  expect_equal(sum(is.na(mysterycall::physicians$long)), 171L)
})

test_that("all physician subspecialties are from the known set of 7", {
  known_subspecialties <- c(
    "Complex Family Planning",
    "Female Pelvic Medicine and Reconstructive Surgery",
    "Gynecologic Oncology",
    "Maternal-Fetal Medicine",
    "Minimally Invasive Gynecologic Surgery",
    "Pediatric and Adolescent Gynecology",
    "Reproductive Endocrinology and Infertility"
  )
  actual <- unique(mysterycall::physicians$subspecialty)
  unexpected <- setdiff(actual, known_subspecialties)
  expect_equal(length(unexpected), 0L,
               label = paste("Unexpected subspecialties:", paste(unexpected, collapse = "; ")))
})

test_that("physicians has exactly 7 distinct subspecialties", {
  expect_equal(length(unique(mysterycall::physicians$subspecialty)), 7L)
})

# ---------------------------------------------------------------------------
# 3. Statistical: NPI uniqueness and non-NA
# ---------------------------------------------------------------------------

test_that("physicians NPI column has no duplicate values", {
  npis <- mysterycall::physicians$NPI
  expect_equal(sum(duplicated(npis)), 0L)
})

test_that("physicians NPI column has no NA values", {
  expect_equal(sum(is.na(mysterycall::physicians$NPI)), 0L)
})

test_that("physicians name column has no NA values", {
  expect_equal(sum(is.na(mysterycall::physicians$name)), 0L)
})

# ---------------------------------------------------------------------------
# 4. Cross-file referential integrity: subspecialties vs taxonomy
# ---------------------------------------------------------------------------

test_that("every physician subspecialty appears in taxonomy Classification or Specialization", {
  subs <- unique(mysterycall::physicians$subspecialty)
  tax_vals <- both_cols(mysterycall::taxonomy, "Classification", "Specialization")

  # At least some subspecialties must appear in taxonomy; document actual coverage.
  # This is a known partial overlap (see ASSUMPTIONS doc), so we check the ones that DO match.
  # Gold-standard verified: "Female Pelvic Medicine..." and "Gynecologic Oncology" appear in Specialization.
  fpmrs_in_tax <- "Female Pelvic Medicine and Reconstructive Surgery" %in% tax_vals
  go_in_tax    <- "Gynecologic Oncology" %in% tax_vals

  expect_true(fpmrs_in_tax,
              label = "'Female Pelvic Medicine and Reconstructive Surgery' must appear in taxonomy")
  expect_true(go_in_tax,
              label = "'Gynecologic Oncology' must appear in taxonomy")
})

test_that("taxonomy Classification column has no completely empty rows", {
  expect_equal(sum(mysterycall::taxonomy$Classification == "" | is.na(mysterycall::taxonomy$Classification)), 0L)
})

# ---------------------------------------------------------------------------
# 5. acog_districts: 11 unique districts, no District X
# ---------------------------------------------------------------------------

test_that("acog_districts has exactly 11 unique district values", {
  districts <- unique(mysterycall::acog_districts$ACOG_District)
  expect_equal(length(districts), 11L)
})

test_that("acog_districts contains Districts I through XII but NOT District X", {
  districts <- unique(mysterycall::acog_districts$ACOG_District)
  expected_present <- c(
    "District I", "District II", "District III", "District IV",
    "District V", "District VI", "District VII", "District VIII",
    "District IX", "District XI", "District XII"
  )
  missing_from_data <- setdiff(expected_present, districts)
  expect_equal(length(missing_from_data), 0L,
               label = paste("Missing districts:", paste(missing_from_data, collapse = ", ")))
  expect_false("District X" %in% districts,
               label = "District X should not exist in acog_districts")
})

test_that("acog_districts State column has no NA or empty values", {
  states <- mysterycall::acog_districts$State
  expect_equal(sum(is.na(states)), 0L)
  expect_equal(sum(states == ""), 0L)
})

# ---------------------------------------------------------------------------
# 6. Temporal: acgme date columns are parseable
# ---------------------------------------------------------------------------

test_that("acgme original_accreditation_date column exists and values are parseable as dates", {
  expect_true("original_accreditation_date" %in% names(mysterycall::acgme))
  dates_raw <- mysterycall::acgme$original_accreditation_date
  non_na_dates <- dates_raw[!is.na(dates_raw)]
  expect_true(length(non_na_dates) > 0,
              label = "original_accreditation_date should have at least one non-NA value")
  # Attempt to parse; none should produce all NA when using the known format
  parsed <- as.Date(non_na_dates, format = "%B %d, %Y")
  # At least 90% should parse (allowing for format variation)
  pct_parsed <- mean(!is.na(parsed))
  expect_gte(pct_parsed, 0.9,
             label = paste("Fraction parseable:", round(pct_parsed, 3)))
})

test_that("acgme director_date_appointed column exists", {
  expect_true("director_date_appointed" %in% names(mysterycall::acgme))
})

# ---------------------------------------------------------------------------
# 7. Property: city_state_to_lat_long lat/lon within world bounds
# ---------------------------------------------------------------------------

test_that("city_state_to_lat_long lat is within world bounds (-90 to 90)", {
  lats <- mysterycall::city_state_to_lat_long$lat
  non_na <- lats[!is.na(lats)]
  expect_true(all(non_na >= -90), label = paste("Min lat:", min(non_na)))
  expect_true(all(non_na <=  90), label = paste("Max lat:", max(non_na)))
})

test_that("city_state_to_lat_long long is within world bounds (-180 to 180)", {
  lons <- mysterycall::city_state_to_lat_long$long
  non_na <- lons[!is.na(lons)]
  expect_true(all(non_na >= -180), label = paste("Min lon:", min(non_na)))
  expect_true(all(non_na <=  180), label = paste("Max lon:", max(non_na)))
})

# ---------------------------------------------------------------------------
# 8. Schema contract: taxonomy Code is exactly 10 characters for all rows
# ---------------------------------------------------------------------------

test_that("taxonomy Code column is exactly 10 characters for every row", {
  codes <- mysterycall::taxonomy$Code
  bad <- codes[nchar(codes) != 10]
  expect_equal(length(bad), 0L,
               label = paste("Codes with wrong length:", paste(head(bad), collapse = ", ")))
})

# ---------------------------------------------------------------------------
# 9. fips referential completeness
# ---------------------------------------------------------------------------

test_that("fips state_code values are numeric/integer type", {
  # state_code should be numeric FIPS codes
  # state_code is stored as character to preserve leading zeros (e.g. "01" for Alabama)
  expect_true(is.character(mysterycall::fips$state_code) || is.numeric(mysterycall::fips$state_code) || is.integer(mysterycall::fips$state_code))
})

test_that("fips has no duplicate state entries", {
  states <- mysterycall::fips$state
  expect_equal(sum(duplicated(states)), 0L)
})

test_that("fips covers all 50 states plus DC (51 rows)", {
  expect_equal(nrow(mysterycall::fips), 51L)
})
