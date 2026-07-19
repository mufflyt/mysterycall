# Tests for mysterycall_leave_one_out()

make_loo_data <- function(seed = 1, n = 300) {
  set.seed(seed)
  data.frame(
    y = rbinom(n, 1, 0.4),
    grp = factor(sample(c("a", "b", "c"), n, TRUE)),
    caller = factor(sample(paste0("c", 1:5), n, TRUE)))
}

test_that("one refit per group level, tracking the target term", {
  d <- make_loo_data()
  fit <- glm(y ~ grp, family = binomial, data = d)
  res <- mysterycall_leave_one_out(fit, d, group = "caller", term = "grpb")
  expect_s3_class(res, "mysterycall_leave_one_out")
  expect_equal(nrow(res$table), 5L)              # 5 callers
  expect_setequal(res$table$group_excluded, paste0("c", 1:5))
  expect_true(all(res$table$converged))
  expect_true("ratio" %in% names(res$table))
})

test_that("each refit's n equals the full n minus the excluded group's rows", {
  d <- make_loo_data(seed = 4)
  fit <- glm(y ~ grp, family = binomial, data = d)
  res <- mysterycall_leave_one_out(fit, d, group = "caller", term = "grpb")
  for (lv in levels(d$caller)) {
    expected_n <- sum(d$caller != lv)
    got <- res$table$n[res$table$group_excluded == lv]
    expect_equal(got, expected_n)
  }
})

test_that("a leave-out estimate matches a manual refit (semantic check)", {
  d <- make_loo_data(seed = 5)
  fit <- glm(y ~ grp, family = binomial, data = d)
  res <- mysterycall_leave_one_out(fit, d, group = "caller", term = "grpb",
                                   exponentiate = FALSE)
  lv <- "c3"
  manual <- glm(y ~ grp, family = binomial, data = d[d$caller != lv, ])
  expect_equal(res$table$estimate[res$table$group_excluded == lv],
               unname(coef(manual)["grpb"]), tolerance = 1e-6)
})

test_that("joint_predictor adds a joint_p column via mysterycall_joint_test", {
  d <- make_loo_data(seed = 6)
  fit <- glm(y ~ grp, family = binomial, data = d)
  res <- mysterycall_leave_one_out(fit, d, group = "caller", term = "grpb",
                                   joint_predictor = "grp")
  expect_true("joint_p" %in% names(res$table))
  expect_true(all(res$table$joint_p >= 0 & res$table$joint_p <= 1))
})

test_that("exponentiate = TRUE reports ratio = exp(estimate)", {
  d <- make_loo_data(seed = 8)
  fit <- glm(y ~ grp, family = binomial, data = d)
  res <- mysterycall_leave_one_out(fit, d, group = "caller", term = "grpb")
  expect_equal(res$table$ratio, exp(res$table$estimate), tolerance = 1e-9)
})

test_that("full-data estimate is stored", {
  d <- make_loo_data()
  fit <- glm(y ~ grp, family = binomial, data = d)
  res <- mysterycall_leave_one_out(fit, d, group = "caller", term = "grpb")
  expect_equal(res$full$ratio, exp(unname(coef(fit)["grpb"])), tolerance = 1e-9)
})

test_that("as.data.frame returns the table", {
  d <- make_loo_data()
  fit <- glm(y ~ grp, family = binomial, data = d)
  res <- mysterycall_leave_one_out(fit, d, group = "caller", term = "grpb")
  expect_s3_class(as.data.frame(res), "data.frame")
})
