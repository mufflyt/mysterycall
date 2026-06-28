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

test_that("mysterycall_insurance_wait_sentence returns expected structure", {
  set.seed(42)
  df <- data.frame(
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = 20),
    business_days_until_appointment = c(rpois(20, 21), rpois(20, 10)),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_insurance_wait_sentence(df))

  expect_type(res, "list")
  expect_named(res, c("sentence", "irr", "ci_lower", "ci_upper", "p_value",
                      "pct_diff", "medicaid_stats", "bcbs_stats"))
  expect_character(res$sentence, len = 1)
  expect_type(res$irr, "double")
  expect_type(res$ci_lower, "double")
  expect_type(res$ci_upper, "double")
  expect_type(res$p_value, "double")
  expect_type(res$pct_diff, "double")
  expect_type(res$medicaid_stats, "list")
  expect_type(res$bcbs_stats, "list")
})

test_that("mysterycall_insurance_wait_sentence works with custom column names", {
  set.seed(42)
  df <- data.frame(
    ins_type = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = 20),
    wait_time = c(rpois(20, 21), rpois(20, 10)),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_insurance_wait_sentence(
    df,
    outcome_col = "wait_time",
    insurance_col = "ins_type"
  ))

  expect_character(res$sentence)
  expect_true(nchar(res$sentence) > 0)
  expect_true(grepl("Medicaid", res$sentence))
  expect_true(grepl("Blue Cross/Blue Shield", res$sentence))
})

test_that("mysterycall_insurance_wait_sentence works with custom labels", {
  set.seed(42)
  df <- data.frame(
    insurance = rep(c("MA", "PPO"), each = 20),
    business_days_until_appointment = c(rpois(20, 21), rpois(20, 10)),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_insurance_wait_sentence(
    df,
    medicaid_label = "MA",
    bcbs_label = "PPO"
  ))

  expect_character(res$sentence)
  expect_true(grepl("MA", res$sentence))
  expect_true(grepl("PPO", res$sentence))
})

test_that("mysterycall_insurance_wait_sentence respects digits parameters", {
  set.seed(42)
  df <- data.frame(
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = 20),
    business_days_until_appointment = c(rpois(20, 21), rpois(20, 10)),
    stringsAsFactors = FALSE
  )

  res_0 <- suppressMessages(mysterycall_insurance_wait_sentence(
    df,
    digits_irr = 0,
    digits_pct = 0,
    digits_median = 0
  ))

  res_3 <- suppressMessages(mysterycall_insurance_wait_sentence(
    df,
    digits_irr = 3,
    digits_pct = 2,
    digits_median = 1
  ))

  expect_type(res_0$irr, "double")
  expect_type(res_3$irr, "double")
  expect_true(res_0$irr >= 0)
  expect_true(res_3$irr >= 0)
})

test_that("mysterycall_insurance_wait_sentence filters positive values when requested", {
  set.seed(42)
  df <- data.frame(
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = 20),
    business_days_until_appointment = c(
      c(0, 1, 2, 3, rpois(16, 21)),  # Medicaid with 0 values
      rpois(20, 10)                  # BCBS
    ),
    stringsAsFactors = FALSE
  )

  res_all <- suppressMessages(mysterycall_insurance_wait_sentence(
    df,
    filter_positive = FALSE
  ))

  res_pos <- suppressMessages(mysterycall_insurance_wait_sentence(
    df,
    filter_positive = TRUE
  ))

  expect_type(res_all$sentence, "character")
  expect_type(res_pos$sentence, "character")
})

test_that("mysterycall_insurance_wait_sentence errors on missing outcome column", {
  set.seed(42)
  df <- data.frame(
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = 20),
    wait_time = c(rpois(20, 21), rpois(20, 10)),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_insurance_wait_sentence(df)),
    "business_days_until_appointment"
  )
})

test_that("mysterycall_insurance_wait_sentence errors on missing insurance column", {
  set.seed(42)
  df <- data.frame(
    ins_type = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = 20),
    business_days_until_appointment = c(rpois(20, 21), rpois(20, 10)),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_insurance_wait_sentence(df)),
    "insurance"
  )
})

test_that("mysterycall_insurance_wait_sentence errors on missing medicaid label", {
  set.seed(42)
  df <- data.frame(
    insurance = rep(c("MA", "Blue Cross/Blue Shield"), each = 20),
    business_days_until_appointment = c(rpois(20, 21), rpois(20, 10)),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_insurance_wait_sentence(df, medicaid_label = "Medicaid")),
    "Medicaid label"
  )
})

test_that("mysterycall_insurance_wait_sentence errors on missing bcbs label", {
  set.seed(42)
  df <- data.frame(
    insurance = rep(c("Medicaid", "PPO"), each = 20),
    business_days_until_appointment = c(rpois(20, 21), rpois(20, 10)),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_insurance_wait_sentence(df, bcbs_label = "Blue Cross/Blue Shield")),
    "BCBS label"
  )
})

test_that("mysterycall_insurance_wait_sentence errors on wrong data type", {
  expect_error(
    suppressMessages(mysterycall_insurance_wait_sentence("not a data frame")),
    "data.frame"
  )
})

test_that("mysterycall_insurance_wait_sentence handles NA values gracefully", {
  set.seed(42)
  df <- data.frame(
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = 20),
    business_days_until_appointment = c(
      c(NA, rpois(19, 21)),
      c(rpois(19, 10), NA)
    ),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_insurance_wait_sentence(df))

  expect_type(res$sentence, "character")
  expect_type(res$irr, "double")
})

test_that("mysterycall_insurance_wait_sentence works with minimal data", {
  set.seed(42)
  df <- data.frame(
    insurance = c("Medicaid", "Medicaid", "Blue Cross/Blue Shield", "Blue Cross/Blue Shield"),
    business_days_until_appointment = c(5L, 10L, 3L, 7L),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_insurance_wait_sentence(df))

  expect_type(res$sentence, "character")
  expect_true(nchar(res$sentence) > 0)
})

test_that("mysterycall_insurance_wait_sentence medicaid_stats contains expected names", {
  set.seed(42)
  df <- data.frame(
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = 20),
    business_days_until_appointment = c(rpois(20, 21), rpois(20, 10)),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_insurance_wait_sentence(df))

  expect_named(res$medicaid_stats, c("median", "q1", "q3"))
  expect_named(res$bcbs_stats, c("median", "q1", "q3"))
  expect_type(res$medicaid_stats$median, "double")
  expect_type(res$medicaid_stats$q1, "double")
  expect_type(res$medicaid_stats$q3, "double")
})

test_that("mysterycall_insurance_wait_sentence p_value is numeric and in valid range", {
  set.seed(42)
  df <- data.frame(
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = 20),
    business_days_until_appointment = c(rpois(20, 21), rpois(20, 10)),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_insurance_wait_sentence(df))

  expect_type(res$p_value, "double")
  expect_true(res$p_value >= 0 && res$p_value <= 1)
})

test_that("mysterycall_insurance_wait_sentence IRR is positive", {
  set.seed(42)
  df <- data.frame(
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = 20),
    business_days_until_appointment = c(rpois(20, 21), rpois(20, 10)),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_insurance_wait_sentence(df))

  expect_true(res$irr > 0)
  expect_true(res$ci_lower > 0)
  expect_true(res$ci_upper > 0)
  expect_true(res$ci_lower <= res$irr)
  expect_true(res$irr <= res$ci_upper)
})

test_that("mysterycall_insurance_wait_sentence sentence mentions direction of effect", {
  set.seed(42)
  df <- data.frame(
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = 20),
    business_days_until_appointment = c(rpois(20, 21), rpois(20, 10)),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_insurance_wait_sentence(df))

  expect_true(grepl("longer|shorter", res$sentence))
})
