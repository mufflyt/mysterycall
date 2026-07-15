library(testthat)

# Offline tests for the local-file covariate readers in demographic_covariates.R.
# Each builds a tiny fixture (temp CSV or temp DuckDB) so no network, no external
# database, and no /Volumes mount is required.

# ---------------------------------------------------------------------------
# mysterycall_get_cms_enrollment (tidy CSV reader)
# ---------------------------------------------------------------------------

.write_cms_csv <- function(lines) {
  p <- tempfile(fileext = ".csv")
  writeLines(lines, p)
  p
}

test_that("get_cms_enrollment returns the requested county's row", {
  csv <- .write_cms_csv(c(
    "FIPS,County,State,Medicare Enrollment,Medicaid/CHIP Enrollment,Report_Month",
    "48113,Dallas,TX,50000,30000,2024-01",
    "06075,San Francisco,CA,40000,25000,2024-01"
  ))
  res <- mysterycall_get_cms_enrollment(csv, "48113")
  expect_equal(nrow(res), 1L)
  expect_equal(res$County, "Dallas")
  expect_equal(res[["Medicare Enrollment"]], 50000L)
  expect_equal(res[["Medicaid/CHIP Enrollment"]], 30000L)
  expect_named(res, c("FIPS", "County", "State", "Medicare Enrollment",
                      "Medicaid/CHIP Enrollment", "Report_Month"))
})

test_that("get_cms_enrollment matches leading-zero FIPS (read.csv drops the zero)", {
  csv <- .write_cms_csv(c(
    "FIPS,County,State,Medicare Enrollment,Medicaid/CHIP Enrollment,Report_Month",
    "08031,Denver,CO,45000,28000,2024-01",
    "48113,Dallas,TX,50000,30000,2024-01"
  ))
  # "08031" as a string and 8031 as read from the CSV must reconcile.
  res <- mysterycall_get_cms_enrollment(csv, "08031")
  expect_equal(nrow(res), 1L)
  expect_equal(res$County, "Denver")
  expect_equal(res$FIPS, "08031")          # returned zero-padded
})

test_that("get_cms_enrollment errors clearly on a missing required column", {
  csv <- .write_cms_csv(c(
    "FIPS,County,State,Medicare Enrollment,Report_Month",   # no Medicaid/CHIP col
    "48113,Dallas,TX,50000,2024-01"
  ))
  expect_error(
    mysterycall_get_cms_enrollment(csv, "48113"),
    "Medicaid/CHIP Enrollment"
  )
})

test_that("get_cms_enrollment errors on a missing file", {
  expect_error(
    mysterycall_get_cms_enrollment(tempfile(fileext = ".csv"), "48113"),
    "not found"
  )
})

# ---------------------------------------------------------------------------
# mysterycall_get_hrsa_ahrf (preprocessed AHRF DuckDB reader)
# ---------------------------------------------------------------------------

.make_duckdb <- function(tables) {
  skip_if_not_installed("duckdb")
  skip_if_not_installed("DBI")
  p <- tempfile(fileext = ".duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), p)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  for (nm in names(tables)) DBI::dbWriteTable(con, nm, tables[[nm]])
  p
}

test_that("get_hrsa_ahrf reads a preprocessed ahrf_county_data table", {
  ahrf <- data.frame(
    fips              = c("48113", "08031"),
    county_name       = c("Dallas", "Denver"),
    state_abbrev      = c("TX", "CO"),
    pop_total         = c(2600000L, 715000L),
    obgyn_count       = c(400L, 150L),
    medicaid_enrolled = c(600000L, 180000L),
    stringsAsFactors  = FALSE
  )
  db <- .make_duckdb(list(ahrf_county_data = ahrf))
  res <- mysterycall_get_hrsa_ahrf(db, "08031")   # character FIPS w/ leading zero
  expect_equal(nrow(res), 1L)
  expect_equal(res$county_name, "Denver")
  expect_equal(res$obgyn_count, 150L)
})

test_that("get_hrsa_ahrf errors clearly when the table is absent", {
  db <- .make_duckdb(list(some_other_table = data.frame(x = 1L)))
  expect_error(
    mysterycall_get_hrsa_ahrf(db, "08031"),
    "ahrf_county_data"
  )
})

test_that("get_hrsa_ahrf errors clearly when a required column is missing", {
  bad <- data.frame(fips = "48113", county_name = "Dallas", pop_total = 1L)
  db  <- .make_duckdb(list(ahrf_county_data = bad))
  expect_error(
    mysterycall_get_hrsa_ahrf(db, "48113"),
    "missing required column"
  )
})

test_that("get_hrsa_ahrf errors on a missing file", {
  skip_if_not_installed("duckdb")
  expect_error(
    mysterycall_get_hrsa_ahrf(tempfile(fileext = ".duckdb"), "48113"),
    "not found"
  )
})

# ---------------------------------------------------------------------------
# mysterycall_track_clinician_churn (NPPES history DuckDB reader)
# ---------------------------------------------------------------------------

test_that("track_clinician_churn computes joins/exits/churn across years", {
  # One address; year 1 has NPIs {1,2}, year 2 has {2,3} -> 1 joined, 1 left.
  hist <- data.frame(
    year                   = c(2020L, 2020L, 2021L, 2021L),
    npi                    = c("1", "2", "2", "3"),
    first_name             = c("A", "B", "B", "C"),
    last_name              = c("Aa", "Bb", "Bb", "Cc"),
    practice_address_street = rep("123 MAIN ST", 4L),
    practice_address_zip    = rep("80031", 4L),
    stringsAsFactors        = FALSE
  )
  db <- .make_duckdb(list(temporal_obgyn_only_all_years = hist))

  res <- mysterycall_track_clinician_churn(db, "123 Main St", "80031-1234")
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 2L)                       # two years
  y2 <- res[res$Year == 2021L, ]
  expect_equal(y2$Staff_Count, 2L)
  expect_equal(y2$Joined, 1L)                       # NPI 3 joined
  expect_equal(y2$Left, 1L)                         # NPI 1 left
  expect_equal(y2$Churn_Rate, round((1 + 1) / 2, 3))
})

test_that("track_clinician_churn returns NULL when no address matches", {
  hist <- data.frame(
    year = 2020L, npi = "1", first_name = "A", last_name = "Aa",
    practice_address_street = "123 MAIN ST", practice_address_zip = "80031",
    stringsAsFactors = FALSE
  )
  db <- .make_duckdb(list(temporal_obgyn_only_all_years = hist))
  expect_message(
    res <- mysterycall_track_clinician_churn(db, "999 Nowhere Rd", "00000"),
    "No clinicians found"
  )
  expect_null(res)
})

test_that("track_clinician_churn errors on a missing database", {
  expect_error(
    mysterycall_track_clinician_churn(tempfile(fileext = ".duckdb"), "1 A St", "00000"),
    "not found"
  )
})
