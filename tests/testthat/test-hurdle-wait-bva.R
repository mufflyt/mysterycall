# Boundary-value analysis (BVA) for mysterycall_hurdle_wait()
#
# Each parameter with a documented bound is probed at the edge: the last value
# that is still accepted, the first value that is rejected, and (for the wait
# truncation) the pivot value that flips an observation between the two parts.
# Every expectation below was confirmed by RUNNING the code, not assumed.

# Data with a controllable number of same-day (0-day) waits so the wait == 0
# truncation boundary can be exercised exactly.
make_bva_data <- function(seed = 1, n = 120, n_zero = 10) {
  set.seed(seed)
  d <- data.frame(
    practice  = rep(sprintf("p%03d", seq_len(n)), each = 2),
    insurance = rep(c("Commercial", "Medicaid"), n),
    stringsAsFactors = FALSE)
  d$obtained <- rbinom(nrow(d), 1, 0.7)
  d$wait_days <- ifelse(d$obtained == 1,
                        rnbinom(nrow(d), mu = 14, size = 2) + 1L, NA)
  # force exactly n_zero obtained rows to a 0-day (same-day) wait
  obtained_idx <- which(d$obtained == 1)
  d$wait_days[head(obtained_idx, n_zero)] <- 0L
  d
}

# ---- conf_level: accepted on [0.5, 0.999], rejected just outside -------------

test_that("conf_level lower boundary: 0.5 accepted, just-below rejected", {
  skip_if_not_installed("glmmTMB")
  d <- make_bva_data()
  # 0.5 is the inclusive lower edge -> proceeds to fit
  res <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                 conf_level = 0.5)
  expect_s3_class(res, "mysterycall_hurdle_wait")
  # just below the edge -> rejected before any model is fit
  expect_error(
    mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                            conf_level = 0.5 - 1e-6))
})

test_that("conf_level upper boundary: 0.999 accepted, just-above rejected", {
  skip_if_not_installed("glmmTMB")
  d <- make_bva_data()
  res <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                 conf_level = 0.999)
  expect_s3_class(res, "mysterycall_hurdle_wait")
  expect_error(
    mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                            conf_level = 0.999 + 1e-6))
})

test_that("wider conf_level yields wider CIs at the boundaries", {
  skip_if_not_installed("glmmTMB")
  d <- make_bva_data()
  narrow <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                    conf_level = 0.5)
  wide   <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                    conf_level = 0.999)
  # same deterministic fit, only z changes -> every interval strictly wider
  w_narrow <- narrow$count$conf_high - narrow$count$conf_low
  w_wide   <- wide$count$conf_high - wide$count$conf_low
  expect_true(all(w_wide > w_narrow))
})

# ---- data: min.rows = 1 ------------------------------------------------------

test_that("data at the row-count boundary: 0 rows rejected, 1 row accepted-to-fit", {
  d0 <- make_bva_data()[0, , drop = FALSE]
  expect_error(
    mysterycall_hurdle_wait(d0, "obtained", "wait_days", "insurance"))
  # a single row clears the assert_data_frame(min.rows = 1L) gate; the failure,
  # if any, comes from glmmTMB downstream, never from the row-count check.
  d1 <- make_bva_data()[1, , drop = FALSE]
  err <- tryCatch({
    mysterycall_hurdle_wait(d1, "obtained", "wait_days", "insurance")
    ""  # no error at all -> certainly not a row-count rejection
  }, error = function(e) conditionMessage(e))
  expect_false(grepl("min.rows|number of rows|nrow", err, ignore.case = TRUE))
})

# ---- predictors: min.len = 1 -------------------------------------------------

test_that("predictors at the length boundary: empty rejected, single accepted-to-fit", {
  skip_if_not_installed("glmmTMB")
  d <- make_bva_data()
  expect_error(
    mysterycall_hurdle_wait(d, "obtained", "wait_days", character(0)))
  # exactly one predictor is the smallest valid vector
  res <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance")
  expect_s3_class(res, "mysterycall_hurdle_wait")
})

# ---- truncate_zero: the wait == 0 pivot --------------------------------------

test_that("wait == 0 is the truncation pivot: excluded when TRUE, kept when FALSE", {
  skip_if_not_installed("glmmTMB")
  n_zero <- 10L
  d <- make_bva_data(n_zero = n_zero)
  obtained_nonmissing <- sum(d$obtained == 1 & !is.na(d$wait_days))

  trunc <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                   truncate_zero = TRUE)
  keep  <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                   truncate_zero = FALSE)

  # untruncated count part carries every obtained, non-missing wait...
  expect_equal(keep$n_count, obtained_nonmissing)
  # ...truncated drops exactly the wait == 0 rows (the boundary value)
  expect_equal(trunc$n_count, obtained_nonmissing - n_zero)
  expect_equal(keep$n_count - trunc$n_count, n_zero)
  expect_true(trunc$truncated)
  expect_false(keep$truncated)
})
