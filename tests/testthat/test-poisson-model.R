set.seed(1978)
n_doc <- 8
n_per <- 6
mock <- data.frame(
  wait_days = c(rpois(n_doc * n_per / 2, lambda = 22),
                rpois(n_doc * n_per / 2, lambda = 14)),
  insurance = rep(c("Medicaid", "BCBS"), each = n_doc * n_per / 2),
  gender    = sample(c("Male", "Female"), n_doc * n_per, replace = TRUE),
  physician = rep(paste0("Dr_", seq_len(n_doc)), each = n_per),
  stringsAsFactors = FALSE
)

# Add one row with a missing value to test n_dropped
mock_na <- mock
mock_na$wait_days[3] <- NA

# ── Input validation (no lme4 needed) ─────────────────────────────────────────

test_that("poisson_model: stops when outcome column missing", {
  skip_if_not_installed("lme4")
  expect_error(
    mysterycall_poisson_model(mock, "no_such_col", "insurance", "physician"),
    "no_such_col"
  )
})

test_that("poisson_model: stops when predictor column missing", {
  skip_if_not_installed("lme4")
  expect_error(
    mysterycall_poisson_model(mock, "wait_days", "no_such_col", "physician"),
    "no_such_col"
  )
})

test_that("poisson_model: stops when random_intercept column missing", {
  skip_if_not_installed("lme4")
  expect_error(
    mysterycall_poisson_model(mock, "wait_days", "insurance", "no_such_col"),
    "no_such_col"
  )
})

test_that("poisson_model: stops on non-numeric outcome", {
  skip_if_not_installed("lme4")
  df <- mock
  df$wait_days <- as.character(df$wait_days)
  expect_error(
    mysterycall_poisson_model(df, "wait_days", "insurance", "physician"),
    "numeric"
  )
})

test_that("poisson_model: stops on negative outcome values", {
  skip_if_not_installed("lme4")
  df <- mock
  df$wait_days[1] <- -1L
  expect_error(
    mysterycall_poisson_model(df, "wait_days", "insurance", "physician"),
    "negative"
  )
})

test_that("poisson_model: stops on invalid conf_level", {
  skip_if_not_installed("lme4")
  expect_error(
    mysterycall_poisson_model(mock, "wait_days", "insurance", "physician",
                               conf_level = 1.5),
    "conf_level"
  )
  expect_error(
    mysterycall_poisson_model(mock, "wait_days", "insurance", "physician",
                               conf_level = 0),
    "conf_level"
  )
})

# ── Model fitting ──────────────────────────────────────────────────────────────

test_that("poisson_model: returns correct class", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", c("insurance", "gender"), "physician"
  ))
  expect_s3_class(res, "mysterycall_poisson_model")
})

test_that("poisson_model: return list has all expected names", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", c("insurance", "gender"), "physician"
  ))
  expect_named(res, c("model", "irr_table", "random_effects", "factor_refs",
                       "formula", "n", "n_dropped", "n_clusters",
                       "overdispersion", "convergence", "aic", "bic"),
               ignore.order = TRUE)
})

test_that("poisson_model: irr_table has correct columns", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  expect_true(all(c("term", "estimate", "se", "z_value", "p_value",
                     "p_value_fmt", "irr", "ci_lower", "ci_upper")
                  %in% names(res$irr_table)))
})

test_that("poisson_model: irr == exp(estimate)", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  expect_equal(res$irr_table$irr, exp(res$irr_table$estimate), tolerance = 1e-8)
})

test_that("poisson_model: ci_lower < irr < ci_upper for all rows", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  tbl <- res$irr_table
  expect_true(all(tbl$ci_lower < tbl$irr))
  expect_true(all(tbl$irr      < tbl$ci_upper))
})

test_that("poisson_model: p_values are numeric in [0, 1]", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  p <- res$irr_table$p_value
  expect_true(is.numeric(p))
  expect_true(all(p >= 0 & p <= 1, na.rm = TRUE))
})

test_that("poisson_model: p_value_fmt is '<0.001' or '0.xxx'", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  fmt <- res$irr_table$p_value_fmt
  expect_true(all(grepl("^< 0\\.001$|^\\d\\.\\d{3}$", fmt)))
})

test_that("poisson_model: n equals complete cases used", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock_na, "wait_days", "insurance", "physician"
  ))
  expect_equal(res$n,         nrow(mock) - 1L)
  expect_equal(res$n_dropped, 1L)
})

test_that("poisson_model: n_clusters equals distinct physician count", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  expect_equal(res$n_clusters, length(unique(mock$physician)))
})

test_that("poisson_model: formula contains random intercept term", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  expect_true(grepl("physician", deparse(res$formula)))
  expect_true(grepl("1 | physician", deparse(res$formula), fixed = TRUE))
})

test_that("poisson_model: factor_refs records reference level for character predictor", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  expect_true("insurance" %in% names(res$factor_refs))
  # BCBS sorts before Medicaid alphabetically
  expect_equal(res$factor_refs[["insurance"]], "BCBS")
})

test_that("poisson_model: overdispersion is non-negative numeric", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  expect_true(is.numeric(res$overdispersion))
  expect_true(res$overdispersion >= 0)
})

test_that("poisson_model: aic and bic are finite numerics", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  expect_true(is.finite(res$aic))
  expect_true(is.finite(res$bic))
})

test_that("poisson_model: convergence list has expected shape", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  expect_named(res$convergence, c("converged", "singular", "messages"),
               ignore.order = TRUE)
  expect_true(is.logical(res$convergence$converged))
  expect_true(is.logical(res$convergence$singular))
})

test_that("poisson_model: multiple predictors included in formula", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", c("insurance", "gender"), "physician"
  ))
  f <- deparse(res$formula)
  expect_true(grepl("insurance", f))
  expect_true(grepl("gender",    f))
})

test_that("poisson_model: print method runs without error", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  expect_output(print(res), "Poisson GLMER")
  expect_output(print(res), "Fixed effects")
})

test_that("poisson_model: model object is a glmerMod", {
  skip_if_not_installed("lme4")
  res <- suppressWarnings(mysterycall_poisson_model(
    mock, "wait_days", "insurance", "physician"
  ))
  expect_s4_class(res$model, "glmerMod")
})
