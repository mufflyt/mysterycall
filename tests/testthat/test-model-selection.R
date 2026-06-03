# ── mysterycall:::mysterycall_select_best_model ─────────────────────────────────────────────

m1 <- glm(mpg ~ wt,      data = mtcars, family = gaussian())
m2 <- glm(mpg ~ wt + hp, data = mtcars, family = gaussian())
m3 <- glm(mpg ~ wt + hp + cyl, data = mtcars, family = gaussian())

test_that("select_best_model AIC: returns data frame with expected columns", {
  res <- mysterycall:::mysterycall_select_best_model(list(base = m1, full = m2), "aic")
  expect_s3_class(res, "data.frame")
  expect_true(all(c("model", "AIC", "delta_AIC", "winner") %in% names(res)))
})

test_that("select_best_model AIC: winner has smallest AIC", {
  res <- mysterycall:::mysterycall_select_best_model(list(m1 = m1, m2 = m2, m3 = m3), "aic")
  winner_row <- res[res$winner, ]
  expect_equal(nrow(winner_row), 1L)
  expect_equal(winner_row$delta_AIC, 0)
})

test_that("select_best_model AIC: delta_AIC >= 0 for all rows", {
  res <- mysterycall:::mysterycall_select_best_model(list(m1 = m1, m2 = m2), "aic")
  expect_true(all(res$delta_AIC >= 0))
})

test_that("select_best_model BIC: works analogously", {
  res <- mysterycall:::mysterycall_select_best_model(list(m1 = m1, m2 = m2), "bic")
  expect_true("BIC" %in% names(res))
  expect_true(any(res$winner))
})

test_that("select_best_model LRT: returns comparison data frame", {
  res <- mysterycall:::mysterycall_select_best_model(list(m1 = m1, m2 = m2), "lrt")
  expect_s3_class(res, "data.frame")
  expect_true(all(c("comparison", "Chisq", "df", "p_value") %in% names(res)))
})

test_that("select_best_model LRT: one row per consecutive pair", {
  res <- mysterycall:::mysterycall_select_best_model(list(m1 = m1, m2 = m2, m3 = m3), "lrt")
  expect_equal(nrow(res), 2L)
})

test_that("select_best_model: unnamed list errors", {
  expect_error(mysterycall:::mysterycall_select_best_model(list(m1, m2)), "named list")
})

test_that("select_best_model LRT: single model errors", {
  expect_error(mysterycall:::mysterycall_select_best_model(list(only = m1), "lrt"), "2 models")
})
