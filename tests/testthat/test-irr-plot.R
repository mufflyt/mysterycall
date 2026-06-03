skip_if_not_installed("lme4")

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
model_res <- suppressWarnings(
  mysterycall_poisson_model(mock, "wait_days", c("insurance", "gender"), "physician")
)

# ── mysterycall_irr_plot ──────────────────────────────────────────────────────

test_that("irr_plot: returns a ggplot object", {
  p <- mysterycall_irr_plot(model_res)
  expect_s3_class(p, "gg")
})

test_that("irr_plot: intercept excluded by default", {
  p    <- mysterycall_irr_plot(model_res)
  data <- ggplot2::layer_data(p)
  # term labels are stored in the plot's data, not layer_data — check scales
  term_labels <- as.character(p$data$term)
  expect_false(any(grepl("Intercept", term_labels, ignore.case = TRUE)))
})

test_that("irr_plot: intercept included when requested", {
  p <- mysterycall_irr_plot(model_res, include_intercept = TRUE)
  term_labels <- as.character(p$data$term)
  expect_true(any(grepl("Intercept", term_labels, ignore.case = TRUE)))
})

test_that("irr_plot: accepts a plain data frame with required columns", {
  df <- data.frame(
    term     = c("A", "B"),
    irr      = c(1.2, 0.8),
    ci_lower = c(1.0, 0.6),
    ci_upper = c(1.5, 1.1),
    stringsAsFactors = FALSE
  )
  expect_s3_class(mysterycall_irr_plot(df), "gg")
})

test_that("irr_plot: data frame missing required columns errors", {
  df <- data.frame(term = "A", irr = 1.2, stringsAsFactors = FALSE)
  expect_error(mysterycall_irr_plot(df), "ci_lower")
})

test_that("irr_plot: non-model non-dataframe input errors", {
  expect_error(mysterycall_irr_plot(list(a = 1)), "data frame")
})

test_that("irr_plot: x_log applies log10 scale", {
  p_log    <- mysterycall_irr_plot(model_res, x_log = TRUE)
  p_linear <- mysterycall_irr_plot(model_res, x_log = FALSE)
  # A log-scale plot has more scales registered than the linear version
  expect_gt(length(p_log$scales$scales), length(p_linear$scales$scales))
})

test_that("irr_plot: title appears when supplied", {
  p <- mysterycall_irr_plot(model_res, title = "Test Title")
  expect_equal(p$labels$title, "Test Title")
})

test_that("irr_plot: custom x_label used", {
  p <- mysterycall_irr_plot(model_res, x_label = "Rate Ratio")
  expect_equal(p$labels$x, "Rate Ratio")
})

# ── mysterycall:::mysterycall_model_table ───────────────────────────────────────────────────

test_that("model_table: returns a data frame", {
  out <- mysterycall:::mysterycall_model_table(model_res)
  expect_s3_class(out, "data.frame")
})

test_that("model_table: excludes intercept by default", {
  out <- mysterycall:::mysterycall_model_table(model_res)
  expect_false(any(grepl("Intercept", out[[1L]], ignore.case = TRUE)))
})

test_that("model_table: includes intercept when requested", {
  out <- mysterycall:::mysterycall_model_table(model_res, include_intercept = TRUE)
  expect_true(any(grepl("Intercept", out[[1L]], ignore.case = TRUE)))
})

test_that("model_table: has exactly 3 columns", {
  out <- mysterycall:::mysterycall_model_table(model_res)
  expect_equal(ncol(out), 3L)
})

test_that("model_table: default column names are correct", {
  out <- mysterycall:::mysterycall_model_table(model_res)
  expect_equal(names(out), c("Term", "IRR (95% CI)", "p-value"))
})

test_that("model_table: custom column names respected", {
  out <- mysterycall:::mysterycall_model_table(model_res,
                                  term_col = "Predictor",
                                  irr_col  = "IRR [CI]",
                                  p_col    = "P")
  expect_equal(names(out), c("Predictor", "IRR [CI]", "P"))
})

test_that("model_table: IRR column contains dash separator", {
  out <- mysterycall:::mysterycall_model_table(model_res)
  # Combined IRR (95% CI) column uses em-dash
  expect_true(all(grepl("–", out[["IRR (95% CI)"]]) | grepl("\\(", out[["IRR (95% CI)"]])))
})

test_that("model_table: p-value column matches p_value_fmt from irr_table", {
  out    <- mysterycall:::mysterycall_model_table(model_res, include_intercept = TRUE)
  n_rows <- nrow(model_res$irr_table)
  expect_equal(nrow(out), n_rows)
  expect_equal(out[["p-value"]], model_res$irr_table$p_value_fmt)
})

test_that("model_table: non-model input errors", {
  expect_error(mysterycall:::mysterycall_model_table(list(a = 1)), "mysterycall_poisson_model")
})

test_that("model_table: negative digits errors", {
  expect_error(mysterycall:::mysterycall_model_table(model_res, digits = -1), "digits")
})
