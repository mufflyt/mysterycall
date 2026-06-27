# tests/testthat/test-geographic-map.R
# testthat 3rd edition tests for mysterycall_geographic_map()

# Helper: data frame with enough obs per state to stay above default
# low_states_warn = 5.  Seven states, 10 obs each = 70 rows total.
make_geo_df <- function(n = 70) {
  states  <- rep(c("CO", "CA", "TX", "NY", "FL", "WA", "OR"), length.out = n)
  offered <- rep(c(1L, 0L, 1L, 0L, 1L, 1L, 0L),             length.out = n)
  data.frame(state = states, offered = offered, stringsAsFactors = FALSE)
}

# ---------------------------------------------------------------------------
# 1. Returns gg / ggplot object
# ---------------------------------------------------------------------------
test_that("returns object of class gg and ggplot", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("maps")

  p <- mysterycall_geographic_map(make_geo_df(), low_states_warn = 1L)
  expect_s3_class(p, "gg")
  expect_s3_class(p, "ggplot")
})

# ---------------------------------------------------------------------------
# 2. Return value is invisible
# ---------------------------------------------------------------------------
test_that("return value is invisible", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("maps")

  expect_invisible(mysterycall_geographic_map(make_geo_df(), low_states_warn = 1L))
})

# ---------------------------------------------------------------------------
# 3. Works with state abbreviations CO, CA, TX
# ---------------------------------------------------------------------------
test_that("accepts two-letter state abbreviations without error", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("maps")

  df <- data.frame(
    state   = rep(c("CO", "CA", "TX"), each = 10),
    offered = rep(c(1L, 0L), times = 15),
    stringsAsFactors = FALSE
  )
  p <- mysterycall_geographic_map(df, low_states_warn = 1L)
  expect_s3_class(p, "ggplot")
})

# ---------------------------------------------------------------------------
# 4. Binary outcome (0 / 1) aggregated to per-state rate in [0, 1]
# ---------------------------------------------------------------------------
test_that("binary outcome is aggregated to per-state acceptance rate", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("maps")

  df <- data.frame(
    state   = rep(c("CO", "CA", "TX"), each = 20),
    offered = c(
      rep(1L, 14), rep(0L, 6),   # CO rate = 0.70
      rep(1L, 10), rep(0L, 10),  # CA rate = 0.50
      rep(1L, 16), rep(0L, 4)    # TX rate = 0.80
    ),
    stringsAsFactors = FALSE
  )
  p <- mysterycall_geographic_map(df, low_states_warn = 1L)
  expect_s3_class(p, "ggplot")

  # The merged polygon data stored in the plot should have rate values in [0,1].
  rate_vals <- p$data$rate[!is.na(p$data$rate)]
  expect_true(all(rate_vals >= 0 & rate_vals <= 1))
})

# ---------------------------------------------------------------------------
# 5. Rate outcome (0-1 values, already aggregated) works directly
# ---------------------------------------------------------------------------
test_that("pre-aggregated rate outcome (0-1 numeric) works without error", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("maps")

  df <- data.frame(
    state = rep(c("CO", "CA", "TX"), each = 6),
    rate  = c(rep(0.65, 6), rep(0.50, 6), rep(0.80, 6)),
    stringsAsFactors = FALSE
  )
  p <- mysterycall_geographic_map(df, outcome_col = "rate", low_states_warn = 1L)
  expect_s3_class(p, "ggplot")
})

# ---------------------------------------------------------------------------
# 6. Warning when a state has fewer than low_states_warn observations
# ---------------------------------------------------------------------------
test_that("warns when a state has fewer observations than low_states_warn", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("maps")

  df <- data.frame(
    state   = c(rep("CO", 10), rep("CA", 2)),  # CA has only 2 obs
    offered = c(rep(1L, 5), rep(0L, 5), 1L, 0L),
    stringsAsFactors = FALSE
  )
  expect_warning(
    mysterycall_geographic_map(df, low_states_warn = 5L),
    regexp = "fewer than 5"
  )
})

# ---------------------------------------------------------------------------
# 7. Error when state_col is not present in data
# ---------------------------------------------------------------------------
test_that("errors when state_col is absent from data", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("maps")

  df <- data.frame(region = c("CO", "CA"), offered = c(1L, 0L),
                   stringsAsFactors = FALSE)
  expect_error(
    mysterycall_geographic_map(df, state_col = "state"),
    regexp = "not found"
  )
})

# ---------------------------------------------------------------------------
# 8. Error when outcome_col is not present in data
# ---------------------------------------------------------------------------
test_that("errors when outcome_col is absent from data", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("maps")

  df <- data.frame(state = c("CO", "CA"), result = c(1L, 0L),
                   stringsAsFactors = FALSE)
  expect_error(
    mysterycall_geographic_map(df, outcome_col = "offered"),
    regexp = "not found"
  )
})

# ---------------------------------------------------------------------------
# 9. Error when palette is not one of the valid viridis options
# ---------------------------------------------------------------------------
test_that("errors when palette is not a valid viridis option", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("maps")

  expect_error(
    mysterycall_geographic_map(make_geo_df(), palette = "rainbow"),
    regexp = "should be one of"
  )
})

# ---------------------------------------------------------------------------
# 10. Error when direction is not 1 or -1
# ---------------------------------------------------------------------------
test_that("errors when direction is not 1 or -1", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("maps")

  expect_error(
    mysterycall_geographic_map(make_geo_df(), direction = 0L),
    regexp = "direction"
  )
})

# ---------------------------------------------------------------------------
# 11. na_color is wired into the fill scale's na.value
# ---------------------------------------------------------------------------
test_that("na_color is applied to the fill scale na.value for missing states", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("maps")

  custom_na <- "#ABCDEF"
  p <- mysterycall_geographic_map(
    make_geo_df(),
    na_color        = custom_na,
    low_states_warn = 1L
  )

  fill_scales <- Filter(
    function(s) "fill" %in% s$aesthetics,
    p$scales$scales
  )
  expect_length(fill_scales, 1L)
  expect_equal(fill_scales[[1]]$na.value, custom_na)
})

# ---------------------------------------------------------------------------
# 12. title and subtitle propagate to plot labels
# ---------------------------------------------------------------------------
test_that("title and subtitle appear in the plot labels", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("maps")

  p <- mysterycall_geographic_map(
    make_geo_df(),
    title           = "Test Map Title",
    subtitle        = "Test Subtitle",
    low_states_warn = 1L
  )
  expect_equal(p$labels$title,    "Test Map Title")
  expect_equal(p$labels$subtitle, "Test Subtitle")
})
