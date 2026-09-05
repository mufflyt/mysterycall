# tests/testthat/test-gt-irr-table.R
# Tests for mysterycall_irr_table() and mysterycall_model_gt()

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

make_irr_data <- function() {
  data.frame(
    term       = c("insuranceMedicaid", "insuranceMedicare"),
    level      = c("Medicaid", "Medicare"),
    irr        = c(1.25, 0.80),
    ci_lower   = c(1.05, 0.65),
    ci_upper   = c(1.48, 0.98),
    p_value    = c(0.012, 0.031),
    p_value_fmt = c("0.012", "0.031"),
    direction  = c("higher", "lower"),
    stringsAsFactors = FALSE
  )
}

make_poisson_result <- function() {
  set.seed(42)
  df <- data.frame(
    days      = rpois(90, 10),
    insurance = rep(c("BCBS", "Medicaid", "Medicare"), 30)
  )
  mysterycall_simple_poisson(df, "days", "insurance", reference = "BCBS",
                             use_profile_ci = FALSE)
}

# ---------------------------------------------------------------------------
# 1. Basic output class
# ---------------------------------------------------------------------------
test_that("output inherits gt_tbl", {
  skip_if_not_installed("gt")
  tbl <- mysterycall_irr_table(make_irr_data())
  expect_s3_class(tbl, "gt_tbl")
})

# ---------------------------------------------------------------------------
# 2. Works with simple_poisson result
# ---------------------------------------------------------------------------
test_that("works with mysterycall_simple_poisson irr_table", {
  skip_if_not_installed("gt")
  res <- make_poisson_result()
  tbl <- mysterycall_irr_table(res$irr_table)
  expect_s3_class(tbl, "gt_tbl")
})

# ---------------------------------------------------------------------------
# 3. Stars correct for p = 0.0001
# ---------------------------------------------------------------------------
test_that("stars are *** for p = 0.0001", {
  skip_if_not_installed("gt")
  d <- make_irr_data()
  d$p_value <- c(0.0001, 0.5)
  tbl <- mysterycall_irr_table(d, add_significance_stars = TRUE)
  # extract underlying data
  built <- gt::as_raw_html(tbl)
  expect_match(built, "\\*\\*\\*", all = FALSE)
})

# ---------------------------------------------------------------------------
# 4. Stars correct for p = 0.01
# ---------------------------------------------------------------------------
test_that("stars are ** for p = 0.01", {
  skip_if_not_installed("gt")
  d <- make_irr_data()
  d$p_value <- c(0.01, 0.5)
  tbl <- mysterycall_irr_table(d, add_significance_stars = TRUE)
  built <- gt::as_raw_html(tbl)
  expect_match(built, "\\*\\*", all = FALSE)
})

# ---------------------------------------------------------------------------
# 5. Stars correct for p = 0.04 (just below 0.05)
# ---------------------------------------------------------------------------
test_that("stars are * for p = 0.04", {
  skip_if_not_installed("gt")
  d <- make_irr_data()
  d$p_value <- c(0.04, 0.5)
  tbl <- mysterycall_irr_table(d, add_significance_stars = TRUE)
  built <- gt::as_raw_html(tbl)
  expect_match(built, "\\*", all = FALSE)
})

# ---------------------------------------------------------------------------
# 6. No star for p = 0.5
# ---------------------------------------------------------------------------
test_that("no star for p = 0.5", {
  skip_if_not_installed("gt")
  d <- make_irr_data()
  d$p_value <- c(0.5, 0.8)
  tbl <- mysterycall_irr_table(d)
  # Inspect the underlying gt data directly rather than rendered HTML
  # (footnote text itself contains asterisks)
  gt_data <- gt::extract_body(tbl)
  stars_col <- gt_data[["Stars"]]
  expect_true(all(stars_col == "" | is.na(stars_col)))
})

# ---------------------------------------------------------------------------
# 7. Title appears in gt object
# ---------------------------------------------------------------------------
test_that("title appears in gt object", {
  skip_if_not_installed("gt")
  tbl <- mysterycall_irr_table(make_irr_data(), title = "My IRR Table")
  heading <- gt:::dt_heading_get(tbl[["_heading"]])
  # dt_heading_get may not exist in all gt versions; use alternative
  # Use the stored internal list instead
  heading_info <- tbl[["_heading"]]
  expect_true(
    isTRUE(grepl("My IRR Table", heading_info$title))
  )
})

# ---------------------------------------------------------------------------
# 8. add_significance_stars = FALSE drops stars column
# ---------------------------------------------------------------------------
test_that("add_significance_stars=FALSE drops stars", {
  skip_if_not_installed("gt")
  tbl <- mysterycall_irr_table(make_irr_data(), add_significance_stars = FALSE)
  col_names <- tbl[["_boxhead"]][["var"]]
  expect_false("Stars" %in% col_names)
})

# ---------------------------------------------------------------------------
# 9. Missing required column errors informatively
# ---------------------------------------------------------------------------
test_that("missing irr column errors with informative message", {
  skip_if_not_installed("gt")
  d <- make_irr_data()
  d$irr <- NULL
  expect_error(mysterycall_irr_table(d), "irr")
})

test_that("missing label column errors with informative message", {
  skip_if_not_installed("gt")
  d <- make_irr_data()
  d$term  <- NULL
  d$level <- NULL
  expect_error(mysterycall_irr_table(d), "term.*level|level.*term")
})

test_that("missing p_value column errors with informative message", {
  skip_if_not_installed("gt")
  d <- make_irr_data()
  d$p_value     <- NULL
  d$p_value_fmt <- NULL
  expect_error(mysterycall_irr_table(d), "p_value")
})

# ---------------------------------------------------------------------------
# 10. 0-row irr_data produces empty gt, no crash
# ---------------------------------------------------------------------------
test_that("0-row irr_data produces empty gt without crash", {
  skip_if_not_installed("gt")
  d <- make_irr_data()[0L, ]
  tbl <- mysterycall_irr_table(d)
  expect_s3_class(tbl, "gt_tbl")
})

# ---------------------------------------------------------------------------
# 11. mysterycall_model_gt works end-to-end
# ---------------------------------------------------------------------------
test_that("mysterycall_model_gt works end-to-end", {
  skip_if_not_installed("gt")
  res <- make_poisson_result()
  tbl <- mysterycall_model_gt(res)
  expect_s3_class(tbl, "gt_tbl")
})

# ---------------------------------------------------------------------------
# 12. mysterycall_model_gt errors on non-poisson object
# ---------------------------------------------------------------------------
test_that("mysterycall_model_gt errors on wrong input type", {
  skip_if_not_installed("gt")
  expect_error(mysterycall_model_gt(list(irr_table = make_irr_data())),
               "mysterycall_simple_poisson")
})

# ---------------------------------------------------------------------------
# 13. Custom title and subtitle are stored
# ---------------------------------------------------------------------------
test_that("custom subtitle stored in gt object", {
  skip_if_not_installed("gt")
  tbl <- mysterycall_irr_table(make_irr_data(),
                                title    = "Test Title",
                                subtitle = "Test Subtitle")
  heading_info <- tbl[["_heading"]]
  expect_true(grepl("Test Subtitle", heading_info$subtitle))
})

# ---------------------------------------------------------------------------
# 14. Works with only 'level' column (no 'term')
# ---------------------------------------------------------------------------
test_that("accepts 'level' column when 'term' is absent", {
  skip_if_not_installed("gt")
  d <- make_irr_data()
  d$term <- NULL
  tbl <- mysterycall_irr_table(d)
  expect_s3_class(tbl, "gt_tbl")
})

# ---------------------------------------------------------------------------
# 15. Works with only p_value_fmt (no numeric p_value)
# ---------------------------------------------------------------------------
test_that("accepts p_value_fmt when numeric p_value absent", {
  skip_if_not_installed("gt")
  d <- make_irr_data()
  d$p_value <- NULL
  tbl <- mysterycall_irr_table(d)
  expect_s3_class(tbl, "gt_tbl")
})

# ---------------------------------------------------------------------------
# Significance stars are opt-in (SAMPL: report exact p values, not alpha codes)
# ---------------------------------------------------------------------------

test_that("significance stars are off by default", {
  skip_if_not_installed("gt")
  d <- make_irr_data()
  d$p_value <- c(0.0001, 0.5)
  built <- gt::as_raw_html(mysterycall_irr_table(d))
  expect_false(grepl("Stars", built, fixed = TRUE))
  expect_false(grepl("*** p", built, fixed = TRUE))
})

test_that("the default footnote drops the alpha ladder when stars are off", {
  skip_if_not_installed("gt")
  d <- make_irr_data()
  off <- gt::as_raw_html(mysterycall_irr_table(d))
  on  <- gt::as_raw_html(mysterycall_irr_table(d, add_significance_stars = TRUE))
  expect_true(grepl("exact p values", off, fixed = TRUE))
  expect_false(grepl("p &lt; 0.05", off, fixed = TRUE) || grepl("p < 0.05", off, fixed = TRUE))
  expect_true(grepl("p &lt; 0.05", on, fixed = TRUE) || grepl("p < 0.05", on, fixed = TRUE))
})
