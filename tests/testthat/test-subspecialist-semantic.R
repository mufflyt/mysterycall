library(testthat)

# Semantic tests: assert the actual numbers the density functions compute, not
# just their structure. Values are checked against closed-form ground truth.

# Collect drawn text from a ggplot: annotate() stores `label` in aes_params,
# geom_text() in the layer data — check both.
.sem_labels <- function(p) {
  out <- character(0)
  for (l in p$layers) {
    lab <- l$aes_params$label
    if (!is.null(lab)) out <- c(out, as.character(lab))
    d <- l$data
    if (is.data.frame(d) && "label" %in% names(d)) out <- c(out, as.character(d$label))
  }
  out
}

# ---- density == count / population * per, exactly --------------------------
test_that("trend density equals count / population * per, to the digit", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "A", year = c(2013L, 2023L),
                       count = c(1234, 4321))
  pop <- c(`2013` = 2e6, `2023` = 4e6)
  p <- suppressWarnings(mysterycall_subspecialist_trend(counts, population = pop))
  d <- p$data
  expect_equal(d$density[d$year == 2013], 1234 / 2e6 * 1e5)   # 61.7
  expect_equal(d$density[d$year == 2023], 4321 / 4e6 * 1e5)   # 108.025
  # every row satisfies the identity
  expect_equal(d$density, d$count / d$population * 1e5)
})

test_that("density scales linearly with `per`", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "A", year = c(2013L, 2014L), count = c(100, 200))
  pop <- c(`2013` = 1e6, `2014` = 1e6)
  p5 <- suppressWarnings(mysterycall_subspecialist_trend(counts, population = pop, per = 1e5))
  p3 <- suppressWarnings(mysterycall_subspecialist_trend(counts, population = pop, per = 1e3))
  expect_equal(p5$data$density, p3$data$density * 100)
})

# ---- exact Garwood Poisson confidence limits -------------------------------
test_that("Poisson rate CI matches the exact Garwood/gamma limits", {
  # per == population, so rate limits equal count limits
  ci5 <- mysterycall:::.poisson_rate_ci(5, 1e5, 1e5, 0.95)
  expect_equal(ci5$lower, stats::qgamma(0.025, shape = 5), tolerance = 1e-8)
  expect_equal(ci5$upper, stats::qgamma(0.975, shape = 6), tolerance = 1e-8)

  ci0 <- mysterycall:::.poisson_rate_ci(0, 1e5, 1e5, 0.95)
  expect_equal(ci0$lower, 0)                                             # defined as 0
  expect_equal(ci0$upper, stats::qgamma(0.975, shape = 1), tolerance = 1e-8)

  # 90% interval is strictly inside the 95% interval
  a95 <- mysterycall:::.poisson_rate_ci(20, 1e5, 1e5, 0.95)
  a90 <- mysterycall:::.poisson_rate_ci(20, 1e5, 1e5, 0.90)
  expect_gt(a90$lower, a95$lower)
  expect_lt(a90$upper, a95$upper)
})

test_that("Poisson rate CI scales inversely with the denominator", {
  a <- mysterycall:::.poisson_rate_ci(20, 1e5, 1e5, 0.95)
  b <- mysterycall:::.poisson_rate_ci(20, 2e5, 1e5, 0.95)   # double the population
  expect_equal(b$lower, a$lower / 2, tolerance = 1e-10)
  expect_equal(b$upper, a$upper / 2, tolerance = 1e-10)
})

test_that("conf_level CI band brackets the point rate for every row", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = rep(c("A", "B"), each = 3),
                       year = rep(c(2013L, 2018L, 2023L), 2),
                       count = c(5, 40, 200, 0, 1, 3))
  pop <- c(`2013` = 1e6, `2018` = 1e6, `2023` = 1e6)
  p <- suppressWarnings(mysterycall_subspecialist_trend(counts, population = pop,
                                                        conf_level = 0.95))
  d <- p$data
  expect_true(all(d$density_low <= d$density & d$density <= d$density_high))
  expect_true(all(d$density_low >= 0))
})

# ---- trend_test recovers a known rate ratio --------------------------------
test_that("trend_test recovers the true annual rate ratio on log-linear data", {
  skip_if_not_installed("ggplot2")
  r <- 1.08; base <- 1000; yrs <- 2013:2023
  # counts sit exactly on base * r^(year - 2013); Poisson MLE recovers b = log(r)
  counts <- data.frame(subspecialty = "A", year = yrs,
                       count = base * r^(yrs - 2013))
  pop <- stats::setNames(rep(1e6, length(yrs)), yrs)
  p <- suppressWarnings(
    mysterycall_subspecialist_trend(counts, population = pop, trend_test = "poisson")
  )
  tt <- attr(p, "trend_test")
  expect_equal(tt$rr_per_year, r, tolerance = 1e-4)
  expect_lt(tt$p_value, 1e-3)
  # internal consistency of the derived percentages
  span <- diff(range(yrs))
  expect_equal(tt$pct_per_year, (tt$rr_per_year - 1) * 100, tolerance = 1e-8)
  expect_equal(tt$pct_total, (tt$rr_per_year^span - 1) * 100, tolerance = 1e-8)
})

test_that("trend_test reports rate ratio ~1 for a flat series", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "Flat", year = 2013:2020,
                       count = rep(500, 8))
  pop <- stats::setNames(rep(1e6, 8), 2013:2020)
  tt <- attr(suppressWarnings(
    mysterycall_subspecialist_trend(counts, population = pop, trend_test = "poisson")
  ), "trend_test")
  expect_equal(tt$rr_per_year, 1, tolerance = 1e-8)
  expect_equal(tt$pct_total, 0, tolerance = 1e-6)
})

# ---- infographic percent change is exact -----------------------------------
test_that("infographic percent change is exact across cases", {
  skip_if_not_installed("ggplot2")
  lab <- function(s, e) suppressWarnings(.sem_labels(
    mysterycall_subspecialist_infographic(subspecialty = "X", start = s, end = e,
                                          caption = NA)))
  expect_true(any(grepl("+12.5%",  lab(0.8, 0.9), fixed = TRUE)))
  expect_true(any(grepl("+200.0%", lab(1,   3),   fixed = TRUE)))
  expect_true(any(grepl("-50.0%",  lab(2,   1),   fixed = TRUE)))
  expect_true(any(grepl("+0.0%",   lab(2,   2),   fixed = TRUE)))   # no change
  expect_true(any(grepl("n/a",     lab(0,   5),   fixed = TRUE)))   # zero baseline
})

test_that("infographic colours a decrease with the decrease colour", {
  skip_if_not_installed("ggplot2")
  p <- suppressWarnings(mysterycall_subspecialist_infographic(
    subspecialty = c("Up", "Down"), start = c(1, 2), end = c(2, 1), caption = NA))
  all_cols <- unlist(lapply(p$layers, function(l) l$aes_params$colour))
  expect_true("#B22222" %in% all_cols)    # decrease_color is used only for drops
})

# ---- provenance records the exact computation ------------------------------
test_that("provenance records the exact computation string and scale", {
  skip_if_not_installed("ggplot2")
  counts <- data.frame(subspecialty = "A", year = c(2013L, 2014L), count = c(1, 2))
  p <- suppressWarnings(mysterycall_subspecialist_trend(
    counts, population = c(`2013` = 1e6, `2014` = 1e6), per = 1e5))
  prov <- attr(p, "provenance")
  expect_match(prov$computation, "count / population * 100000", fixed = TRUE)
  expect_equal(prov$per, 1e5)
  expect_equal(prov$years, c(2013, 2014))
})
