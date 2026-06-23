suppressPackageStartupMessages({
  pkgload::load_all("/Users/tylermuffly/mysterycall", quiet = TRUE)
})

# ── shared helpers ────────────────────────────────────────────────────────────

.make_poi_model <- function(has_ci = TRUE, has_n_dropped = TRUE) {
  irr <- data.frame(
    term      = c("(Intercept)", "insuranceMedicaid"),
    irr       = c(1.00, 1.28),
    ci_lower  = c(NA,   if (has_ci) 1.05 else NA_real_),
    ci_upper  = c(NA,   if (has_ci) 1.56 else NA_real_),
    p_value   = c(NA,   0.014),
    stringsAsFactors = FALSE
  )
  structure(
    list(irr_table = irr, overdispersion = 1.3,
         n_dropped = if (has_n_dropped) 4L else NULL,
         model = NULL, aic = 120.5, bic = 125.3),
    class = "mysterycall_poisson_model"
  )
}

.make_nb_model_fake <- function() {
  irr <- data.frame(
    term      = c("(Intercept)", "insuranceMedicaid"),
    irr       = c(1.00, 1.28),
    ci_lower  = c(NA,   1.05),
    ci_upper  = c(NA,   1.56),
    p_value   = c(NA,   0.014),
    stringsAsFactors = FALSE
  )
  structure(
    list(irr_table = irr, overdispersion = 2.8, theta = 1.5,
         n_dropped = 4L, model = NULL, aic = 118.3, bic = 124.1),
    class = "mysterycall_nb_model"
  )
}

.irr_df <- function() {
  data.frame(
    term      = c("insuranceMedicaid", "insuranceUninsured"),
    irr       = c(1.28, 0.81),
    ci_lower  = c(1.05, 0.61),
    ci_upper  = c(1.56, 1.07),
    p_value   = c(0.014, 0.134),
    stringsAsFactors = FALSE
  )
}

# ── Block 1: combined_results_table — adversarial ────────────────────────────

test_that("list() input rejects with class mention", {
  expect_error(
    mysterycall_combined_results_table(list(x = 1)),
    regexp = "mysterycall_poisson_model"
  )
})

test_that("data frame missing irr column rejects", {
  bad <- data.frame(term = "a", ci_lower = 1, ci_upper = 2, p_value = 0.1,
                    stringsAsFactors = FALSE)
  expect_error(
    mysterycall_combined_results_table(bad),
    regexp = "missing"
  )
})

test_that("data frame missing ci_lower column rejects", {
  bad <- data.frame(term = "a", irr = 1.1, ci_upper = 2, p_value = 0.1,
                    stringsAsFactors = FALSE)
  expect_error(
    mysterycall_combined_results_table(bad),
    regexp = "missing"
  )
})

test_that("baseline_mean = 0 rejects", {
  expect_error(
    mysterycall_combined_results_table(.irr_df(), baseline_mean = 0),
    regexp = "positive"
  )
})

test_that("baseline_mean = -10 rejects", {
  expect_error(
    mysterycall_combined_results_table(.irr_df(), baseline_mean = -10),
    regexp = "positive"
  )
})

test_that("baseline_mean = 'twenty' rejects", {
  expect_error(
    mysterycall_combined_results_table(.irr_df(), baseline_mean = "twenty"),
    regexp = "positive"
  )
})

test_that("baseline_mean = c(1, 2) rejects as non-scalar", {
  expect_error(
    mysterycall_combined_results_table(.irr_df(), baseline_mean = c(1, 2)),
    regexp = "positive"
  )
})

test_that("intercept-only data frame with include_intercept=FALSE rejects", {
  intercept_only <- data.frame(
    term     = "(Intercept)",
    irr      = 1.0,
    ci_lower = NA_real_,
    ci_upper = NA_real_,
    p_value  = NA_real_,
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_combined_results_table(intercept_only, include_intercept = FALSE),
    regexp = "No rows"
  )
})

# ── Block 2: combined_results_table — negative control ───────────────────────

test_that("baseline_mean = NULL gives has_days attribute FALSE", {
  res <- mysterycall_combined_results_table(.irr_df())
  expect_false(attr(res, "has_days"))
})

test_that("baseline_mean = NULL gives all-NA Days Diff column", {
  res <- mysterycall_combined_results_table(.irr_df())
  expect_true(all(is.na(res[["Days Diff"]])))
})

test_that("include_intercept = FALSE excludes intercept row", {
  res <- mysterycall_combined_results_table(.make_poi_model(), include_intercept = FALSE)
  expect_false("(Intercept)" %in% res$Term)
})

test_that("include_intercept = TRUE includes intercept row", {
  res <- mysterycall_combined_results_table(.make_poi_model(), include_intercept = TRUE)
  expect_true("(Intercept)" %in% res$Term)
})

test_that("Significance is '*' for p<0.05 and '' for p>=0.05", {
  res <- mysterycall_combined_results_table(.irr_df())
  sig_vals <- res$Significance[match(c("insuranceMedicaid", "insuranceUninsured"), res$Term)]
  expect_equal(sig_vals, c("*", ""))
})

test_that("significant_rows attribute identifies only p<0.05 rows", {
  res <- mysterycall_combined_results_table(.irr_df())
  sig_rows <- attr(res, "significant_rows")
  expect_type(sig_rows, "integer")
  expect_equal(length(sig_rows), 1L)
  expect_equal(res$Term[sig_rows], "insuranceMedicaid")
})

test_that("all-IRR-1.0 with baseline gives Days Diff of +0.0", {
  flat_df <- data.frame(
    term     = c("groupA", "groupB"),
    irr      = c(1.0, 1.0),
    ci_lower = c(0.9, 0.9),
    ci_upper = c(1.1, 1.1),
    p_value  = c(0.8, 0.9),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_combined_results_table(flat_df, baseline_mean = 21)
  expect_true(all(res[["Days Diff"]] == "+0.0", na.rm = TRUE))
})

test_that("exposure_col filter produces non-NA Days Diff for matching rows", {
  res <- mysterycall_combined_results_table(
    .irr_df(),
    baseline_mean = 21,
    exposure_col  = "insurance"
  )
  expect_false(all(is.na(res[["Days Diff"]])))
  expect_true(attr(res, "has_days"))
})

# ── Block 3: results_report — adversarial ────────────────────────────────────

test_that("non-model list input rejects with class mention", {
  expect_error(
    mysterycall_results_report(list(x = 1)),
    regexp = "mysterycall_poisson_model"
  )
})

test_that("baseline_mean = 0 rejects", {
  expect_error(
    mysterycall_results_report(.make_poi_model(), baseline_mean = 0),
    regexp = "positive"
  )
})

test_that("baseline_mean = 'x' rejects", {
  expect_error(
    mysterycall_results_report(.make_poi_model(), baseline_mean = "x"),
    regexp = "positive"
  )
})

test_that("exposure_col = c('a','b') rejects as non-scalar", {
  expect_error(
    mysterycall_results_report(.make_poi_model(), exposure_col = c("a", "b")),
    regexp = "single character"
  )
})

test_that("data = 'not a data frame' rejects", {
  expect_error(
    mysterycall_results_report(.make_poi_model(), data = "not a data frame"),
    regexp = "data frame"
  )
})

# ── Block 4: results_report — negative control ───────────────────────────────

test_that("data = NULL gives NULL acceptance", {
  res <- suppressWarnings(mysterycall_results_report(.make_poi_model()))
  expect_null(res$acceptance)
})

test_that("output_path = NULL gives NULL docx_path", {
  res <- suppressWarnings(mysterycall_results_report(.make_poi_model()))
  expect_null(res$docx_path)
})

test_that("exposure_col = NULL gives NULL paragraph", {
  res <- suppressWarnings(mysterycall_results_report(.make_poi_model(), exposure_col = NULL))
  expect_null(res$paragraph)
})

test_that("exposure_col = NULL gives NULL irr_days", {
  res <- suppressWarnings(
    mysterycall_results_report(.make_poi_model(), baseline_mean = 21, exposure_col = NULL)
  )
  expect_null(res$irr_days)
})

test_that("returned object has class mysterycall_results_report", {
  res <- suppressWarnings(mysterycall_results_report(.make_poi_model()))
  expect_s3_class(res, "mysterycall_results_report")
})

test_that("returned object contains all six named elements", {
  res <- suppressWarnings(mysterycall_results_report(.make_poi_model()))
  expect_named(res,
    c("combined_table", "irr_days", "paragraph", "day_sentences", "acceptance", "docx_path"),
    ignore.order = FALSE
  )
})

test_that("invalid group_col warns but does not error", {
  dummy_data <- data.frame(
    contact_office = c(1L, 0L, 1L),
    insurance      = c("Medicaid", "BCBS", "Medicaid"),
    stringsAsFactors = FALSE
  )
  expect_warning(
    mysterycall_results_report(
      .make_poi_model(),
      data      = dummy_data,
      group_col = "nonexistent_col"
    ),
    regexp = "nonexistent_col"
  )
})

# ── Block 5: export_results_docx — adversarial ───────────────────────────────

test_that("character table input rejects", {
  expect_error(
    mysterycall_export_results_docx("not a df"),
    regexp = "data frame"
  )
})

test_that("numeric table input rejects", {
  expect_error(
    mysterycall_export_results_docx(42),
    regexp = "data frame"
  )
})

test_that("output_path without .docx extension warns", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("officer")
  tmp <- tempfile(fileext = ".xlsx")
  # officer itself errors on non-.docx paths; swallow that so we can confirm
  # the upstream warning fires first
  expect_warning(
    tryCatch(
      mysterycall_export_results_docx(.irr_df(), output_path = tmp),
      error = function(e) NULL
    ),
    regexp = "\\.docx"
  )
})
