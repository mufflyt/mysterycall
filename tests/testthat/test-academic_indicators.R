# Tests for R/academic_indicators.R

test_that("mysterycall_check_academic_name_patterns returns empty result for empty input", {
  res <- mysterycall_check_academic_name_patterns(character(0))
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 0L)
  expect_named(res, c("academic_indicator", "confidence_score", "matched_pattern"))
})

test_that("mysterycall_check_academic_name_patterns returns NA row for NULL input", {
  res <- mysterycall_check_academic_name_patterns(NULL)
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 0L)
})

test_that("mysterycall_check_academic_name_patterns identifies very-high-confidence patterns", {
  orgs <- c("Stanford University School of Medicine", "Random Community Clinic")
  res <- mysterycall_check_academic_name_patterns(orgs)
  expect_equal(nrow(res), 2L)
  expect_true(res$academic_indicator[1])
  expect_gte(res$confidence_score[1], 0.85)
  expect_false(res$academic_indicator[2])
  expect_equal(res$confidence_score[2], 0)
})

test_that("mysterycall_check_academic_name_patterns matches high-confidence patterns", {
  res <- mysterycall_check_academic_name_patterns("UCLA Medical Center")
  expect_true(res$academic_indicator[1])
  expect_gte(res$confidence_score[1], 0.85)
})

test_that("mysterycall_check_academic_name_patterns respects confidence_threshold", {
  # A "MEDICAL CENTER" alone is moderate confidence (~0.80)
  low_thresh  <- mysterycall_check_academic_name_patterns("Saint Joseph Medical Center",
                                                          confidence_threshold = 0.75)
  high_thresh <- mysterycall_check_academic_name_patterns("Saint Joseph Medical Center",
                                                          confidence_threshold = 0.95)
  expect_true(low_thresh$academic_indicator[1])
  expect_false(high_thresh$academic_indicator[1])
})

test_that("mysterycall_check_academic_name_patterns matches a known institution by name", {
  res <- mysterycall_check_academic_name_patterns("Mayo Clinic Hospital")
  expect_true(res$academic_indicator[1])
})

test_that("mysterycall_check_academic_name_patterns is vectorised", {
  res <- mysterycall_check_academic_name_patterns(c("Stanford University", "Community Clinic",
                                                    "Johns Hopkins Hospital"))
  expect_equal(nrow(res), 3L)
  expect_true(all(c("academic_indicator", "confidence_score", "matched_pattern") %in% names(res)))
})

test_that("mysterycall_classify_academic_affiliation returns expected columns", {
  res <- mysterycall_classify_academic_affiliation("Stanford University Medical Center")
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 1L)
  expect_true("academic_classification" %in% names(res))
})

test_that("mysterycall_classify_academic_affiliation accepts hospital_affiliation flag", {
  res <- mysterycall_classify_academic_affiliation(
    org_name             = "Community Hospital",
    hospital_affiliation = TRUE
  )
  expect_equal(nrow(res), 1L)
})

test_that("mysterycall_classify_academic_affiliation accepts specialty arg", {
  res <- mysterycall_classify_academic_affiliation(
    org_name  = "Generic Clinic",
    specialty = "Family Medicine"
  )
  expect_equal(nrow(res), 1L)
})

test_that("mysterycall_classify_academic_affiliation is vectorised", {
  res <- mysterycall_classify_academic_affiliation(
    c("Stanford University", "Community Clinic")
  )
  expect_equal(nrow(res), 2L)
})

test_that("mysterycall_get_academic_indicators_summary returns a named list", {
  summary <- mysterycall_get_academic_indicators_summary()
  expect_type(summary, "list")
  expect_true(length(summary) >= 2L)
  # Must contain key counts
  numeric_fields <- vapply(summary, is.numeric, logical(1))
  expect_true(any(numeric_fields))
})
