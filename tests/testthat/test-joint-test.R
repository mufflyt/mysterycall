# Tests for mysterycall_joint_test()

make_glm <- function(seed = 1, n = 300) {
  set.seed(seed)
  d <- data.frame(
    y = rbinom(n, 1, 0.4),
    grp = factor(sample(letters[1:4], n, TRUE)),
    x = rnorm(n))
  glm(y ~ grp + x, family = binomial, data = d)
}

test_that("df equals the number of parameters the factor adds", {
  fit <- make_glm()
  res <- mysterycall_joint_test(fit, "grp")
  expect_s3_class(res, "mysterycall_joint_test")
  expect_equal(res$df, 3L)                       # 4-level factor -> 3 df
  expect_true(res$p_value >= 0 && res$p_value <= 1)
})

test_that("chi-square and p match base R drop1 LRT (semantic cross-check)", {
  fit <- make_glm(seed = 7)
  res <- mysterycall_joint_test(fit, "grp")
  d1 <- drop1(fit, scope = ~ grp, test = "Chisq")
  # drop1 LRT statistic for grp
  expect_equal(res$chisq, unname(d1[["LRT"]][2]), tolerance = 1e-6)
  expect_equal(res$p_value, unname(d1[["Pr(>Chi)"]][2]), tolerance = 1e-6)
  expect_equal(res$df, unname(d1[["Df"]][2]))
})

test_that("logLik-based statistic equals the deviance difference for a glm", {
  fit <- make_glm(seed = 3)
  res <- mysterycall_joint_test(fit, "grp")
  reduced <- update(fit, . ~ . - grp, data = model.frame(fit))
  expect_equal(res$chisq, deviance(reduced) - deviance(fit), tolerance = 1e-6)
})

test_that("interaction terms involving the predictor are also dropped", {
  set.seed(2)
  d <- data.frame(
    y = rbinom(400, 1, 0.4),
    grp = factor(sample(letters[1:3], 400, TRUE)),
    z = factor(sample(c("u", "v"), 400, TRUE)))
  fit <- glm(y ~ grp * z, family = binomial, data = d)
  res <- mysterycall_joint_test(fit, "grp")
  expect_true(any(grepl(":", res$dropped_terms)))   # grp:z dropped
  # df = grp main (2) + grp:z interaction (2) = 4
  expect_equal(res$df, 4L)
})

test_that("a predictor not in the model errors", {
  fit <- make_glm()
  expect_error(mysterycall_joint_test(fit, "nope"),
               "not a fixed-effect term")
})

test_that("a mysterycall model wrapper is unwrapped", {
  fit <- make_glm()
  wrapper <- structure(list(model = fit), class = "mysterycall_logistic_model")
  res <- mysterycall_joint_test(wrapper, "grp")
  expect_equal(res$df, 3L)
})

test_that("as.data.frame returns a one-row tibble", {
  fit <- make_glm()
  df <- as.data.frame(mysterycall_joint_test(fit, "grp"))
  expect_equal(nrow(df), 1L)
  expect_true(all(c("predictor", "chisq", "df", "p_value") %in% names(df)))
})
