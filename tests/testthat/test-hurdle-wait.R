# Tests for mysterycall_hurdle_wait()

make_hurdle_data <- function(seed = 1, n = 150) {
  set.seed(seed)
  d <- data.frame(
    practice  = rep(sprintf("p%03d", seq_len(n)), each = 2),
    insurance = rep(c("Commercial", "Medicaid"), n),
    stringsAsFactors = FALSE)
  med <- d$insurance == "Medicaid"
  d$obtained <- rbinom(nrow(d), 1, plogis(0.9 - 0.8 * med))
  d$wait_days <- ifelse(d$obtained == 1,
                        rnbinom(nrow(d), mu = ifelse(med, 20, 13), size = 2), NA)
  d
}

test_that("returns both parts with ratios and CIs", {
  skip_if_not_installed("glmmTMB")
  d <- make_hurdle_data()
  res <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                 random_intercept = "practice")
  expect_s3_class(res, "mysterycall_hurdle_wait")
  for (part in list(res$hurdle, res$count)) {
    expect_true(all(c("term", "estimate", "conf_low", "conf_high", "p_value")
                    %in% names(part)))
    expect_true(all(part$conf_low <= part$estimate + 1e-8))
    expect_true(all(part$conf_high >= part$estimate - 1e-8))
  }
  # a Medicaid term appears in both parts
  expect_true(any(grepl("Medicaid", res$hurdle$term)))
  expect_true(any(grepl("Medicaid", res$count$term)))
})

test_that("hurdle n is the full sample; count n is the obtained (truncated) subset", {
  skip_if_not_installed("glmmTMB")
  d <- make_hurdle_data(2)
  res <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                 random_intercept = "practice")
  expect_equal(res$n_hurdle, nrow(d))
  # truncated: only obtained with wait > 0
  expected_count_n <- sum(d$obtained == 1 & !is.na(d$wait_days) & d$wait_days > 0)
  expect_equal(res$n_count, expected_count_n)
  expect_true(res$truncated)
})

test_that("truncate_zero = FALSE keeps same-day (0) waits", {
  skip_if_not_installed("glmmTMB")
  d <- make_hurdle_data(3)
  d$wait_days[d$obtained == 1][1:5] <- 0    # some same-day appointments
  trunc <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                   random_intercept = "practice",
                                   truncate_zero = TRUE)
  keep <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                  random_intercept = "practice",
                                  truncate_zero = FALSE)
  expect_gt(keep$n_count, trunc$n_count)     # the 0-day waits are retained
})

test_that("works without a random intercept", {
  skip_if_not_installed("glmmTMB")
  d <- make_hurdle_data(4)
  res <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance")
  expect_s3_class(res, "mysterycall_hurdle_wait")
  expect_gt(nrow(res$count), 0L)
})

test_that("poisson count family is accepted", {
  skip_if_not_installed("glmmTMB")
  d <- make_hurdle_data(5)
  res <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                 count_family = "poisson")
  expect_equal(res$count_family, "poisson")
})

test_that("as.data.frame stacks the two parts with a part column", {
  skip_if_not_installed("glmmTMB")
  d <- make_hurdle_data()
  df <- as.data.frame(mysterycall_hurdle_wait(d, "obtained", "wait_days",
                                              "insurance"))
  expect_s3_class(df, "data.frame")
  expect_setequal(unique(df$part), c("hurdle", "count"))
})

test_that("a missing predictor errors", {
  d <- make_hurdle_data()
  expect_error(
    mysterycall_hurdle_wait(d, "obtained", "wait_days", "nope"),
    "subset")
})
