# ── mysterycall:::mysterycall_screen_interactions ──────────────────────────────────────────

make_df <- function(seed = 1L) {
  set.seed(seed)
  n <- 60L
  data.frame(
    wait    = rpois(n, 14),
    ins     = rep(c("BCBS", "Medicaid"), n / 2),
    gender  = sample(c("Male", "Female"), n, replace = TRUE),
    setting = sample(c("Academic", "Private"), n, replace = TRUE),
    phys    = rep(paste0("D", seq_len(n / 5)), each = 5L),
    stringsAsFactors = FALSE
  )
}

test_that("screen_interactions: returns data frame", {
  df  <- make_df()
  res <- mysterycall:::mysterycall_screen_interactions(df, "wait", "ins", c("gender", "setting"))
  expect_s3_class(res, "data.frame")
})

test_that("screen_interactions: one row per candidate", {
  df  <- make_df()
  res <- mysterycall:::mysterycall_screen_interactions(df, "wait", "ins", c("gender", "setting"))
  expect_equal(nrow(res), 2L)
})

test_that("screen_interactions: expected column names", {
  df  <- make_df()
  res <- mysterycall:::mysterycall_screen_interactions(df, "wait", "ins", c("gender"))
  expect_true(all(c("candidate","n_terms","min_p_value","significant") %in% names(res)))
})

test_that("screen_interactions: detects factor-expanded interaction coefficients", {
  df <- data.frame(
    wait = rpois(40, 12),
    ins = factor(rep(c("BCBS", "Medicaid"), 20)),
    gender = factor(rep(c("Female", "Male"), each = 20)),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_screen_interactions(df, "wait", "ins", "gender")
  expect_equal(res$n_terms, 1L)
  expect_false(is.na(res$min_p_value))
})

test_that("screen_interactions: sorted by min_p_value ascending", {
  df  <- make_df()
  res <- mysterycall:::mysterycall_screen_interactions(df, "wait", "ins", c("gender","setting"))
  p   <- res$min_p_value[!is.na(res$min_p_value)]
  expect_true(all(diff(p) >= 0))
})

test_that("screen_interactions: missing column errors", {
  df <- make_df()
  expect_error(
    mysterycall:::mysterycall_screen_interactions(df, "wait", "ins", c("nonexistent")),
    "not found"
  )
})

test_that("screen_interactions: non-data-frame errors", {
  expect_error(
    mysterycall:::mysterycall_screen_interactions(list(), "wait", "ins", "gender"),
    "data frame"
  )
})

test_that("screen_interactions: with random_intercept uses glmer", {
  skip_if_not_installed("lme4")
  df  <- make_df()
  res <- mysterycall:::mysterycall_screen_interactions(
    df, "wait", "ins", "gender", random_intercept = "phys"
  )
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 1L)
})

# ── Negative binomial family ───────────────────────────────────────────────────

make_nb_df <- function(seed = 42L) {
  set.seed(seed)
  n <- 60L
  data.frame(
    wait    = rnbinom(n, mu = 14, size = 1.5),
    ins     = rep(c("BCBS", "Medicaid"), n / 2),
    gender  = sample(c("Male", "Female"), n, replace = TRUE),
    setting = sample(c("Academic", "Private"), n, replace = TRUE),
    phys    = rep(paste0("D", seq_len(n / 5)), each = 5L),
    stringsAsFactors = FALSE
  )
}

test_that("screen_interactions NB: returns data frame", {
  suppressWarnings(skip_if_not_installed("glmmTMB"))
  df  <- make_nb_df()
  res <- suppressWarnings(
    mysterycall_screen_interactions(df, "wait", "ins", c("gender", "setting"),
                                    family = "negative_binomial")
  )
  expect_s3_class(res, "data.frame")
})

test_that("screen_interactions NB: one row per candidate", {
  skip_if_not_installed("glmmTMB")
  df  <- make_nb_df()
  res <- suppressWarnings(
    mysterycall_screen_interactions(df, "wait", "ins", c("gender", "setting"),
                                    family = "negative_binomial")
  )
  expect_equal(nrow(res), 2L)
})

test_that("screen_interactions NB: expected column names", {
  skip_if_not_installed("glmmTMB")
  df  <- make_nb_df()
  res <- suppressWarnings(
    mysterycall_screen_interactions(df, "wait", "ins", "gender",
                                    family = "negative_binomial")
  )
  expect_true(all(c("candidate", "n_terms", "min_p_value", "significant") %in% names(res)))
})

test_that("screen_interactions NB: detects factor-expanded interaction coefficients", {
  skip_if_not_installed("glmmTMB")
  df <- data.frame(
    wait = rnbinom(60, mu = 12, size = 1.5),
    ins = factor(rep(c("BCBS", "Medicaid"), 30)),
    gender = factor(rep(c("Female", "Male"), each = 30)),
    stringsAsFactors = FALSE
  )
  res <- suppressWarnings(
    mysterycall_screen_interactions(df, "wait", "ins", "gender",
                                    family = "negative_binomial")
  )
  expect_equal(res$n_terms, 1L)
  expect_false(is.na(res$min_p_value))
})

test_that("screen_interactions NB: sorted by min_p_value ascending", {
  skip_if_not_installed("glmmTMB")
  df  <- make_nb_df()
  res <- suppressWarnings(
    mysterycall_screen_interactions(df, "wait", "ins", c("gender", "setting"),
                                    family = "negative_binomial")
  )
  p <- res$min_p_value[!is.na(res$min_p_value)]
  expect_true(all(diff(p) >= 0))
})

test_that("screen_interactions NB: with random_intercept uses glmmTMB", {
  skip_if_not_installed("glmmTMB")
  df  <- make_nb_df()
  res <- suppressWarnings(
    mysterycall_screen_interactions(df, "wait", "ins", "gender",
                                    random_intercept = "phys",
                                    family = "negative_binomial")
  )
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 1L)
})

test_that("screen_interactions NB: invalid family rejected", {
  expect_error(
    mysterycall_screen_interactions(make_nb_df(), "wait", "ins", "gender",
                                    family = "gamma"),
    class = "error"
  )
})
