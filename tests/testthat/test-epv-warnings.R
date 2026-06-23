# Tests for events-per-variable (EPV) warnings in Poisson and NB model functions.
#
# EPV = n_complete_cases / est_params, where est_params = 1 (intercept) +
# sum(n_levels - 1) for factor/character predictors, + 1 per numeric predictor.
#   EPV < 5  → "Very low" warning
#   EPV < 10 → "Low" warning
#   EPV >= 10 → no EPV warning

# ── Helper: capture only EPV-related warnings, swallow everything else ─────────
.capture_epv_warns <- function(expr) {
  warns <- character(0L)
  withCallingHandlers(
    tryCatch(suppressMessages(expr), error = function(e) NULL),
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  warns[grepl("events-per-variable", warns, fixed = TRUE)]
}

# ── Test data ──────────────────────────────────────────────────────────────────

# 80 obs, ins (2 lvl → 1 df) + intercept = 2 params → EPV = 40 (safe)
make_high_epv <- function() {
  set.seed(1L)
  data.frame(
    wait = rpois(80L, 15L),
    ins  = rep(c("A", "B"), 40L),
    phys = rep(paste0("D", 1:8), each = 10L),
    stringsAsFactors = FALSE
  )
}

# 18 obs, ins (2 lvl → 1 df) + intercept = 2 params → EPV = 9 (low but ≥ 5)
make_low_epv <- function() {
  set.seed(2L)
  data.frame(
    wait = rpois(18L, 15L),
    ins  = rep(c("A", "B"), 9L),
    phys = rep(paste0("D", 1:3), each = 6L),
    stringsAsFactors = FALSE
  )
}

# 10 obs, ins (2 lvl → 1 df) + region (5 lvl → 4 df) + intercept = 6 params
# → EPV = 10/6 ≈ 1.67 (very low < 5)
make_very_low_epv <- function() {
  set.seed(3L)
  data.frame(
    wait   = rpois(10L, 15L),
    ins    = rep(c("A", "B"), 5L),
    region = rep(c("N", "S", "E", "W", "C"), 2L),
    phys   = paste0("D", 1:10),
    stringsAsFactors = FALSE
  )
}

# ── Poisson EPV tests ──────────────────────────────────────────────────────────

test_that("poisson: no EPV warning when EPV >= 10", {
  skip_if_not_installed("lme4")
  df <- make_high_epv()
  epv_warns <- .capture_epv_warns(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  )
  expect_length(epv_warns, 0L)
})

test_that("poisson: warns 'Low events-per-variable' when EPV < 10 and >= 5", {
  skip_if_not_installed("lme4")
  df <- make_low_epv()
  epv_warns <- .capture_epv_warns(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  )
  expect_gte(length(epv_warns), 1L)
  expect_match(epv_warns[[1L]], "events-per-variable")
  expect_false(grepl("Very low", epv_warns[[1L]]))
})

test_that("poisson: warns 'Very low events-per-variable' when EPV < 5", {
  skip_if_not_installed("lme4")
  df <- make_very_low_epv()
  epv_warns <- .capture_epv_warns(
    mysterycall_poisson_model(df, "wait", c("ins", "region"), "phys")
  )
  expect_gte(length(epv_warns), 1L)
  expect_match(epv_warns[[1L]], "Very low")
})

# ── NB EPV tests ───────────────────────────────────────────────────────────────

test_that("nb: no EPV warning when EPV >= 10", {
  skip_if_not_installed("glmmTMB")
  set.seed(42L)
  df <- data.frame(
    wait = rnbinom(80L, mu = 15, size = 2),
    ins  = rep(c("A", "B"), 40L),
    phys = rep(paste0("D", 1:8), each = 10L),
    stringsAsFactors = FALSE
  )
  epv_warns <- .capture_epv_warns(
    mysterycall_nb_model(df, "wait", "ins", "phys")
  )
  expect_length(epv_warns, 0L)
})

test_that("nb: warns 'Low events-per-variable' when EPV < 10 and >= 5", {
  skip_if_not_installed("glmmTMB")
  set.seed(42L)
  df <- data.frame(
    wait = rnbinom(18L, mu = 15, size = 2),
    ins  = rep(c("A", "B"), 9L),
    phys = rep(paste0("D", 1:3), each = 6L),
    stringsAsFactors = FALSE
  )
  epv_warns <- .capture_epv_warns(
    mysterycall_nb_model(df, "wait", "ins", "phys")
  )
  expect_gte(length(epv_warns), 1L)
  expect_match(epv_warns[[1L]], "events-per-variable")
  expect_false(grepl("Very low", epv_warns[[1L]]))
})

test_that("nb: warns 'Very low events-per-variable' when EPV < 5", {
  skip_if_not_installed("glmmTMB")
  set.seed(42L)
  df <- data.frame(
    wait   = rnbinom(10L, mu = 15, size = 2),
    ins    = rep(c("A", "B"), 5L),
    region = rep(c("N", "S", "E", "W", "C"), 2L),
    phys   = paste0("D", 1:10),
    stringsAsFactors = FALSE
  )
  epv_warns <- .capture_epv_warns(
    mysterycall_nb_model(df, "wait", c("ins", "region"), "phys")
  )
  expect_gte(length(epv_warns), 1L)
  expect_match(epv_warns[[1L]], "Very low")
})
