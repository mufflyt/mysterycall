make_ins_data <- function(seed = 42, n = 20) {
  set.seed(seed)
  data.frame(
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = n),
    business_days_until_appointment = c(
      rpois(n, 21), rpois(n, 10)
    ),
    stringsAsFactors = FALSE
  )
}

test_that("returns named list with all required elements", {
  df  <- make_ins_data()
  res <- mysterycall_insurance_wait_sentence(df)
  expected_keys <- c("sentence", "irr", "ci_lower", "ci_upper",
                     "p_value", "pct_diff", "medicaid_stats", "bcbs_stats")
  expect_true(all(expected_keys %in% names(res)))
})

test_that("sentence is non-empty character scalar", {
  df  <- make_ins_data()
  res <- mysterycall_insurance_wait_sentence(df)
  expect_type(res$sentence, "character")
  expect_gt(nchar(res$sentence), 0L)
})

test_that("IRR matches manual glm computation", {
  df <- make_ins_data()
  res <- mysterycall_insurance_wait_sentence(df)

  ins_fac  <- relevel(factor(df$insurance), ref = "Blue Cross/Blue Shield")
  fit_man  <- glm(df$business_days_until_appointment ~ ins_fac,
                  family = poisson(link = "log"))
  irr_man  <- round(unname(exp(coef(fit_man)["ins_facMedicaid"])), 2)

  expect_equal(res$irr, irr_man)
})

test_that("pct_diff equals round((irr-1)*100, 1)", {
  df  <- make_ins_data()
  res <- mysterycall_insurance_wait_sentence(df)
  expect_equal(res$pct_diff, round((res$irr - 1) * 100, 1))
})

test_that("sentence contains IRR value", {
  df  <- make_ins_data()
  res <- mysterycall_insurance_wait_sentence(df)
  expect_match(res$sentence, as.character(res$irr))
})

test_that("sentence contains 'longer' when Medicaid > BCBS", {
  # Medicaid has higher wait (lambda=21 vs 10)
  df  <- make_ins_data()
  res <- mysterycall_insurance_wait_sentence(df)
  if (res$irr > 1) {
    expect_match(res$sentence, "longer")
  } else {
    expect_match(res$sentence, "shorter")
  }
})

test_that("medicaid_stats median matches manual computation", {
  df  <- make_ins_data()
  res <- mysterycall_insurance_wait_sentence(df)
  med_m_vals <- df$business_days_until_appointment[df$insurance == "Medicaid"]
  expect_equal(res$medicaid_stats$median, round(median(med_m_vals), 0))
})

test_that("bcbs_stats median matches manual computation", {
  df  <- make_ins_data()
  res <- mysterycall_insurance_wait_sentence(df)
  med_b_vals <- df$business_days_until_appointment[df$insurance == "Blue Cross/Blue Shield"]
  expect_equal(res$bcbs_stats$median, round(median(med_b_vals), 0))
})

test_that("error on missing outcome column", {
  df <- data.frame(
    insurance = c("Medicaid", "Blue Cross/Blue Shield"),
    wrong_col = 1:2,
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_insurance_wait_sentence(df),
    "missing"
  )
})

test_that("error on missing insurance column", {
  df <- data.frame(
    business_days_until_appointment = 1:4,
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_insurance_wait_sentence(df),
    "missing"
  )
})

test_that("error on wrong bcbs_label (not in data)", {
  df <- make_ins_data()
  expect_error(
    mysterycall_insurance_wait_sentence(df, bcbs_label = "Aetna"),
    "not found"
  )
})

test_that("error on wrong medicaid_label (not in data)", {
  df <- make_ins_data()
  expect_error(
    mysterycall_insurance_wait_sentence(df, medicaid_label = "Tricare"),
    "not found"
  )
})

test_that("filter_positive changes bcbs_stats median", {
  df <- make_ins_data()
  # Add some zeros to BCBS
  df$business_days_until_appointment[df$insurance == "Blue Cross/Blue Shield"][1:3] <- 0
  res_all <- mysterycall_insurance_wait_sentence(df, filter_positive = FALSE)
  res_pos <- mysterycall_insurance_wait_sentence(df, filter_positive = TRUE)
  # With zeros filtered, BCBS median should be >= without filter
  expect_gte(res_pos$bcbs_stats$median, res_all$bcbs_stats$median)
})

test_that("non-default labels work correctly", {
  df <- data.frame(
    payer = rep(c("MC", "BCBS"), each = 10),
    days  = c(rpois(10, 20), rpois(10, 10)),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_insurance_wait_sentence(
    df,
    outcome_col    = "days",
    insurance_col  = "payer",
    medicaid_label = "MC",
    bcbs_label     = "BCBS"
  )
  expect_match(res$sentence, "MC")
  expect_match(res$sentence, "BCBS")
})

test_that("ci_lower < irr < ci_upper", {
  df  <- make_ins_data()
  res <- mysterycall_insurance_wait_sentence(df)
  expect_lt(res$ci_lower, res$irr)
  expect_gt(res$ci_upper, res$irr)
})

test_that("p_value is between 0 and 1", {
  df  <- make_ins_data()
  res <- mysterycall_insurance_wait_sentence(df)
  expect_gte(res$p_value, 0)
  expect_lte(res$p_value, 1)
})

test_that("error on non-data-frame input", {
  expect_error(
    mysterycall_insurance_wait_sentence(list(a = 1)),
    "data.frame"
  )
})
