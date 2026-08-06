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

# ============================================================================
# Test 1: Happy path - basic data frame with all required columns
# ============================================================================
test_that("mysterycall_irr_to_days converts IRR data frame with exposure_col", {
  irr_tbl <- data.frame(
    term        = c("(Intercept)", "insuranceMedicaid", "insuranceUninsured"),
    irr         = c(1.00, 1.28, 0.81),
    ci_lower    = c(NA,   1.05, 0.61),
    ci_upper    = c(NA,   1.56, 1.07),
    p_value_fmt = c(NA,   "0.014", "0.134"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 21,
    exposure_col  = "insurance",
    ref_group     = "BCBS"
  )

  expect_s3_class(result, "mysterycall_irr_days")
  expect_true(is.list(result))
  expect_named(result, c("table", "sentences", "paragraph", "baseline_mean"))
  expect_true(is.data.frame(result$table))
  expect_equal(nrow(result$table), 2L)  # 2 non-intercept terms with insurance prefix
  expect_true(is.character(result$sentences))
  expect_equal(length(result$sentences), 2L)
  expect_equal(result$baseline_mean, 21)
})

# ============================================================================
# Test 2: Happy path - with all non-intercept terms (exposure_col = NULL)
# ============================================================================
test_that("mysterycall_irr_to_days includes all non-intercept terms when exposure_col=NULL", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "insuranceMedicaid", "waveWave2"),
    irr     = c(1.00, 1.15, 0.95),
    ci_lower = c(NA,  0.98, 0.80),
    ci_upper = c(NA,  1.35, 1.12),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 10,
    exposure_col  = NULL,
    ref_group     = NULL
  )

  expect_s3_class(result, "mysterycall_irr_days")
  expect_equal(nrow(result$table), 2L)
  expect_true(grepl("compared with the reference group", result$paragraph))
})

# ============================================================================
# Test 3: Day difference calculations are correct
# ============================================================================
test_that("mysterycall_irr_to_days computes correct day differences", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupTreatment"),
    irr     = c(1.00, 1.50),
    ci_lower = c(NA,  1.20),
    ci_upper = c(NA,  1.80),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 20,
    exposure_col  = "group"
  )

  # IRR 1.50 with baseline 20 -> days_mean = 30, days_diff = 10
  # ci_lower 1.20 with baseline 20 -> days_ci_lower = 4
  # ci_upper 1.80 with baseline 20 -> days_ci_upper = 16
  expect_equal(result$table$days_mean[1], 30, tolerance = 1e-6)
  expect_equal(result$table$days_diff[1], 10, tolerance = 1e-6)
  expect_equal(result$table$days_ci_lower[1], 4, tolerance = 1e-6)
  expect_equal(result$table$days_ci_upper[1], 16, tolerance = 1e-6)
})

# ============================================================================
# Test 4: Direction assignment (more vs fewer)
# ============================================================================
test_that("mysterycall_irr_to_days assigns correct direction", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupA", "groupB"),
    irr     = c(1.00, 1.20, 0.85),
    ci_lower = c(NA,  1.00, 0.70),
    ci_upper = c(NA,  1.40, 1.00),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 15,
    exposure_col  = "group"
  )

  # IRR 1.20 > 1 -> direction should be "more"
  # IRR 0.85 < 1 -> direction should be "fewer"
  expect_equal(result$table$direction[1], "more")
  expect_equal(result$table$direction[2], "fewer")
})

# ============================================================================
# Test 5: Edge case - NA p-values handled correctly
# ============================================================================
test_that("mysterycall_irr_to_days handles NA p-values gracefully", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupA"),
    irr     = c(1.00, 1.10),
    ci_lower = c(NA,  0.95),
    ci_upper = c(NA,  1.25),
    p_value_fmt = c(NA, NA),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 12,
    exposure_col  = "group"
  )

  expect_true(is.na(result$table$p_value_fmt[1]))
  expect_true(grepl("compared with the reference group", result$sentences[1]))
  expect_false(grepl("; p =", result$sentences[1]))  # p-value not included
})

# ============================================================================
# Test 6: Custom ref_group label appears in sentences
# ============================================================================
test_that("mysterycall_irr_to_days includes custom ref_group in sentences", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "insuranceMedicaid"),
    irr     = c(1.00, 1.25),
    ci_lower = c(NA,  1.05),
    ci_upper = c(NA,  1.50),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 18,
    exposure_col  = "insurance",
    ref_group     = "PrivateBlue"
  )

  expect_true(grepl("compared with PrivateBlue", result$sentences[1]))
})

# ============================================================================
# Test 7: Digit formatting is applied
# ============================================================================
test_that("mysterycall_irr_to_days respects digits and irr_digits parameters", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupTest"),
    irr     = c(1.00, 1.3456),
    ci_lower = c(NA,  1.1234),
    ci_upper = c(NA,  1.5678),
    p_value_fmt = c(NA, "0.0234"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 20,
    exposure_col  = "group",
    digits        = 2L,
    irr_digits    = 3L
  )

  # Sentence should reflect the formatted precision
  sentence <- result$sentences[1]
  expect_true(is.character(sentence))
  expect_true(grepl("IRR 1\\.346", sentence))  # irr_digits = 3
})

# ============================================================================
# Test 8: Bad input - missing baseline_mean
# ============================================================================
test_that("mysterycall_irr_to_days errors when baseline_mean is missing", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupA"),
    irr     = c(1.00, 1.10),
    ci_lower = c(NA,  0.95),
    ci_upper = c(NA,  1.25),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_irr_to_days(irr_tbl, exposure_col = "group"),
    "baseline_mean"
  )
})

# ============================================================================
# Test 9: Bad input - negative baseline_mean
# ============================================================================
test_that("mysterycall_irr_to_days errors when baseline_mean is non-positive", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupA"),
    irr     = c(1.00, 1.10),
    ci_lower = c(NA,  0.95),
    ci_upper = c(NA,  1.25),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_irr_to_days(irr_tbl, baseline_mean = -5, exposure_col = "group"),
    "must be a single positive number"
  )

  expect_error(
    mysterycall_irr_to_days(irr_tbl, baseline_mean = 0, exposure_col = "group"),
    "must be a single positive number"
  )
})

# ============================================================================
# Test 10: Bad input - missing required columns
# ============================================================================
test_that("mysterycall_irr_to_days errors when required columns are missing", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupA"),
    irr     = c(1.00, 1.10),
    ci_lower = c(NA,  0.95),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_irr_to_days(irr_tbl, baseline_mean = 10, exposure_col = "group"),
    "ci_upper"
  )
})

# ============================================================================
# Test 11: Bad input - no matching terms for exposure_col
# ============================================================================
test_that("mysterycall_irr_to_days errors when no terms match exposure_col", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "waveWave2"),
    irr     = c(1.00, 1.10),
    ci_lower = c(NA,  0.95),
    ci_upper = c(NA,  1.25),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_irr_to_days(irr_tbl, baseline_mean = 10, exposure_col = "insurance"),
    "No terms starting with"
  )
})

# ============================================================================
# Test 12: Bad input - wrong data type for model_result
# ============================================================================
test_that("mysterycall_irr_to_days errors for invalid model_result type", {
  expect_error(
    mysterycall_irr_to_days(list(x = 1), baseline_mean = 10, exposure_col = "group"),
    "must be a mysterycall_poisson_model"
  )

  expect_error(
    mysterycall_irr_to_days("not_a_model", baseline_mean = 10, exposure_col = "group"),
    "must be a mysterycall_poisson_model"
  )
})

# ============================================================================
# Test 13: Bad input - exposure_col wrong type
# ============================================================================
test_that("mysterycall_irr_to_days errors when exposure_col is not character", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupA"),
    irr     = c(1.00, 1.10),
    ci_lower = c(NA,  0.95),
    ci_upper = c(NA,  1.25),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_irr_to_days(irr_tbl, baseline_mean = 10, exposure_col = 123),
    "must be a single character string"
  )
})

# ============================================================================
# Test 14: print.mysterycall_irr_days returns invisible object
# ============================================================================
test_that("print.mysterycall_irr_days returns invisible result", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupA"),
    irr     = c(1.00, 1.20),
    ci_lower = c(NA,  1.00),
    ci_upper = c(NA,  1.40),
    p_value_fmt = c(NA, "0.045"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 15,
    exposure_col  = "group"
  )

  output <- suppressMessages(capture.output(returned <- print(result)))

  expect_identical(returned, result)
  expect_true(length(output) > 0)
  expect_true(any(grepl("Reference-group mean", output)))
})

# ============================================================================
# Test 15: print.mysterycall_irr_days with custom digits
# ============================================================================
test_that("print.mysterycall_irr_days respects digits parameter", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupTest"),
    irr     = c(1.00, 1.3456),
    ci_lower = c(NA,  1.1234),
    ci_upper = c(NA,  1.5678),
    p_value_fmt = c(NA, "0.023"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 20.123,
    exposure_col  = "group",
    digits        = 3L
  )

  output <- suppressMessages(capture.output(print(result, digits = 3)))

  expect_true(length(output) > 0)
  expect_true(any(grepl("Reference-group mean: 20.1", output)))
})

# ============================================================================
# Test 16: Happy path with p_value column instead of p_value_fmt
# ============================================================================
test_that("mysterycall_irr_to_days handles p_value column and formats it", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupA", "groupB"),
    irr     = c(1.00, 1.15, 0.95),
    ci_lower = c(NA,  0.98, 0.80),
    ci_upper = c(NA,  1.35, 1.12),
    p_value = c(NA,  0.0234, 0.5234),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 10,
    exposure_col  = "group"
  )

  expect_true(!is.na(result$table$p_value_fmt[1]))
  expect_equal(result$table$p_value_fmt[1], "0.023")
  expect_equal(result$table$p_value_fmt[2], "0.523")
})

# ============================================================================
# Test 17: p_value < 0.001 formats as "< 0.001"
# ============================================================================
test_that("mysterycall_irr_to_days formats p_value < 0.001 as '<0.001'", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupA"),
    irr     = c(1.00, 1.20),
    ci_lower = c(NA,  1.05),
    ci_upper = c(NA,  1.40),
    p_value = c(NA,  0.0001),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 12,
    exposure_col  = "group"
  )

  expect_equal(result$table$p_value_fmt[1], "< 0.001")
})

# ============================================================================
# Test 18: Level label stripping works correctly
# ============================================================================
test_that("mysterycall_irr_to_days correctly strips exposure prefix from term", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "insuranceMedicaid", "insuranceOther"),
    irr     = c(1.00, 1.15, 0.92),
    ci_lower = c(NA,  0.98, 0.75),
    ci_upper = c(NA,  1.35, 1.10),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 18,
    exposure_col  = "insurance"
  )

  expect_equal(result$table$level[1], "Medicaid")
  expect_equal(result$table$level[2], "Other")
})

# ============================================================================
# Test 19: Paragraph joins all sentences correctly
# ============================================================================
test_that("mysterycall_irr_to_days paragraph joins sentences with spaces", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupA", "groupB"),
    irr     = c(1.00, 1.10, 1.05),
    ci_lower = c(NA,  0.95, 0.90),
    ci_upper = c(NA,  1.25, 1.20),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 10,
    exposure_col  = "group"
  )

  expect_equal(result$paragraph, paste(result$sentences, collapse = " "))
  expect_true(length(result$sentences) == 2L)
})

# ============================================================================
# Test 20: Return table includes all expected columns
# ============================================================================
test_that("mysterycall_irr_to_days table includes all expected columns", {
  irr_tbl <- data.frame(
    term    = c("(Intercept)", "groupA"),
    irr     = c(1.00, 1.15),
    ci_lower = c(NA,  0.98),
    ci_upper = c(NA,  1.35),
    p_value_fmt = c(NA, "0.042"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_irr_to_days(
    irr_tbl,
    baseline_mean = 20,
    exposure_col  = "group"
  )

  expected_cols <- c("term", "level", "irr", "days_mean", "days_diff",
                     "days_ci_lower", "days_ci_upper", "direction", "p_value_fmt",
                     "p_value")
  expect_named(result$table, expected_cols)
})
