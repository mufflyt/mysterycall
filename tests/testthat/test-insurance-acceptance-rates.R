# Controlled dataset with known expected values
# Medicaid: phones 1-4; BCBS: phones 5-8
# accepted_col non-NA for all
# Medicaid numerator: phone 1,2 (able + days>0)    => 2
# Medicaid excluded:  phone 4 (not able)            => 1
# Medicaid total:     phones 1-4                    => 4
# Medicaid denom:     4 - 1                         => 3
# Medicaid rate:      round(2/3*100, 1)             => 66.7

# BCBS numerator: phone 5,6 (able + days>0)         => 2
# BCBS excluded:  phone 8 (not able)                => 1
# BCBS total:     phones 5-8                        => 4
# BCBS denom:     4 - 1                             => 3
# BCBS rate:      round(2/3*100, 1)                 => 66.7

df <- data.frame(
  phone                              = paste0("p", 1:8),
  insurance                          = c(rep("Medicaid", 4),
                                         rep("Blue Cross/Blue Shield", 4)),
  reason_for_exclusions              = c("Able to contact", "Able to contact",
                                         "Able to contact", "Not available",
                                         "Able to contact", "Able to contact",
                                         "Able to contact", "Not available"),
  business_days_until_appointment    = c(5L, 3L, 0L, NA_integer_,
                                         7L, 2L, 0L, NA_integer_),
  does_the_physician_accept_medicaid = rep("Yes", 8),
  stringsAsFactors = FALSE
)

test_that("Medicaid numerator is correct", {
  res <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )
  # phones 1 (days=5) and 2 (days=3) — phone 3 has days=0 so excluded from numerator
  expect_equal(res$count_accepts_medicaid, 2L)
})

test_that("Medicaid denominator is correct", {
  res <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )
  expect_equal(res$total_count_medicaid, 4L)
  expect_equal(res$count_medicaid_excluded, 1L)
  expect_equal(res$count_medicaid_denom, 3L)
})

test_that("Medicaid acceptance rate is correct", {
  res <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )
  expected <- round(2 / 3 * 100, 1)
  expect_equal(res$medicaid_acceptance_rate, expected)
})

test_that("BCBS counts are correct", {
  res <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )
  expect_equal(res$count_accepts_bcbs, 2L)
  expect_equal(res$total_count_bcbs, 4L)
  expect_equal(res$count_bcbs_denom, 3L)
})

test_that("paragraph is a non-empty character string", {
  res <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )
  expect_type(res$paragraph, "character")
  expect_true(nchar(res$paragraph) > 0L)
  expect_true(grepl("Medicaid Acceptance Rate", res$paragraph))
  expect_true(grepl("Blue Cross/Blue Shield Acceptance Rate", res$paragraph))
})

test_that("paragraph contains correct rates", {
  res <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )
  expected_rate <- format(round(2 / 3 * 100, 1), nsmall = 1)
  expect_true(grepl(expected_rate, res$paragraph, fixed = TRUE))
})

test_that("summary_sentence contains n/N notation", {
  res <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )
  expect_true(grepl("n =", res$summary_sentence))
  expect_true(grepl("N =", res$summary_sentence))
})

test_that("writes CSV when output_dir supplied", {
  td <- tempfile(); dir.create(td)
  suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = td,
                                           filename = "rates.csv")
  )
  csv <- read.csv(file.path(td, "rates.csv"))
  expect_equal(nrow(csv), 2L)
  expect_true("acceptance_rate" %in% names(csv))
})

test_that("errors on missing required columns", {
  expect_error(
    mysterycall_insurance_acceptance_rates(df, insurance_col = "missing",
                                           output_dir = NA),
    "not found"
  )
  expect_error(
    mysterycall_insurance_acceptance_rates(df, phone_col = "missing",
                                           output_dir = NA),
    "not found"
  )
})

test_that("gracefully handles missing medicaid_accept_col", {
  df2 <- df[, setdiff(names(df), "does_the_physician_accept_medicaid")]
  res <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df2, output_dir = NA)
  )
  expect_type(res$medicaid_acceptance_rate, "double")
})
