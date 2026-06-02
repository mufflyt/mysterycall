# ---- shared fixture ----------------------------------------------------------

make_state_data <- function() {
  data.frame(
    state = c("Colorado", "California", "Texas", "New York", "Florida",
              "Washington", "Oregon", "Arizona"),
    rate  = c(0.55, 0.72, 0.48, 0.63, 0.81, 0.50, 0.67, 0.44),
    stringsAsFactors = FALSE
  )
}

make_abb_data <- function() {
  data.frame(
    st   = c("CO", "CA", "TX", "NY", "FL"),
    rate = c(0.55, 0.72, 0.48, 0.63, 0.81),
    stringsAsFactors = FALSE
  )
}

# ---- tests -------------------------------------------------------------------

test_that("map_acceptance_rate: returns a ggplot object", {
  skip_if_not_installed("ggplot2")
  df <- make_state_data()
  p  <- mysterycall_map_acceptance_rate(df, region_col = "state",
                                         rate_col   = "rate")
  expect_s3_class(p, "ggplot")
})

test_that("map_acceptance_rate: works with full state names", {
  skip_if_not_installed("ggplot2")
  df <- make_state_data()
  expect_no_error(
    mysterycall_map_acceptance_rate(df, region_col = "state", rate_col = "rate")
  )
})

test_that("map_acceptance_rate: works with 2-letter state abbreviations", {
  skip_if_not_installed("ggplot2")
  df <- make_abb_data()
  p  <- mysterycall_map_acceptance_rate(df, region_col = "st", rate_col = "rate")
  expect_s3_class(p, "ggplot")
})

test_that("map_acceptance_rate: save_path writes a file", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("mapproj")
  df   <- make_state_data()
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))
  mysterycall_map_acceptance_rate(df, region_col = "state", rate_col = "rate",
                                   save_path = path)
  expect_true(file.exists(path))
})

test_that("map_acceptance_rate: region_type = 'hrr' errors", {
  df <- make_state_data()
  expect_error(
    mysterycall_map_acceptance_rate(df, region_col = "state", rate_col = "rate",
                                     region_type = "hrr"),
    "HRR maps require an sf object"
  )
})

test_that("map_acceptance_rate: errors on missing region column", {
  skip_if_not_installed("ggplot2")
  df <- make_state_data()
  expect_error(
    mysterycall_map_acceptance_rate(df, region_col = "no_such_col",
                                     rate_col = "rate"),
    "not found"
  )
})

test_that("map_acceptance_rate: errors on missing rate column", {
  skip_if_not_installed("ggplot2")
  df <- make_state_data()
  expect_error(
    mysterycall_map_acceptance_rate(df, region_col = "state",
                                     rate_col = "bad_col"),
    "not found"
  )
})
