library(testthat)

AUDIT <- data.frame(
  npi                              = c("1234567893","1234567893","9876543210","9876543210"),
  insurance                        = c("Medicaid","BCBS","Medicaid","BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A","A","B","B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN","OB/GYN","OB/GYN","OB/GYN"),
  phone                            = c("3035550100","3035550100","7205550200","7205550200"),
  physician_information            = c("Smith, John","Smith, John","Doe, Jane","Doe, Jane"),
  reason_for_exclusions            = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid","BCBS"), each = 40L),
  stringsAsFactors = FALSE
)

test_that("Happy path: numeric vector input with default parameters", {
  pvals <- c(0.001, 0.03, 0.2, 0.5, 0.04)
  result <- suppressMessages(suppressWarnings(
    mysterycall_multiple_comparison_adjust(pvals)
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 5L)
  expect_equal(
    names(result),
    c("comparison", "p_raw", "p_adjusted", "significant", "stars")
  )
  expect_equal(result$p_raw, pvals)
  expect_type(result$comparison, "character")
  expect_type(result$significant, "logical")
  expect_type(result$stars, "character")
})

test_that("Happy path: data.frame input with p_col and label_col", {
  df <- data.frame(
    comparison = c("A vs B", "A vs C", "B vs C"),
    p_value    = c(0.01, 0.04, 0.3),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_multiple_comparison_adjust(
      df,
      p_col     = "p_value",
      label_col = "comparison"
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3L)
  expect_equal(result$comparison, c("A vs B", "A vs C", "B vs C"))
  expect_equal(result$p_raw, c(0.01, 0.04, 0.3))
  expect_true(all(result$p_adjusted >= result$p_raw))
})

test_that("Happy path: method variants (bonferroni, holm, BH, BY, fdr alias)", {
  pvals <- c(0.001, 0.01, 0.05, 0.1)

  bonf <- suppressMessages(suppressWarnings(
    mysterycall_multiple_comparison_adjust(pvals, method = "bonferroni")
  ))
  holm <- suppressMessages(suppressWarnings(
    mysterycall_multiple_comparison_adjust(pvals, method = "holm")
  ))
  bh <- suppressMessages(suppressWarnings(
    mysterycall_multiple_comparison_adjust(pvals, method = "BH")
  ))
  by <- suppressMessages(suppressWarnings(
    mysterycall_multiple_comparison_adjust(pvals, method = "BY")
  ))
  fdr <- suppressMessages(suppressWarnings(
    mysterycall_multiple_comparison_adjust(pvals, method = "fdr")
  ))

  expect_s3_class(bonf, "data.frame")
  expect_equal(bonf$p_adjusted, c(0.004, 0.04, 0.2, 0.4))
  expect_equal(fdr$p_adjusted, bh$p_adjusted)
  expect_true(all(holm$p_adjusted <= bonf$p_adjusted))
})

test_that("Edge case: NA p-values are preserved with warning", {
  pvals <- c(0.01, NA, 0.05, 0.5)
  result <- suppressWarnings(
    mysterycall_multiple_comparison_adjust(pvals)
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 4L)
  expect_true(is.na(result$p_adjusted[2]))
  expect_false(result$significant[2])
  expect_true(is.na(result$stars[2]))
})

test_that("Edge case: significance stars boundary values", {
  pvals <- c(0.0005, 0.005, 0.025, 0.051)
  result <- suppressMessages(suppressWarnings(
    mysterycall_multiple_comparison_adjust(pvals, method = "holm")
  ))

  expect_true(all(result$stars %in% c("***", "**", "*", "ns")))
  expect_true(result$p_raw[1] < 0.001)
})

test_that("Edge case: custom alpha threshold", {
  pvals <- c(0.001, 0.01, 0.05, 0.1)

  result_alpha_001 <- suppressMessages(suppressWarnings(
    mysterycall_multiple_comparison_adjust(pvals, alpha = 0.001)
  ))
  result_alpha_05 <- suppressMessages(suppressWarnings(
    mysterycall_multiple_comparison_adjust(pvals, alpha = 0.05)
  ))

  expect_true(sum(result_alpha_001$significant) < sum(result_alpha_05$significant))
})

test_that("Edge case: data.frame with default row names as labels", {
  df <- data.frame(
    p = c(0.01, 0.04, 0.3),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_multiple_comparison_adjust(df, p_col = "p")
  ))

  expect_equal(result$comparison, c("1", "2", "3"))
})

test_that("Edge case: data.frame with custom row names as labels", {
  df <- data.frame(
    p = c(0.01, 0.04, 0.3),
    stringsAsFactors = FALSE
  )
  rownames(df) <- c("Test_A", "Test_B", "Test_C")
  result <- suppressMessages(suppressWarnings(
    mysterycall_multiple_comparison_adjust(df, p_col = "p")
  ))

  expect_equal(result$comparison, c("Test_A", "Test_B", "Test_C"))
})

test_that("Bad input: alpha outside (0, 1)", {
  pvals <- c(0.01, 0.05, 0.1)

  expect_error(
    mysterycall_multiple_comparison_adjust(pvals, alpha = 0),
    "`alpha` must be a single numeric value in \\(0, 1\\)."
  )
  expect_error(
    mysterycall_multiple_comparison_adjust(pvals, alpha = 1),
    "`alpha` must be a single numeric value in \\(0, 1\\)."
  )
  expect_error(
    mysterycall_multiple_comparison_adjust(pvals, alpha = -0.05),
    "`alpha` must be a single numeric value in \\(0, 1\\)."
  )
  expect_error(
    mysterycall_multiple_comparison_adjust(pvals, alpha = 1.5),
    "`alpha` must be a single numeric value in \\(0, 1\\)."
  )
})

test_that("Bad input: alpha is not a single value", {
  pvals <- c(0.01, 0.05, 0.1)

  expect_error(
    mysterycall_multiple_comparison_adjust(pvals, alpha = c(0.01, 0.05)),
    "`alpha` must be a single numeric value in \\(0, 1\\)."
  )
})

test_that("Bad input: x is data.frame but p_col is NULL", {
  df <- data.frame(p = c(0.01, 0.05, 0.1))

  expect_error(
    mysterycall_multiple_comparison_adjust(df, p_col = NULL),
    "When `x` is a data.frame, `p_col` must be specified."
  )
})

test_that("Bad input: p_col not found in data.frame", {
  df <- data.frame(p_value = c(0.01, 0.05, 0.1), stringsAsFactors = FALSE)

  expect_error(
    mysterycall_multiple_comparison_adjust(df, p_col = "nonexistent"),
    "Column 'nonexistent' not found in `x`."
  )
})

test_that("Bad input: label_col not found in data.frame", {
  df <- data.frame(
    p = c(0.01, 0.05, 0.1),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_multiple_comparison_adjust(
      df,
      p_col     = "p",
      label_col = "nonexistent"
    ),
    "Column 'nonexistent' not found in `x`."
  )
})

test_that("Bad input: x is wrong type (list, character, etc.)", {
  expect_error(
    mysterycall_multiple_comparison_adjust(list(a = 0.01, b = 0.05)),
    "`x` must be a numeric vector or a data.frame."
  )

  expect_error(
    mysterycall_multiple_comparison_adjust(c("0.01", "0.05")),
    "`x` must be a numeric vector or a data.frame."
  )
})

test_that("Bad input: p-values outside [0, 1]", {
  pvals_negative <- c(-0.05, 0.01, 0.1)
  pvals_over_one <- c(1.5, 0.01, 0.1)

  expect_error(
    mysterycall_multiple_comparison_adjust(pvals_negative),
    "All p-values must be in \\[0, 1\\]."
  )
  expect_error(
    mysterycall_multiple_comparison_adjust(pvals_over_one),
    "All p-values must be in \\[0, 1\\]."
  )
})

test_that("Bad input: invalid method argument", {
  pvals <- c(0.01, 0.05, 0.1)

  expect_error(
    mysterycall_multiple_comparison_adjust(pvals, method = "invalid_method")
  )
})
