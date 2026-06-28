library(testthat)
library(mysterycall)

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


test_that("mysterycall_simple_poisson: happy path with explicit reference", {
  set.seed(1)
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        COUNT_DF,
        outcome = "days",
        group = "insurance",
        reference = "BCBS",
        outcome_label = "business days until appointment"
      )
    )
  )

  # Check return structure
  expect_s3_class(result, "mysterycall_simple_poisson")
  expect_type(result, "list")
  expect_true(all(c("model", "irr_table", "reference", "summary_statement", "n", "dispersion") %in% names(result)))

  # Check model is glm
  expect_s3_class(result$model, "glm")

  # Check irr_table is data.frame with expected columns
  expect_s3_class(result$irr_table, "data.frame")
  expect_true(all(c("term", "level", "irr", "ci_lower", "ci_upper", "p_value", "p_value_fmt", "direction") %in% names(result$irr_table)))

  # Check reference level
  expect_equal(result$reference, "BCBS")

  # Check n is reasonable
  expect_equal(result$n, nrow(COUNT_DF))
  expect_type(result$n, "integer")

  # Check dispersion is numeric
  expect_type(result$dispersion, "double")
  expect_true(result$dispersion > 0)

  # Check summary_statement is character
  expect_type(result$summary_statement, "character")
  expect_true(nchar(result$summary_statement) > 0)
})


test_that("mysterycall_simple_poisson: happy path without explicit reference", {
  set.seed(2)
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        COUNT_DF,
        outcome = "days",
        group = "insurance"
      )
    )
  )

  # Default reference should be alphabetically first
  expect_equal(result$reference, "BCBS")

  # IRR table should have one row for the non-reference level
  expect_equal(nrow(result$irr_table), 1L)

  # Should contain Medicaid level
  expect_true("Medicaid" %in% result$irr_table$level)
})


test_that("mysterycall_simple_poisson: use_profile_ci=FALSE", {
  set.seed(3)
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        COUNT_DF,
        outcome = "days",
        group = "insurance",
        reference = "BCBS",
        use_profile_ci = FALSE
      )
    )
  )

  expect_s3_class(result, "mysterycall_simple_poisson")
  expect_true(nrow(result$irr_table) > 0)
  # CIs should still be present
  expect_true(all(!is.na(result$irr_table$ci_lower)))
  expect_true(all(!is.na(result$irr_table$ci_upper)))
})


test_that("mysterycall_simple_poisson: custom outcome_label", {
  set.seed(4)
  custom_label <- "appointment wait time"
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        COUNT_DF,
        outcome = "days",
        group = "insurance",
        outcome_label = custom_label
      )
    )
  )

  # Custom label should appear in summary statement
  expect_true(grepl(custom_label, result$summary_statement, ignore.case = FALSE))
})


test_that("mysterycall_simple_poisson: conf_level parameter", {
  set.seed(5)
  result_95 <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        COUNT_DF,
        outcome = "days",
        group = "insurance",
        conf_level = 0.95
      )
    )
  )

  result_90 <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        COUNT_DF,
        outcome = "days",
        group = "insurance",
        conf_level = 0.90
      )
    )
  )

  # 90% CI should be narrower than 95% CI
  expect_true(
    (result_90$irr_table$ci_upper[1] - result_90$irr_table$ci_lower[1]) <
      (result_95$irr_table$ci_upper[1] - result_95$irr_table$ci_lower[1])
  )
})


test_that("mysterycall_simple_poisson: handles NAs in outcome", {
  set.seed(6)
  df_with_na <- COUNT_DF
  df_with_na$days[c(1, 5)] <- NA

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        df_with_na,
        outcome = "days",
        group = "insurance"
      )
    )
  )

  # Should exclude 2 rows with NA in outcome
  expect_equal(result$n, nrow(COUNT_DF) - 2L)
})


test_that("mysterycall_simple_poisson: handles NAs in group", {
  set.seed(7)
  df_with_na <- COUNT_DF
  df_with_na$insurance[c(2, 10)] <- NA

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        df_with_na,
        outcome = "days",
        group = "insurance"
      )
    )
  )

  # Should exclude 2 rows with NA in group
  expect_equal(result$n, nrow(COUNT_DF) - 2L)
})


test_that("mysterycall_simple_poisson: error on non-numeric outcome", {
  set.seed(8)
  df_bad <- data.frame(
    days      = as.character(c(rpois(40, 5), rpois(40, 10))),
    insurance = rep(c("Medicaid","BCBS"), each = 40L),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_simple_poisson(
      df_bad,
      outcome = "days",
      group = "insurance"
    ),
    "must be numeric"
  )
})


test_that("mysterycall_simple_poisson: error on non-factor/character group", {
  set.seed(9)
  df_bad <- data.frame(
    days      = c(rpois(40, 5), rpois(40, 10)),
    insurance = as.numeric(rep(c(1, 2), each = 40L)),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_simple_poisson(
      df_bad,
      outcome = "days",
      group = "insurance"
    ),
    "must be a factor or character"
  )
})


test_that("mysterycall_simple_poisson: error on missing outcome column", {
  set.seed(10)
  expect_error(
    mysterycall_simple_poisson(
      COUNT_DF,
      outcome = "nonexistent_column",
      group = "insurance"
    )
  )
})


test_that("mysterycall_simple_poisson: error on missing group column", {
  set.seed(11)
  expect_error(
    mysterycall_simple_poisson(
      COUNT_DF,
      outcome = "days",
      group = "nonexistent_group"
    )
  )
})


test_that("mysterycall_simple_poisson: error on invalid reference level", {
  set.seed(12)
  expect_error(
    mysterycall_simple_poisson(
      COUNT_DF,
      outcome = "days",
      group = "insurance",
      reference = "InvalidLevel"
    ),
    "is not a level"
  )
})


test_that("mysterycall_simple_poisson: error when no complete cases", {
  set.seed(13)
  df_all_na <- data.frame(
    days = rep(NA_integer_, 10),
    insurance = rep(c("A", "B"), 5),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_simple_poisson(
      df_all_na,
      outcome = "days",
      group = "insurance"
    ),
    "No complete cases"
  )
})


test_that("mysterycall_simple_poisson: error on invalid conf_level", {
  set.seed(14)
  expect_error(
    mysterycall_simple_poisson(
      COUNT_DF,
      outcome = "days",
      group = "insurance",
      conf_level = 1.5
    ),
    "not <= 1"
  )
})


test_that("mysterycall_simple_poisson: print method works", {
  set.seed(15)
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        COUNT_DF,
        outcome = "days",
        group = "insurance"
      )
    )
  )

  # Capture print output
  output <- capture.output(print(result))

  # Check that key elements appear in output
  expect_true(any(grepl("Simple Poisson GLM", output)))
  expect_true(any(grepl("Reference level", output)))
  expect_true(any(grepl("Summary statement", output)))
})


test_that("mysterycall_simple_poisson: IRR direction classification", {
  set.seed(16)
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        COUNT_DF,
        outcome = "days",
        group = "insurance"
      )
    )
  )

  # Check that direction is correctly assigned based on IRR
  for (i in seq_len(nrow(result$irr_table))) {
    row <- result$irr_table[i, ]
    if (row$irr > 1) {
      expect_equal(row$direction, "higher")
    } else if (row$irr < 1) {
      expect_equal(row$direction, "lower")
    } else {
      expect_equal(row$direction, "same")
    }
  }
})


test_that("mysterycall_simple_poisson: dispersion statistic is calculated", {
  set.seed(17)
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        COUNT_DF,
        outcome = "days",
        group = "insurance"
      )
    )
  )

  # Dispersion should be positive
  expect_true(result$dispersion > 0)

  # For this data, should not be extreme
  expect_true(result$dispersion < 10)
})


test_that("mysterycall_simple_poisson: summary statement mentions overdispersion if phi > 1.5", {
  set.seed(18)
  # Create data with higher variance to trigger overdispersion
  df_overdispersed <- data.frame(
    count = c(rep(1, 15), rep(20, 15), rep(2, 15), rep(30, 15)),
    group = rep(c("A", "B"), each = 30),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        df_overdispersed,
        outcome = "count",
        group = "group"
      )
    )
  )

  if (result$dispersion > 1.5) {
    expect_true(grepl("overdispersion", result$summary_statement, ignore.case = TRUE))
  }
})


test_that("mysterycall_simple_poisson: works with AUDIT data", {
  set.seed(19)
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        AUDIT,
        outcome = "wait_days",
        group = "insurance",
        outcome_label = "wait days"
      )
    )
  )

  expect_s3_class(result, "mysterycall_simple_poisson")
  expect_equal(result$n, nrow(AUDIT))
  expect_true(nrow(result$irr_table) > 0)
})


test_that("mysterycall_simple_poisson: factor group is handled correctly", {
  set.seed(20)
  df_factor <- COUNT_DF
  df_factor$insurance <- factor(df_factor$insurance)

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        df_factor,
        outcome = "days",
        group = "insurance"
      )
    )
  )

  expect_s3_class(result, "mysterycall_simple_poisson")
  expect_equal(result$n, nrow(df_factor))
})


test_that("mysterycall_simple_poisson: reference level relevel works correctly", {
  set.seed(21)
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_simple_poisson(
        COUNT_DF,
        outcome = "days",
        group = "insurance",
        reference = "Medicaid"
      )
    )
  )

  expect_equal(result$reference, "Medicaid")
  expect_true("BCBS" %in% result$irr_table$level)
})
