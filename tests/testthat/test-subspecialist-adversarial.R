library(testthat)

# Adversarial tests: hostile / degenerate inputs that should either be handled
# gracefully or rejected with a clear error — never a silent wrong answer.

FP3 <- c(`2013` = 1e6, `2014` = 1e6, `2015` = 1e6)

# ---- trend: degenerate but valid inputs ------------------------------------
test_that("trend tolerates an all-zero-count series (density 0, CI lower 0)", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "Z", year = c(2013L, 2014L, 2015L),
                       count = c(0, 0, 0))
  p <- suppressWarnings(mysterycall_subspecialist_trend(counts, population = FP3,
                                                        conf_level = 0.95))
  expect_true(all(p$data$density == 0))
  expect_true(all(p$data$density_low == 0))
  expect_true(all(p$data$density_high >= 0))
})

test_that("trend tolerates non-integer counts", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "A", year = c(2013L, 2014L, 2015L),
                       count = c(10.5, 12.25, 14.0))
  p <- suppressWarnings(mysterycall_subspecialist_trend(counts, population = FP3,
                                                        trend_test = "poisson"))
  expect_s3_class(p, "ggplot")
  expect_equal(p$data$density[p$data$year == 2013], 10.5 / 1e6 * 1e5)
})

test_that("trend accepts a population superset (extra years ignored)", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "A", year = c(2013L, 2014L), count = c(5, 6))
  pop <- c(`2011` = 9e5, `2013` = 1e6, `2014` = 1e6, `2020` = 1.1e6)
  p <- suppressWarnings(mysterycall_subspecialist_trend(counts, population = pop))
  expect_equal(nrow(p$data), 2L)
  expect_equal(p$data$population, c(1e6, 1e6))
})

test_that("trend keeps duplicate subspecialty-year rows without error", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = rep("A", 4),
                       year = c(2013L, 2013L, 2014L, 2014L),
                       count = c(5, 7, 6, 8))
  p <- suppressWarnings(mysterycall_subspecialist_trend(counts, population = FP3))
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(p$data), 4L)
})

test_that("trend: a single-year subspecialty yields an NA trend-test row", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "Solo", year = 2013L, count = 100)
  p <- suppressWarnings(mysterycall_subspecialist_trend(
    counts, population = c(`2013` = 1e6), trend_test = "quasipoisson",
    conf_level = 0.9))
  tt <- attr(p, "trend_test")
  expect_true(is.na(tt$rr_per_year))
  expect_equal(tt$n_years, 1L)
})

# ---- trend: inputs that must be rejected ------------------------------------
test_that("trend errors when a needed denominator year is missing", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "A", year = c(2013L, 2099L), count = c(5, 6))
  expect_error(
    mysterycall_subspecialist_trend(counts, population = FP3),
    "missing denominators"
  )
})

test_that("trend rejects non-positive population and negative counts", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "A", year = c(2013L, 2014L), count = c(5, 6))
  expect_error(
    mysterycall_subspecialist_trend(counts, population = c(`2013` = 1e6, `2014` = 0)),
    "positive"
  )
  bad <- data.frame(subspecialty = "A", year = c(2013L, 2014L), count = c(-1, 6))
  expect_error(mysterycall_subspecialist_trend(bad, population = FP3), "non-negative")
})

test_that("trend rejects an out-of-range conf_level", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "A", year = c(2013L, 2014L), count = c(5, 6))
  expect_error(
    mysterycall_subspecialist_trend(counts, population = FP3, conf_level = 0),
    "conf_level"
  )
  expect_error(
    mysterycall_subspecialist_trend(counts, population = FP3, conf_level = 1.5),
    "conf_level"
  )
})

# ---- infographic: hostile inputs -------------------------------------------
test_that("infographic renders with NA density (marks it, does not crash)", {
  skip_if_not_installed("ggplot2")
  p <- suppressWarnings(mysterycall_subspecialist_infographic(
    subspecialty = c("A", "B"), start = c(NA, 1), end = c(2, 3), caption = NA))
  expect_s3_class(p, "ggplot")
})

test_that("infographic handles one and many subspecialties", {
  skip_if_not_installed("ggplot2")
  expect_s3_class(
    suppressWarnings(mysterycall_subspecialist_infographic(
      subspecialty = "Only", start = 1, end = 2, caption = NA)),
    "ggplot")
  n <- 8L
  expect_s3_class(
    suppressWarnings(mysterycall_subspecialist_infographic(
      subspecialty = paste0("S", seq_len(n)),
      start = seq_len(n), end = seq_len(n) + 1, caption = NA)),
    "ggplot")
})

test_that("infographic rejects length-mismatched and negative inputs", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_subspecialist_infographic(subspecialty = c("A", "B"),
                                          start = c(1, 2), end = 3),
    "same length")
  expect_error(
    mysterycall_subspecialist_infographic(subspecialty = "A", start = -1, end = 2),
    "non-negative")
})

test_that(".abbrev_subspecialty survives empty, letterless, and long names", {
  expect_equal(mysterycall:::.abbrev_subspecialty(""), "")
  expect_equal(mysterycall:::.abbrev_subspecialty("123 !!!"), "")
  expect_equal(mysterycall:::.abbrev_subspecialty("A B C D E F"), "ABCD")  # capped at 4
})

# ---- census fetcher: adversarial (mocked, no network) ----------------------
test_that("census fetch preserves input year order and names", {
  skip_if_not_installed("mockery")
  mockery::stub(mysterycall_census_female_population, ".census_acs_total",
                function(variable, year, survey, geography) year * 10)
  out <- suppressMessages(
    mysterycall_census_female_population(c(2015, 2013, 2014), survey = "acs5"))
  expect_named(out, c("2015", "2013", "2014"))        # order preserved, not sorted
  expect_equal(unname(out), c(20150, 20130, 20140))
})

test_that("census fetch wraps a backend error with the offending year", {
  skip_if_not_installed("mockery")
  mockery::stub(mysterycall_census_female_population, ".census_acs_total",
                function(variable, year, survey, geography) stop("backend down"))
  expect_error(
    suppressMessages(mysterycall_census_female_population(2013, survey = "acs5")),
    "Census fetch for 2013"
  )
})

# ---- provenance: prints/captions safely with only required fields ----------
test_that("provenance prints and captions with all-optional fields absent", {
  prov <- mysterycall:::.build_provenance(
    metric = "m", computation = "c", numerator_desc = "num", denominator_desc = "den",
    generated_by = "g")
  expect_output(print(prov), "figure provenance")
  cap <- mysterycall:::.provenance_caption(prov)
  expect_match(cap, "^Source")
  expect_match(cap, "num")
  expect_match(cap, "den")
})
