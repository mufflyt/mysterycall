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
# Tests for mysterycall_check_academic_name_patterns
# ============================================================================

test_that("mysterycall_check_academic_name_patterns returns correct structure with valid input", {
  org_names <- c("Johns Hopkins Hospital", "Community Hospital", "University of Michigan Medical Center")
  result <- suppressMessages(mysterycall_check_academic_name_patterns(org_names))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_equal(colnames(result), c("academic_indicator", "confidence_score", "matched_pattern"))
  expect_type(result$academic_indicator, "logical")
  expect_type(result$confidence_score, "double")
  expect_type(result$matched_pattern, "character")
})

test_that("mysterycall_check_academic_name_patterns correctly identifies known institutions", {
  org_names <- c("JOHNS HOPKINS", "MAYO CLINIC", "Random Clinic", "UCSF Medical Center")
  result <- suppressMessages(mysterycall_check_academic_name_patterns(org_names))

  expect_true(result$academic_indicator[1])
  expect_true(result$academic_indicator[2])
  expect_false(result$academic_indicator[3])
  expect_true(result$academic_indicator[4])
  expect_equal(result$confidence_score[1], 0.99)
  expect_equal(result$confidence_score[2], 0.99)
  expect_equal(result$confidence_score[3], 0.0)
})

test_that("mysterycall_check_academic_name_patterns respects confidence threshold parameter", {
  # "Medical Center" pattern has confidence 0.80 (moderate)
  org_names <- "Medical Center"

  # With default threshold 0.85, score < 0.85 should be zeroed out
  result_high_threshold <- suppressMessages(mysterycall_check_academic_name_patterns(org_names, confidence_threshold = 0.85))
  expect_false(result_high_threshold$academic_indicator[1])
  expect_equal(result_high_threshold$confidence_score[1], 0.0)

  # With lower threshold 0.75, score 0.80 >= 0.75 should be included
  result_low_threshold <- suppressMessages(mysterycall_check_academic_name_patterns(org_names, confidence_threshold = 0.75))
  expect_true(result_low_threshold$academic_indicator[1])
  expect_equal(result_low_threshold$confidence_score[1], 0.80)
})

test_that("mysterycall_check_academic_name_patterns handles edge cases correctly", {
  # Empty vector
  result_empty <- suppressMessages(mysterycall_check_academic_name_patterns(c()))
  expect_equal(nrow(result_empty), 0)
  expect_s3_class(result_empty, "data.frame")

  # NULL input
  result_null <- suppressMessages(mysterycall_check_academic_name_patterns(NULL))
  expect_equal(nrow(result_null), 0)

  # Single element
  result_single <- suppressMessages(mysterycall_check_academic_name_patterns("Johns Hopkins"))
  expect_equal(nrow(result_single), 1)
  expect_true(result_single$academic_indicator[1])
})

test_that("mysterycall_check_academic_name_patterns is case-insensitive", {
  org_names <- c("johns hopkins", "JOHNS HOPKINS", "Johns Hopkins", "jOhNs HoPkInS")
  result <- suppressMessages(mysterycall_check_academic_name_patterns(org_names))

  # All should match at confidence 0.99
  expect_true(all(result$academic_indicator))
  expect_true(all(result$confidence_score == 0.99))
})

test_that("mysterycall_check_academic_name_patterns matches pattern tiers correctly", {
  # very_high tier patterns (0.95 confidence)
  very_high <- suppressMessages(mysterycall_check_academic_name_patterns("School of Medicine", confidence_threshold = 0.85))
  expect_true(very_high$academic_indicator[1])
  expect_equal(very_high$confidence_score[1], 0.95)

  # high tier patterns (0.90 confidence)
  high <- suppressMessages(mysterycall_check_academic_name_patterns("University Hospital", confidence_threshold = 0.85))
  expect_true(high$academic_indicator[1])
  expect_equal(high$confidence_score[1], 0.90)
})

test_that("mysterycall_check_academic_name_patterns handles whitespace in org names", {
  org_names <- c("  Johns Hopkins  ", "JOHNS HOPKINS", "Johns   Hopkins")
  result <- suppressMessages(mysterycall_check_academic_name_patterns(org_names))

  # First two should match; third may not match exactly depending on implementation
  expect_true(result$academic_indicator[1])
  expect_true(result$academic_indicator[2])
})

# ============================================================================
# Tests for mysterycall_classify_academic_affiliation
# ============================================================================

test_that("mysterycall_classify_academic_affiliation returns correct structure", {
  org_names <- c("University of Michigan Medical Center", "Community Hospital")
  result <- suppressMessages(mysterycall_classify_academic_affiliation(org_names))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_equal(colnames(result), c("academic_classification", "confidence_score", "matched_pattern"))
  expect_type(result$academic_classification, "character")
  expect_type(result$confidence_score, "double")
})

test_that("mysterycall_classify_academic_affiliation correctly classifies organizations", {
  org_names <- c("Johns Hopkins Hospital", "Mom and Pop Clinic", "UCSF", "Small Town Clinic")
  result <- suppressMessages(mysterycall_classify_academic_affiliation(org_names))

  expect_equal(result$academic_classification[1], "Academic")
  expect_equal(result$academic_classification[2], "Non-Academic")
  expect_equal(result$academic_classification[3], "Academic")
  expect_equal(result$academic_classification[4], "Non-Academic")
})

test_that("mysterycall_classify_academic_affiliation incorporates hospital_affiliation parameter", {
  org_names <- c("Some Hospital", "Some Hospital")
  hospital_aff <- c("MAYO CLINIC", "Unknown Private Clinic")

  result <- suppressMessages(mysterycall_classify_academic_affiliation(
    org_names,
    hospital_affiliation = hospital_aff
  ))

  # First should be Academic due to hospital affiliation match
  expect_equal(result$academic_classification[1], "Academic")
  expect_true(result$confidence_score[1] > 0.0)
})

test_that("mysterycall_classify_academic_affiliation applies specialty boost correctly", {
  org_names <- c("General Hospital", "General Hospital", "General Hospital")
  specialties <- c("SURGICAL ONCOLOGY", "MEDICAL ONCOLOGY", "Primary Care")

  result <- suppressMessages(mysterycall_classify_academic_affiliation(
    org_names,
    specialty = specialties
  ))

  # First two should have research_intensive specialty boost
  # They should have equal or higher confidence than the third
  expect_true(result$confidence_score[1] >= result$confidence_score[3])
  expect_true(result$confidence_score[2] >= result$confidence_score[3])
})

test_that("mysterycall_classify_academic_affiliation handles all parameters together", {
  org_names <- c("University Hospital")
  hospital_aff <- c("School of Medicine")
  specialty <- c("NEUROSURGERY")

  result <- suppressMessages(mysterycall_classify_academic_affiliation(
    org_names,
    hospital_affiliation = hospital_aff,
    specialty = specialty
  ))

  expect_equal(result$academic_classification[1], "Academic")
  expect_true(result$confidence_score[1] > 0.85)
  expect_type(result$matched_pattern[1], "character")
})

test_that("mysterycall_classify_academic_affiliation handles NULL optional parameters", {
  org_names <- c("Johns Hopkins", "Unknown Clinic")

  result <- suppressMessages(mysterycall_classify_academic_affiliation(
    org_names,
    hospital_affiliation = NULL,
    specialty = NULL
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_equal(result$academic_classification[1], "Academic")
  expect_equal(result$academic_classification[2], "Non-Academic")
})

test_that("mysterycall_classify_academic_affiliation handles empty vectors correctly", {
  result <- suppressMessages(mysterycall_classify_academic_affiliation(c()))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_equal(colnames(result), c("academic_classification", "confidence_score", "matched_pattern"))
})

test_that("mysterycall_classify_academic_affiliation confidence scores are bounded 0-1", {
  org_names <- c("Johns Hopkins", "University of Yale", "School of Medicine")
  result <- suppressMessages(mysterycall_classify_academic_affiliation(org_names))

  expect_true(all(result$confidence_score >= 0.0))
  expect_true(all(result$confidence_score <= 1.0))
})

# ============================================================================
# Tests for mysterycall_get_academic_indicators_summary
# ============================================================================

test_that("mysterycall_get_academic_indicators_summary returns correct top-level structure", {
  result <- suppressMessages(mysterycall_get_academic_indicators_summary())

  expect_type(result, "list")
  expected_names <- c("module_version", "created_date", "indicators", "total_known_institutions",
                      "total_patterns", "usage_notes")
  expect_true(all(expected_names %in% names(result)))
})

test_that("mysterycall_get_academic_indicators_summary has correct data types", {
  result <- suppressMessages(mysterycall_get_academic_indicators_summary())

  expect_type(result$module_version, "character")
  expect_type(result$created_date, "character")
  expect_type(result$total_known_institutions, "integer")
  expect_type(result$total_patterns, "integer")
  expect_type(result$usage_notes, "character")
})

test_that("mysterycall_get_academic_indicators_summary has positive counts", {
  result <- suppressMessages(mysterycall_get_academic_indicators_summary())

  expect_true(result$total_known_institutions > 0)
  expect_true(result$total_patterns > 0)
})

test_that("mysterycall_get_academic_indicators_summary has proper indicators structure", {
  result <- suppressMessages(mysterycall_get_academic_indicators_summary())
  indicators <- result$indicators

  # Check tier structure
  expected_tiers <- c("tier1_education_training", "tier2_research_clinical", "tier3_name_patterns")
  expect_true(all(expected_tiers %in% names(indicators)))

  # Check tier1
  expect_true("confidence_range" %in% names(indicators$tier1_education_training))
  expect_true("indicators" %in% names(indicators$tier1_education_training))

  # Check tier2
  expect_true("confidence_range" %in% names(indicators$tier2_research_clinical))
  expect_true("indicators" %in% names(indicators$tier2_research_clinical))

  # Check tier3
  expect_true("confidence_range" %in% names(indicators$tier3_name_patterns))
  expect_true("patterns" %in% names(indicators$tier3_name_patterns))
})

test_that("mysterycall_get_academic_indicators_summary has usage guidelines", {
  result <- suppressMessages(mysterycall_get_academic_indicators_summary())

  expect_type(result$usage_notes, "character")
  expect_true(length(result$usage_notes) > 0)
  # Should recommend the classify function
  expect_true(any(grepl("classify_academic_affiliation", result$usage_notes)))
})

# ============================================================================
# Tests for exported data constants
# ============================================================================

test_that("KNOWN_ACADEMIC_INSTITUTIONS is a non-empty character vector", {
  expect_type(KNOWN_ACADEMIC_INSTITUTIONS, "character")
  expect_true(length(KNOWN_ACADEMIC_INSTITUTIONS) > 0)
  expect_true("JOHNS HOPKINS" %in% KNOWN_ACADEMIC_INSTITUTIONS)
  expect_true("MAYO CLINIC" %in% KNOWN_ACADEMIC_INSTITUTIONS)
})

test_that("ACADEMIC_HOSPITAL_PATTERNS is a properly structured named list", {
  expect_type(ACADEMIC_HOSPITAL_PATTERNS, "list")

  expected_names <- c("very_high", "high", "moderate")
  expect_true(all(expected_names %in% names(ACADEMIC_HOSPITAL_PATTERNS)))

  # Each tier should be a character vector
  expect_type(ACADEMIC_HOSPITAL_PATTERNS$very_high, "character")
  expect_type(ACADEMIC_HOSPITAL_PATTERNS$high, "character")
  expect_type(ACADEMIC_HOSPITAL_PATTERNS$moderate, "character")

  # Each tier should be non-empty
  expect_true(length(ACADEMIC_HOSPITAL_PATTERNS$very_high) > 0)
  expect_true(length(ACADEMIC_HOSPITAL_PATTERNS$high) > 0)
  expect_true(length(ACADEMIC_HOSPITAL_PATTERNS$moderate) > 0)
})

test_that("ACGME_PROGRAM_INDICATORS is a non-empty character vector", {
  expect_type(ACGME_PROGRAM_INDICATORS, "character")
  expect_true(length(ACGME_PROGRAM_INDICATORS) > 0)
  expect_true("RESIDENCY PROGRAM" %in% ACGME_PROGRAM_INDICATORS)
})

test_that("COTH_TEACHING_INDICATORS is a non-empty character vector", {
  expect_type(COTH_TEACHING_INDICATORS, "character")
  expect_true(length(COTH_TEACHING_INDICATORS) > 0)
  expect_true("TEACHING HOSPITAL" %in% COTH_TEACHING_INDICATORS)
})

test_that("MEDICAL_SCHOOL_INDICATORS is a non-empty character vector", {
  expect_type(MEDICAL_SCHOOL_INDICATORS, "character")
  expect_true(length(MEDICAL_SCHOOL_INDICATORS) > 0)
  expect_true("SCHOOL OF MEDICINE" %in% MEDICAL_SCHOOL_INDICATORS)
})

test_that("NIH_CTSA_HUBS is a non-empty character vector", {
  expect_type(NIH_CTSA_HUBS, "character")
  expect_true(length(NIH_CTSA_HUBS) > 0)
  expect_true("CTSA HUB" %in% NIH_CTSA_HUBS)
})

test_that("NCI_CANCER_CENTERS is a non-empty character vector", {
  expect_type(NCI_CANCER_CENTERS, "character")
  expect_true(length(NCI_CANCER_CENTERS) > 0)
  expect_true("NCI-DESIGNATED" %in% NCI_CANCER_CENTERS)
})

test_that("MEDICARE_GME_INDICATORS is a non-empty character vector", {
  expect_type(MEDICARE_GME_INDICATORS, "character")
  expect_true(length(MEDICARE_GME_INDICATORS) > 0)
  expect_true("GME PAYMENTS" %in% MEDICARE_GME_INDICATORS)
})
