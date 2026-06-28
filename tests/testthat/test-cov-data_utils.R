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

# ============================================================================
# mysterycall_check_duplicates
# ============================================================================

test_that("mysterycall_check_duplicates: happy path returns flagged duplicates", {
  df <- data.frame(
    physician_id = c("A", "A", "A", "B", "B", "C"),
    call_date    = Sys.Date() + 0:5,
    stringsAsFactors = FALSE
  )
  result <- mysterycall_check_duplicates(df, id_col = "physician_id", max_calls = 2L)

  expect_s3_class(result, "data.frame")
  expect_true("n_calls" %in% names(result))
  expect_equal(nrow(result), 3L)  # Only A's 3 calls flagged
  expect_equal(attr(result, "n_flagged"), 1L)
  expect_equal(attr(result, "max_calls"), 2L)
})

test_that("mysterycall_check_duplicates: edge case with no duplicates returns empty df", {
  df <- data.frame(
    physician_id = c("A", "B", "C"),
    call_date    = Sys.Date() + 0:2,
    stringsAsFactors = FALSE
  )
  result <- mysterycall_check_duplicates(df, id_col = "physician_id", max_calls = 2L)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
  expect_equal(attr(result, "n_flagged"), 0L)
})

test_that("mysterycall_check_duplicates: all rows same physician", {
  df <- data.frame(
    physician_id = rep("A", 5),
    call_date    = Sys.Date() + 0:4,
    stringsAsFactors = FALSE
  )
  result <- mysterycall_check_duplicates(df, id_col = "physician_id", max_calls = 2L)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 5L)
  expect_true(all(result$n_calls == 5L))
  expect_equal(attr(result, "n_flagged"), 1L)
})

test_that("mysterycall_check_duplicates: bad input not a data frame", {
  expect_error(
    mysterycall_check_duplicates(list(a = 1), id_col = "a", max_calls = 2L),
    "`data` must be a data frame"
  )
})

test_that("mysterycall_check_duplicates: bad input id_col not found", {
  df <- data.frame(
    id = c("A", "B"),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_check_duplicates(df, id_col = "missing_col", max_calls = 2L),
    "`id_col` not found in data"
  )
})

test_that("mysterycall_check_duplicates: bad input invalid max_calls", {
  df <- data.frame(id = c("A", "B"), stringsAsFactors = FALSE)

  expect_error(
    mysterycall_check_duplicates(df, id_col = "id", max_calls = "two"),
    "`max_calls` must be a single positive integer"
  )
  expect_error(
    mysterycall_check_duplicates(df, id_col = "id", max_calls = NA),
    "`max_calls` must be a single positive integer"
  )
  expect_error(
    mysterycall_check_duplicates(df, id_col = "id", max_calls = 0L),
    "`max_calls` must be a single positive integer"
  )
})

# ============================================================================
# mysterycall_stratified_sample
# ============================================================================

test_that("mysterycall_stratified_sample: happy path samples correctly", {
  df <- data.frame(
    specialty = rep(c("Otolaryngology", "Urology", "Dermatology"), c(100, 80, 60)),
    x         = rnorm(240),
    stringsAsFactors = FALSE
  )
  set.seed(2)
  result <- suppressMessages(mysterycall_stratified_sample(df, group_col = "specialty", n_per_group = 30L, seed = 42L))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 90L)  # 30 per group
  expect_true(all(table(result$specialty) == 30L))
})

test_that("mysterycall_stratified_sample: n_per_group larger than some groups", {
  df <- data.frame(
    group = c("A", "A", "A", "B", "B", "C", "C", "C", "C", "C"),
    value = 1:10,
    stringsAsFactors = FALSE
  )
  result <- mysterycall_stratified_sample(df, group_col = "group", n_per_group = 10L, seed = 1L)

  # A: 3 (all returned), B: 2 (all returned), C: 5 (all returned)
  expect_equal(nrow(result), 10L)
  expect_equal(as.integer(table(result$group)["A"]), 3L)
  expect_equal(as.integer(table(result$group)["B"]), 2L)
  expect_equal(as.integer(table(result$group)["C"]), 5L)
})

test_that("mysterycall_stratified_sample: small n_per_group", {
  df <- data.frame(
    specialty = rep(c("A", "B", "C"), each = 20),
    x         = rnorm(60),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_stratified_sample(df, group_col = "specialty", n_per_group = 1L, seed = 3L)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3L)  # 1 per group
  expect_true(all(table(result$specialty) == 1L))
})

test_that("mysterycall_stratified_sample: rows in original order", {
  df <- data.frame(
    group = c("A", "B", "A", "B", "A", "B"),
    id    = 1:6,
    stringsAsFactors = FALSE
  )
  result <- mysterycall_stratified_sample(df, group_col = "group", n_per_group = 2L, seed = 4L)

  # Original row numbers should still be sorted (sorted idx ensures this)
  expect_true(all(diff(result$id) > 0L | diff(result$id) == 0L))
})

test_that("mysterycall_stratified_sample: bad input group_col not found", {
  df <- data.frame(
    id = c("A", "B"),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_stratified_sample(df, group_col = "missing", n_per_group = 1L),
    "`group_col` not found in data"
  )
})

test_that("mysterycall_stratified_sample: bad input not a data frame", {
  expect_error(
    mysterycall_stratified_sample(list(a = 1), group_col = "a", n_per_group = 1L),
    "`data` must be a data frame"
  )
})

test_that("mysterycall_stratified_sample: bad input invalid n_per_group", {
  df <- data.frame(id = c("A", "B"), stringsAsFactors = FALSE)

  expect_error(
    mysterycall_stratified_sample(df, group_col = "id", n_per_group = "one"),
    "`n_per_group` must be a single positive integer"
  )
  expect_error(
    mysterycall_stratified_sample(df, group_col = "id", n_per_group = 0L),
    "`n_per_group` must be a single positive integer"
  )
})

# ============================================================================
# mysterycall_prepare_table1_vars
# ============================================================================

test_that("mysterycall_prepare_table1_vars: happy path with age_col and gender_col", {
  df <- data.frame(
    age    = c(35, 45, 55, 65),
    gender = c("Female", "M", "male", "F"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_prepare_table1_vars(
    df,
    age_col    = "age",
    gender_col = "gender",
    ref_year   = 2026L
  ))

  expect_s3_class(result, "data.frame")
  expect_true("age_category" %in% names(result))
  expect_true("gender_std" %in% names(result))
  expect_equal(nrow(result), 4L)
  expect_true(all(result$gender_std %in% c("Male", "Female", "Unknown")))
})

test_that("mysterycall_prepare_table1_vars: happy path with grad_year_col", {
  df <- data.frame(
    grad_year = c(1990, 2000, 2010, 2020),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_prepare_table1_vars(
    df,
    grad_year_col = "grad_year",
    ref_year       = 2026L
  ))

  expect_s3_class(result, "data.frame")
  expect_true("age_imputed" %in% names(result))
  expect_true("age_category" %in% names(result))
  # age_imputed should be numeric and calculated from grad_year
  expect_type(result$age_imputed, "integer")
  expect_equal(length(result$age_imputed), 4L)
})

test_that("mysterycall_prepare_table1_vars: edge case no columns provided", {
  df <- data.frame(
    x = c(1, 2, 3),
    y = c("a", "b", "c"),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_prepare_table1_vars(df)

  expect_s3_class(result, "data.frame")
  expect_equal(names(result), names(df))
  expect_equal(nrow(result), 3L)
})

test_that("mysterycall_prepare_table1_vars: edge case non-existent columns skipped", {
  df <- data.frame(
    x = c(1, 2, 3),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_prepare_table1_vars(
    df,
    age_col    = "missing_age",
    gender_col = "missing_gender",
    ref_year   = 2026L
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(names(result), names(df))  # No new columns added
})

test_that("mysterycall_prepare_table1_vars: setting_col and region_col passed through", {
  df <- data.frame(
    setting = c("Hospital", "Clinic"),
    region  = c("North", "South"),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_prepare_table1_vars(
    df,
    setting_col = "setting",
    region_col  = "region"
  )

  expect_s3_class(result, "data.frame")
  expect_true("setting_std" %in% names(result))
  expect_true("region_std" %in% names(result))
  expect_equal(result$setting_std, c("Hospital", "Clinic"))
  expect_equal(result$region_std, c("North", "South"))
})

test_that("mysterycall_prepare_table1_vars: gender standardization case insensitive", {
  df <- data.frame(
    gender = c("MALE", "Female", "f", "M", "unknown", NA),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_prepare_table1_vars(
    df,
    gender_col = "gender"
  ))

  expect_equal(result$gender_std[1], "Male")
  expect_equal(result$gender_std[2], "Female")
  expect_equal(result$gender_std[3], "Female")
  expect_equal(result$gender_std[4], "Male")
  expect_equal(result$gender_std[5], "Unknown")
  expect_equal(result$gender_std[6], "Unknown")
})

test_that("mysterycall_prepare_table1_vars: bad input not a data frame", {
  expect_error(
    mysterycall_prepare_table1_vars(
      list(a = 1),
      age_col = "a"
    ),
    "`data` must be a data frame"
  )
})

test_that("mysterycall_prepare_table1_vars: age_col takes priority over grad_year_col", {
  df <- data.frame(
    age       = c(40, 50),
    grad_year = c(1980, 1970),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_prepare_table1_vars(
    df,
    age_col        = "age",
    grad_year_col  = "grad_year",
    ref_year       = 2026L
  ))

  # age_imputed should NOT be created (age_col takes priority)
  expect_false("age_imputed" %in% names(result))
  # But age_category should be from age_col
  expect_true("age_category" %in% names(result))
})
