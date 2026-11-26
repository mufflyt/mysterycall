# Adversarial: required-argument errors must name the argument the USER forgot,
# not leak internal parameter names from deep in the validation stack
# (previously: "argument 'required' is missing, with no default").

test_that("missing random_intercept names random_intercept, not 'required'", {
  df <- data.frame(y = c(rep(1, 10), rep(0, 10)), x = rnorm(20), grp = rep(1:4, 5))
  for (fn in c("mysterycall_logistic_model", "mysterycall_poisson_model", "mysterycall_nb_model")) {
    err <- tryCatch(
      suppressWarnings(get(fn)(df, outcome = "y", predictors = "x")),
      error = function(e) conditionMessage(e)
    )
    expect_match(err, "random_intercept", ignore.case = TRUE,
                 info = paste(fn, "should name random_intercept"))
    expect_false(grepl("argument \"required\"", err),
                 info = paste(fn, "must not leak the internal 'required' parameter"))
  }
})

test_that("missing outcome and predictors are named clearly", {
  df <- data.frame(y = c(rep(1, 10), rep(0, 10)), x = rnorm(20), grp = rep(1:4, 5))
  err_out <- tryCatch(
    suppressWarnings(mysterycall_logistic_model(df, predictors = "x", random_intercept = "grp")),
    error = function(e) conditionMessage(e)
  )
  expect_match(err_out, "outcome")
  expect_false(grepl("argument \"required\"", err_out))

  err_pred <- tryCatch(
    suppressWarnings(mysterycall_logistic_model(df, outcome = "y", random_intercept = "grp")),
    error = function(e) conditionMessage(e)
  )
  expect_match(err_pred, "predictors")
  expect_false(grepl("argument \"required\"", err_pred))
})

test_that("fully-specified calls still run (no regression from the guard)", {
  skip_if_not_installed("lme4")
  set.seed(1)
  df <- data.frame(y = c(rep(1, 15), rep(0, 15)), x = rnorm(30), grp = rep(1:6, 5))
  r <- suppressWarnings(mysterycall_logistic_model(
    df, outcome = "y", predictors = "x", random_intercept = "grp"
  ))
  expect_s3_class(r, "mysterycall_logistic_model")
})
