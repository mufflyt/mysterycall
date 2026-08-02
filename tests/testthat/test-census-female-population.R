library(testthat)

test_that("assembles a year-named vector from per-year ACS totals", {
  skip_if_not_installed("mockery")
  mockery::stub(
    mysterycall_census_female_population, ".census_acs_total",
    function(variable, year, survey, geography) 100000000 + year
  )
  out <- suppressMessages(
    mysterycall_census_female_population(2013:2015, survey = "acs5")
  )
  expect_named(out, c("2013", "2014", "2015"))
  expect_equal(unname(out), c(100002013, 100002014, 100002015))
})

test_that("as = 'data.frame' returns a year/population frame usable as denominator", {
  skip_if_not_installed("mockery")
  mockery::stub(
    mysterycall_census_female_population, ".census_acs_total",
    function(variable, year, survey, geography) 1.6e8
  )
  df <- suppressMessages(
    mysterycall_census_female_population(c(2013, 2018, 2023), survey = "acs5",
                                         as = "data.frame")
  )
  expect_s3_class(df, "data.frame")
  expect_named(df, c("year", "population"))
  expect_equal(df$year, c(2013L, 2018L, 2023L))
})

test_that("2020 handling under acs1 honours fill_2020", {
  skip_if_not_installed("mockery")
  fake <- function(variable, year, survey, geography) {
    # record the survey actually requested for 2020
    if (year == 2020L) return(if (survey == "acs5") 999 else -1)
    year
  }
  mockery::stub(mysterycall_census_female_population, ".census_acs_total", fake)

  # default acs5 substitution
  v_fill <- suppressMessages(
    mysterycall_census_female_population(2019:2021, survey = "acs1")
  )
  expect_equal(unname(v_fill[["2020"]]), 999)

  # skip -> NA for 2020
  v_skip <- suppressMessages(
    mysterycall_census_female_population(2019:2021, survey = "acs1",
                                         fill_2020 = "skip")
  )
  expect_true(is.na(v_skip[["2020"]]))

  # error -> stop
  expect_error(
    suppressMessages(mysterycall_census_female_population(
      2020, survey = "acs1", fill_2020 = "error")),
    "not released"
  )
})

test_that("invalid years are rejected", {
  expect_error(
    mysterycall_census_female_population(years = c("a", "b")),
    "coercible to integers"
  )
})
