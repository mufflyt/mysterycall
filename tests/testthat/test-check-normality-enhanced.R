test_that("check_normality returns interpretation for count data", {
  set.seed(7)
  df <- data.frame(days = rpois(150, 10))
  res <- suppressMessages(
    mysterycall_check_normality(df, "days",
                                outcome_label = "days until appointment",
                                group_label   = "insurance type")
  )
  expect_true(res$is_count)
  expect_false(res$is_normal)
  expect_true(grepl("Poisson", res$interpretation))
  expect_true(grepl("IRR", res$interpretation))
  expect_true(grepl("count data", res$interpretation))
  expect_true("median" %in% names(res))
  expect_true("iqr"    %in% names(res))
  expect_type(res$p_value, "double")
  expect_type(res$w_statistic, "double")
})

test_that("check_normality returns interpretation for continuous data", {
  set.seed(11)
  df <- data.frame(x = rnorm(200, mean = 5, sd = 1))
  res <- suppressMessages(
    mysterycall_check_normality(df, "x")
  )
  expect_false(res$is_count)
  expect_true(res$is_normal)
  expect_true(grepl("normally distributed", res$interpretation))
  expect_true("mean" %in% names(res))
  expect_true("sd"   %in% names(res))
})

test_that("check_normality non-normal continuous (no Poisson recommendation)", {
  set.seed(3)
  df <- data.frame(x = rexp(100, rate = 0.1))
  res <- suppressMessages(
    mysterycall_check_normality(df, "x")
  )
  expect_false(res$is_count)
  expect_false(res$is_normal)
  expect_false(grepl("Poisson", res$interpretation))
  expect_true(grepl("non-parametric", res$interpretation, ignore.case = TRUE))
})

test_that("check_normality errors on unknown variable", {
  df <- data.frame(a = 1:10)
  expect_error(mysterycall_check_normality(df, "z"), "not found")
})

test_that("mysterycall_simple_poisson returns IRR table and statement", {
  skip_if_not_installed("stats")
  set.seed(42)
  df <- data.frame(
    days      = rpois(120, 12),
    insurance = rep(c("BCBS", "Medicaid", "Medicare"), 40)
  )
  res <- suppressMessages(
    mysterycall_simple_poisson(df, "days", "insurance",
                               reference = "BCBS",
                               outcome_label = "business days until appointment",
                               use_profile_ci = FALSE)
  )
  expect_s3_class(res, "mysterycall_simple_poisson")
  expect_equal(res$reference, "BCBS")
  expect_equal(nrow(res$irr_table), 2L)
  expect_true(all(c("irr", "ci_lower", "ci_upper", "p_value_fmt", "direction") %in%
                    names(res$irr_table)))
  expect_true(all(res$irr_table$irr > 0))
  expect_true(grepl("Poisson", res$summary_statement))
  expect_true(grepl("Kruskal-Wallis", res$summary_statement))
  expect_true(grepl("BCBS", res$summary_statement))
  expect_type(res$dispersion, "double")
  expect_true(res$n == 120L)
})

test_that("mysterycall_simple_poisson respects reference level", {
  set.seed(5)
  df <- data.frame(
    wait = rpois(60, 8),
    ins  = rep(c("A", "B", "C"), 20)
  )
  res <- suppressMessages(
    mysterycall_simple_poisson(df, "wait", "ins", reference = "B",
                               use_profile_ci = FALSE)
  )
  expect_equal(res$reference, "B")
  expect_true(all(!grepl("^insB", res$irr_table$term)))
})

test_that("mysterycall_simple_poisson errors on bad inputs", {
  df <- data.frame(y = rpois(20, 5), g = letters[1:20])
  expect_error(mysterycall_simple_poisson(df, "missing", "g"), "not found")
  expect_error(mysterycall_simple_poisson(df, "y", "missing"), "not found")
})
