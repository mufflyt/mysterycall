# Tests for mysterycall_build_matched_controls()

make_match_data <- function(seed = 1) {
  set.seed(seed)
  treated <- data.frame(
    npi = 1:20,
    state = rep(c("CO", "TX"), each = 10),
    lat = c(runif(10, 39.6, 39.8), runif(10, 32.7, 32.9)),
    lon = c(runif(10, -105.1, -104.9), runif(10, -96.9, -96.7)),
    years = rpois(20, 12), female = rbinom(20, 1, 0.5),
    stringsAsFactors = FALSE)
  candidates <- data.frame(
    npi = 101:500,
    state = rep(c("CO", "TX"), each = 200),
    lat = c(runif(200, 39.6, 39.8), runif(200, 32.7, 32.9)),
    lon = c(runif(200, -105.1, -104.9), runif(200, -96.9, -96.7)),
    years = rpois(400, 10), female = rbinom(400, 1, 0.5),
    stringsAsFactors = FALSE)
  list(treated = treated, candidates = candidates)
}

test_that("returns a 1:1 matched cohort with pair records", {
  d <- make_match_data()
  m <- mysterycall_build_matched_controls(
    d$treated, d$candidates, treatment ~ years + female,
    id_col = "npi", exact = "state", coords = c("lat", "lon"),
    caliper_miles = 50)
  expect_s3_class(m, "mysterycall_matched_controls")
  expect_equal(m$n_matched, nrow(m$pairs))
  expect_equal(nrow(m$matched_treated), m$n_matched)
  expect_equal(nrow(m$matched_controls), m$n_matched)
  expect_true(all(c("pair_id", "treated_id", "control_id", "ps_diff",
                    "distance_miles") %in% names(m$pairs)))
})

test_that("controls are used without replacement", {
  d <- make_match_data(2)
  m <- mysterycall_build_matched_controls(
    d$treated, d$candidates, treatment ~ years + female,
    id_col = "npi", exact = "state", coords = c("lat", "lon"),
    caliper_miles = 60)
  expect_equal(anyDuplicated(m$pairs$control_id), 0L)
})

test_that("exact strata are respected: control state == treated state", {
  d <- make_match_data(3)
  m <- mysterycall_build_matched_controls(
    d$treated, d$candidates, treatment ~ years + female,
    id_col = "npi", exact = "state", coords = c("lat", "lon"),
    caliper_miles = 60)
  tstate <- d$treated$state[match(m$pairs$treated_id, d$treated$npi)]
  cstate <- d$candidates$state[match(m$pairs$control_id, d$candidates$npi)]
  expect_equal(tstate, cstate)
})

test_that("the distance caliper is enforced", {
  d <- make_match_data(4)
  m <- mysterycall_build_matched_controls(
    d$treated, d$candidates, treatment ~ years + female,
    id_col = "npi", exact = "state", coords = c("lat", "lon"),
    caliper_miles = 30)
  expect_true(all(m$pairs$distance_miles < 30))
})

test_that("min_in_caliper blocks matches when the pool is too thin", {
  d <- make_match_data(5)
  # a tiny caliper leaves very few candidates in range
  m1 <- mysterycall_build_matched_controls(
    d$treated, d$candidates, treatment ~ years + female,
    id_col = "npi", exact = "state", coords = c("lat", "lon"),
    caliper_miles = 3, min_in_caliper = 1)
  m5 <- mysterycall_build_matched_controls(
    d$treated, d$candidates, treatment ~ years + female,
    id_col = "npi", exact = "state", coords = c("lat", "lon"),
    caliper_miles = 3, min_in_caliper = 8)
  expect_true(m5$n_matched <= m1$n_matched)   # stricter -> no more matches
})

test_that("nearest-neighbour picks the closest propensity score", {
  # tiny deterministic example: one treated, two candidates, no caliper
  treated <- data.frame(npi = 1, x = 5)
  candidates <- data.frame(npi = c(10, 11), x = c(5, 50))
  m <- mysterycall_build_matched_controls(
    treated, candidates, treatment ~ x, id_col = "npi")
  # candidate with x closest to the treated's x has the nearer propensity score
  expect_equal(m$pairs$control_id, 10)
})

test_that("cluster_col matches at most one treated per cluster", {
  d <- make_match_data(6)
  d$treated$office <- rep(1:5, each = 4)      # 5 offices, 4 providers each
  m <- mysterycall_build_matched_controls(
    d$treated, d$candidates, treatment ~ years + female,
    id_col = "npi", exact = "state", coords = c("lat", "lon"),
    caliper_miles = 60, cluster_col = "office")
  expect_true(m$n_matched <= 5L)
  expect_equal(m$n_treated, 5L)
  # each matched treated belongs to a distinct office
  offices <- d$treated$office[match(m$pairs$treated_id, d$treated$npi)]
  expect_equal(anyDuplicated(offices), 0L)
})

test_that("balance table reports SMDs for numeric covariates", {
  d <- make_match_data(7)
  m <- mysterycall_build_matched_controls(
    d$treated, d$candidates, treatment ~ years + female,
    id_col = "npi", exact = "state", coords = c("lat", "lon"),
    caliper_miles = 60)
  expect_setequal(m$balance$covariate, c("years", "female"))
  expect_true(all(is.finite(m$balance$smd)))
})

test_that("works without a caliper (exact strata only)", {
  d <- make_match_data(8)
  m <- mysterycall_build_matched_controls(
    d$treated, d$candidates, treatment ~ years + female,
    id_col = "npi", exact = "state")
  expect_equal(m$n_matched, 20L)              # plenty of candidates per state
  expect_true(all(is.na(m$pairs$distance_miles)))
})

test_that("unmatched treated are counted, not dropped silently", {
  # only 1 candidate in TX but 10 treated in TX -> most TX go unmatched
  set.seed(9)
  treated <- data.frame(npi = 1:12, state = c(rep("CO", 2), rep("TX", 10)),
                        x = rnorm(12))
  candidates <- data.frame(npi = 101:110, state = c(rep("CO", 9), "TX"),
                           x = rnorm(10))
  m <- mysterycall_build_matched_controls(
    treated, candidates, treatment ~ x, id_col = "npi", exact = "state")
  expect_equal(m$n_treated, 12L)
  expect_equal(m$n_matched + m$n_unmatched, 12L)
  expect_true(m$n_unmatched >= 9L)            # 10 TX treated, 1 TX candidate
})

test_that("as.data.frame returns the pairs", {
  d <- make_match_data()
  m <- mysterycall_build_matched_controls(
    d$treated, d$candidates, treatment ~ years + female,
    id_col = "npi", exact = "state")
  expect_s3_class(as.data.frame(m), "data.frame")
})
