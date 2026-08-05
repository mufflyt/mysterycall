library(testthat)

# Boundary Value Analysis: exercise each input domain at its edges and the
# values just inside / just outside them.

.bva_labels <- function(p) {
  out <- character(0)
  for (l in p$layers) {
    lab <- l$aes_params$label
    if (!is.null(lab)) out <- c(out, as.character(lab))
    d <- l$data
    if (is.data.frame(d) && "label" %in% names(d)) out <- c(out, as.character(d$label))
  }
  out
}

FP2 <- c(`2013` = 1e6, `2014` = 1e6)
FP3 <- c(`2013` = 1e6, `2014` = 1e6, `2015` = 1e6)

# ---- conf_level: open interval (0, 1) --------------------------------------
test_that("conf_level exactly at the boundaries 0 and 1 is rejected", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "A", year = c(2013L, 2014L), count = c(5, 6))
  expect_error(mysterycall_subspecialist_trend(counts, population = FP2, conf_level = 0), "conf_level")
  expect_error(mysterycall_subspecialist_trend(counts, population = FP2, conf_level = 1), "conf_level")
})

test_that("conf_level just inside 0 and 1 gives an ordered CI bracketing the rate", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "A", year = c(2013L, 2014L, 2015L),
                       count = c(10, 20, 40))
  for (cl in c(0.001, 0.5, 0.999)) {
    d <- suppressWarnings(
      mysterycall_subspecialist_trend(counts, population = FP3, conf_level = cl))$data
    expect_true(all(d$density_low <= d$density_high), info = paste("cl", cl))
    expect_true(all(d$density_low <= d$density & d$density <= d$density_high),
                info = paste("cl", cl))
  }
})

# ---- count: 0 (minimum) and 1 (smallest positive) --------------------------
test_that("Poisson rate CI at count boundaries 0 and 1", {
  ci0 <- mysterycall:::.poisson_rate_ci(0, 1e5, 1e5, 0.95)
  expect_equal(ci0$lower, 0)                                           # defined as 0
  expect_equal(ci0$upper, stats::qgamma(0.975, shape = 1), tolerance = 1e-8)

  ci1 <- mysterycall:::.poisson_rate_ci(1, 1e5, 1e5, 0.95)
  expect_equal(ci1$lower, stats::qgamma(0.025, shape = 1), tolerance = 1e-8)
  expect_equal(ci1$upper, stats::qgamma(0.975, shape = 2), tolerance = 1e-8)
  expect_gt(ci1$lower, 0)                                              # positive once count >= 1
})

# ---- population: 1 (smallest positive) and 0 (rejected) --------------------
test_that("population boundary: 1 gives density = count * per; 0 is rejected", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "A", year = c(2013L, 2014L), count = c(3, 4))
  p <- suppressWarnings(
    mysterycall_subspecialist_trend(counts, population = c(`2013` = 1, `2014` = 1)))
  expect_equal(p$data$density, c(3, 4) * 1e5)
  expect_error(
    mysterycall_subspecialist_trend(counts, population = c(`2013` = 1, `2014` = 0)),
    "positive")
})

# ---- per: boundary value 1 (density is a raw proportion) -------------------
test_that("per = 1 makes density a raw proportion", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "A", year = c(2013L, 2014L), count = c(1234, 4321))
  pop <- c(`2013` = 2e6, `2014` = 4e6)
  p <- suppressWarnings(mysterycall_subspecialist_trend(counts, population = pop, per = 1))
  expect_equal(p$data$density, c(1234 / 2e6, 4321 / 4e6))
})

# ---- trend_test: number-of-years boundary 1 / 2 / 3 ------------------------
test_that("trend_test across the minimum-years boundary (1, 2, 3)", {
  skip_if_not_installed("ggplot2")
  mk <- function(yrs, cnt) data.frame(subspecialty = "A", year = as.integer(yrs), count = cnt)

  # 1 year: slope undefined -> all-NA row
  tt1 <- attr(suppressWarnings(mysterycall_subspecialist_trend(
    mk(2013, 100), population = c(`2013` = 1e6), trend_test = "poisson")), "trend_test")
  expect_true(is.na(tt1$rr_per_year))
  expect_equal(tt1$n_years, 1L)

  # 2 years: Poisson slope is defined (Wald z)
  tt2 <- attr(suppressWarnings(mysterycall_subspecialist_trend(
    mk(c(2013, 2014), c(100, 110)), population = FP2, trend_test = "poisson")), "trend_test")
  expect_true(is.finite(tt2$rr_per_year))
  expect_equal(tt2$n_years, 2L)

  # 3 years: quasipoisson dispersion becomes estimable (residual df = 1)
  tt3 <- attr(suppressWarnings(mysterycall_subspecialist_trend(
    mk(2013:2015, c(100, 110, 121)), population = FP3, trend_test = "quasipoisson")), "trend_test")
  expect_true(is.finite(tt3$rr_per_year))
  expect_equal(tt3$n_years, 3L)
})

# ---- infographic percent change: zero-baseline and 100% drop boundaries ----
test_that("infographic percent-change edges: start=0, end=0, and just above 0", {
  skip_if_not_installed("ggplot2")
  z <- suppressWarnings(mysterycall_subspecialist_infographic(
    subspecialty = "A", start = 0, end = 5, caption = NA))
  expect_true(any(grepl("n/a", .bva_labels(z), fixed = TRUE)))          # start = 0

  drop <- suppressWarnings(mysterycall_subspecialist_infographic(
    subspecialty = "A", start = 5, end = 0, caption = NA))
  expect_true(any(grepl("-100.0%", .bva_labels(drop), fixed = TRUE)))   # end = 0 -> full drop

  tiny <- suppressWarnings(mysterycall_subspecialist_infographic(
    subspecialty = "A", start = 1e-9, end = 2e-9, caption = NA))
  expect_true(any(grepl("+100.0%", .bva_labels(tiny), fixed = TRUE)))   # just above the boundary
})

# ---- infographic digits: boundary value 0 ----------------------------------
test_that("infographic digits = 0 rounds density values to whole numbers", {
  skip_if_not_installed("ggplot2")
  p <- suppressWarnings(mysterycall_subspecialist_infographic(
    subspecialty = "A", start = 1.44, end = 1.56, digits = 0, caption = NA))
  labs <- .bva_labels(p)
  expect_true(any(labs == "1"))    # start rounded down
  expect_true(any(labs == "2"))    # end rounded up
})

# ---- abbreviation length cap: boundary at 4 --------------------------------
test_that(".abbrev_subspecialty caps derived initials at exactly 4", {
  expect_equal(mysterycall:::.abbrev_subspecialty("Alpha Beta Gamma Delta"), "ABGD")          # 4 words -> 4
  expect_equal(nchar(mysterycall:::.abbrev_subspecialty("Alpha Beta Gamma Delta")), 4L)
  expect_equal(mysterycall:::.abbrev_subspecialty("Alpha Beta Gamma Delta Epsilon"), "ABGD")  # 5 -> capped
})
