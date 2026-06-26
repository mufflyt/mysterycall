skip_if_not_installed("lme4")

# ── Shared fixture ─────────────────────────────────────────────────────────────
# Realistic: business_days is derived from the same dates, so it's correlated
# with calendar_days and ~5/7 the magnitude.
set.seed(2025)
n <- 60
cal <- round(abs(rnorm(n, mean = 28, sd = 10)))
biz <- round(cal * 5 / 7 * abs(rnorm(n, mean = 1, sd = 0.05)))

sens_df <- data.frame(
  wait_days     = cal,
  business_days = biz,
  scenario      = rep(c("Straight", "Lesbian", "Single"), length.out = n),
  practice      = rep(paste0("P", 1:20), length.out = n),
  stringsAsFactors = FALSE
)

make_res <- function(...) {
  suppressMessages(suppressWarnings(
    mysterycall_calendar_sensitivity(
      sens_df,
      calendar_col     = "wait_days",
      business_col     = "business_days",
      predictors       = "scenario",
      random_intercept = "practice",
      ref_label        = "Straight couple",
      supp_table_num   = "S2",
      ...
    )
  ))
}

# ── Input validation ──────────────────────────────────────────────────────────

test_that("calendar_sensitivity: stops when data is not a data frame", {
  expect_error(
    mysterycall_calendar_sensitivity(list(), "wait_days", "business_days",
                                     "scenario", "practice"),
    "data frame"
  )
})

test_that("calendar_sensitivity: stops when calendar_col not found", {
  expect_error(make_res() |> invisible(),    # baseline doesn't error
               NA)                            # no error expected
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_calendar_sensitivity(
        sens_df, "no_col", "business_days", "scenario", "practice"
      )
    )),
    "no_col"
  )
})

test_that("calendar_sensitivity: stops when business_col not found", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_calendar_sensitivity(
        sens_df, "wait_days", "no_col", "scenario", "practice"
      )
    )),
    "no_col"
  )
})

test_that("calendar_sensitivity: stops when outcome column is not numeric", {
  df_bad <- sens_df
  df_bad$wait_days <- as.character(df_bad$wait_days)
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_calendar_sensitivity(
        df_bad, "wait_days", "business_days", "scenario", "practice"
      )
    )),
    "numeric"
  )
})

# ── Return structure ──────────────────────────────────────────────────────────

test_that("calendar_sensitivity: returns correct class", {
  res <- make_res()
  expect_s3_class(res, "mysterycall_calendar_sensitivity")
})

test_that("calendar_sensitivity: returns all expected fields", {
  res <- make_res()
  expected <- c("calendar_lmm", "business_lmm", "comparison_table",
                "summary_table", "n_calendar", "n_business",
                "all_consistent", "paragraph", "docx_path")
  for (f in expected) {
    expect_true(f %in% names(res), info = paste("missing field:", f))
  }
})

test_that("calendar_sensitivity: sub-models are mysterycall_lmm objects", {
  res <- make_res()
  expect_s3_class(res$calendar_lmm, "mysterycall_lmm")
  expect_s3_class(res$business_lmm, "mysterycall_lmm")
})

test_that("calendar_sensitivity: n_calendar and n_business match sub-model n", {
  res <- make_res()
  expect_equal(res$n_calendar, res$calendar_lmm$n)
  expect_equal(res$n_business, res$business_lmm$n)
})

# ── comparison_table correctness ──────────────────────────────────────────────

test_that("calendar_sensitivity: comparison_table has required columns", {
  res <- make_res()
  expected_cols <- c("term", "cal_est", "cal_ci_lo", "cal_ci_hi", "cal_p",
                     "biz_est", "biz_ci_lo", "biz_ci_hi", "biz_p",
                     "direction_consistent", "magnitude_ratio")
  expect_true(all(expected_cols %in% names(res$comparison_table)),
              info = paste("missing:", paste(setdiff(expected_cols, names(res$comparison_table)), collapse = ", ")))
})

test_that("calendar_sensitivity: comparison_table excludes intercept term", {
  res <- make_res()
  expect_false("(Intercept)" %in% res$comparison_table$term)
})

test_that("calendar_sensitivity: direction_consistent is logical", {
  res <- make_res()
  expect_type(res$comparison_table$direction_consistent, "logical")
})

test_that("calendar_sensitivity: magnitude_ratio is positive for correlated outcomes", {
  res <- make_res()
  # For realistically derived business_days, ratios should be positive
  valid_ratios <- res$comparison_table$magnitude_ratio[
    !is.na(res$comparison_table$magnitude_ratio)
  ]
  if (length(valid_ratios)) {
    expect_true(all(valid_ratios > 0),
                info = "business_days derived from calendar_days should give positive ratios")
  }
})

test_that("calendar_sensitivity: all_consistent reflects comparison_table", {
  res <- make_res()
  expect_equal(
    res$all_consistent,
    all(res$comparison_table$direction_consistent)
  )
})

# ── summary_table ─────────────────────────────────────────────────────────────

test_that("calendar_sensitivity: summary_table has Term, Calendar days, Business days, Consistent", {
  res <- make_res()
  expect_true(all(c("Term", "Calendar days", "Business days", "Consistent") %in%
                    names(res$summary_table)))
})

test_that("calendar_sensitivity: summary_table Consistent column contains only Yes/No", {
  res <- make_res()
  expect_true(all(res$summary_table$Consistent %in% c("Yes", "No")))
})

# ── paragraph ─────────────────────────────────────────────────────────────────

test_that("calendar_sensitivity: paragraph is a non-empty string", {
  res <- make_res()
  expect_type(res$paragraph, "character")
  expect_true(nzchar(res$paragraph))
})

test_that("calendar_sensitivity: paragraph contains sample sizes", {
  res <- make_res()
  expect_match(res$paragraph, as.character(res$n_calendar))
  expect_match(res$paragraph, as.character(res$n_business))
})

test_that("calendar_sensitivity: paragraph embeds supp_table_num", {
  res <- make_res()
  expect_match(res$paragraph, "S2")
})

test_that("calendar_sensitivity: paragraph contains ref_label when supplied", {
  res <- make_res()
  expect_match(res$paragraph, "Straight couple")
})

test_that("calendar_sensitivity: paragraph omits ref_label phrase when ref_label is NULL", {
  res <- suppressMessages(suppressWarnings(
    mysterycall_calendar_sensitivity(
      sens_df, "wait_days", "business_days", "scenario", "practice"
    )
  ))
  expect_false(grepl("compared with", res$paragraph))
})

test_that("calendar_sensitivity: magnitude ratio note absent when ratios implausible", {
  # Use independent random columns to produce implausible ratios
  df_rand <- sens_df
  set.seed(99)
  df_rand$business_days <- round(abs(rnorm(n, 40, 15)))   # larger than calendar days
  res <- suppressMessages(suppressWarnings(
    mysterycall_calendar_sensitivity(
      df_rand, "wait_days", "business_days", "scenario", "practice"
    )
  ))
  # Ratio > 1.5 → note should be suppressed
  expect_false(grepl("5/7 weekday fraction", res$paragraph))
})

# ── print method ──────────────────────────────────────────────────────────────

test_that("calendar_sensitivity: print produces expected header", {
  res <- make_res()
  out <- capture.output(print(res))
  expect_true(any(grepl("Calendar vs. Business Days", out)))
})

test_that("calendar_sensitivity: print shows Yes/No consistent column", {
  res <- make_res()
  out <- capture.output(print(res))
  expect_true(any(grepl("Yes|No", out)))
})

test_that("calendar_sensitivity: print shows paragraph section", {
  res <- make_res()
  out <- capture.output(print(res))
  expect_true(any(grepl("Supplemental paragraph", out)))
})

test_that("calendar_sensitivity: print returns invisible(x)", {
  res <- make_res()
  ret <- withVisible(print(res))
  expect_false(ret$visible)
})
