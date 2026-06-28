set.seed(1978)
n_doc <- 8
n_per <- 6
mock_nb <- data.frame(
  wait_days = rnbinom(n_doc * n_per, mu = 18, size = 1.5),
  insurance = rep(c("Medicaid", "BCBS"), n_doc * n_per / 2),
  gender    = sample(c("Male", "Female"), n_doc * n_per, replace = TRUE),
  physician = rep(paste0("Dr_", seq_len(n_doc)), each = n_per),
  stringsAsFactors = FALSE
)

mock_nb_na <- mock_nb
mock_nb_na$wait_days[3] <- NA

# ── Input validation (no glmmTMB needed) ───────────────────────────────────────

test_that("nb_model: stops when outcome column missing", {
  suppressWarnings(skip_if_not_installed("glmmTMB"))
  expect_error(
    mysterycall_nb_model(mock_nb, "no_such_col", "insurance", "physician"),
    "no_such_col"
  )
})

test_that("nb_model: stops when predictor column missing", {
  skip_if_not_installed("glmmTMB")
  expect_error(
    mysterycall_nb_model(mock_nb, "wait_days", "no_such_col", "physician"),
    "no_such_col"
  )
})

test_that("nb_model: stops when random_intercept column missing", {
  skip_if_not_installed("glmmTMB")
  expect_error(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "no_such_col"),
    "no_such_col"
  )
})

test_that("nb_model: stops on non-data-frame input", {
  skip_if_not_installed("glmmTMB")
  expect_error(
    mysterycall_nb_model(list(a = 1), "wait_days", "insurance", "physician"),
    class = "error"
  )
})

# ── Return structure ───────────────────────────────────────────────────────────

test_that("nb_model: returns correct class", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "physician")
  )
  expect_s3_class(result, "mysterycall_nb_model")
})

test_that("nb_model: irr_table has required columns", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "physician")
  )
  expected_cols <- c("term", "irr", "ci_lower", "ci_upper", "p_value", "p_value_fmt")
  expect_true(all(expected_cols %in% names(result$irr_table)))
})

test_that("nb_model: theta is positive numeric", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "physician")
  )
  expect_true(is.numeric(result$theta))
  expect_true(length(result$theta) == 1L)
  expect_true(result$theta > 0)
})

test_that("nb_model: convergence field is present", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "physician")
  )
  expect_true("convergence" %in% names(result))
  expect_true("converged" %in% names(result$convergence))
  expect_type(result$convergence$converged, "logical")
})

test_that("nb_model: n and n_dropped are correct", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(
    mysterycall_nb_model(mock_nb_na, "wait_days", "insurance", "physician")
  )
  expect_equal(result$n_dropped, 1L)
  expect_equal(result$n, nrow(mock_nb_na) - 1L)
})

test_that("nb_model: aic and bic are numeric", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "physician")
  )
  expect_type(result$aic, "double")
  expect_type(result$bic, "double")
})

# ── print method ──────────────────────────────────────────────────────────────

test_that("print.mysterycall_nb_model: dispatches without error", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "physician")
  )
  expect_output(print(result), regexp = "Negative Binomial|theta|IRR", ignore.case = TRUE)
})

# ── Downstream helpers accept nb_model ────────────────────────────────────────

test_that("irr_plot accepts mysterycall_nb_model", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  result <- suppressWarnings(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "physician")
  )
  p <- mysterycall_irr_plot(result)
  expect_s3_class(p, "ggplot")
})

test_that("model_table accepts mysterycall_nb_model", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "physician")
  )
  tbl <- mysterycall_model_table(result)
  expect_s3_class(tbl, "data.frame")
  expect_true(nrow(tbl) > 0L)
})

test_that("write_results_paragraph accepts mysterycall_nb_model", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "physician")
  )
  para <- mysterycall_write_results_paragraph(result, "BCBS", "insurance")
  expect_type(para, "character")
  expect_match(para, "negative binomial", ignore.case = TRUE)
})

test_that("model_metrics accepts mysterycall_nb_model", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "physician")
  )
  metrics <- mysterycall_model_metrics(result)
  expect_true(is.numeric(metrics$mae))
  expect_true(is.numeric(metrics$rmse))
})

test_that("select_best_model uses $aic from nb_model wrapper", {
  skip_if_not_installed("glmmTMB")
  nb <- suppressWarnings(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "physician")
  )
  # Mix of wrapper and bare model
  m_bare <- glm(wait_days ~ insurance, data = mock_nb, family = poisson())
  out <- mysterycall_select_best_model(list(nb = nb, glm = m_bare))
  expect_s3_class(out, "data.frame")
  expect_false(any(is.na(out$AIC)))
})

test_that("marginal_effects handles nb_model when marginaleffects is installed", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("marginaleffects")
  result <- suppressWarnings(
    mysterycall_nb_model(mock_nb, "wait_days", "insurance", "physician")
  )
  expect_s3_class(mysterycall_marginal_effects(result), "data.frame")
})
