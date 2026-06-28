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

# Test 1: Happy path with all three columns
test_that("demographics_sentence returns character with all columns", {
  df <- data.frame(
    gender                   = c("Male", "Male", "Female", "Male"),
    Subspecialty             = c("REI", "MFM", "REI", "REI"),
    Provider.Credential.Text = c("MD", "DO", "MD", "MD"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_demographics_sentence(df)
  )
  expect_type(result, "character")
  expect_length(result, 1L)
  expect_true(grepl("physician gender", result))
  expect_true(grepl("subspecialty", result))
  expect_true(grepl("professional qualification", result))
})

# Test 2: Return value contains stats attribute
test_that("demographics_sentence attaches stats attribute with correct structure", {
  df <- data.frame(
    gender                   = c("Male", "Male", "Female"),
    Subspecialty             = c("REI", "REI", "MFM"),
    Provider.Credential.Text = c("MD", "DO", "MD"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_demographics_sentence(df)
  )
  stats <- attr(result, "stats")
  expect_type(stats, "list")
  expect_named(stats, c("gender", "subspecialty", "credential"))
  expect_type(stats$gender, "list")
  expect_named(stats$gender, c("level", "count", "total", "pct"))
  expect_true(is.character(stats$gender$level))
  expect_true(is.integer(stats$gender$count))
  expect_true(is.integer(stats$gender$total))
  expect_true(is.numeric(stats$gender$pct))
})

# Test 3: Optional subspecialty_col = NULL omits subspecialty clause
test_that("demographics_sentence handles subspecialty_col = NULL", {
  df <- data.frame(
    gender                   = c("Male", "Male", "Female"),
    Subspecialty             = c("REI", "MFM", "REI"),
    Provider.Credential.Text = c("MD", "DO", "MD"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_demographics_sentence(df, subspecialty_col = NULL)
  )
  expect_type(result, "character")
  expect_false(grepl("subspecialty", result))
  expect_true(grepl("physician gender", result))
  stats <- attr(result, "stats")
  expect_null(stats$subspecialty)
})

# Test 4: Optional credential_col = NULL omits credential clause
test_that("demographics_sentence handles credential_col = NULL", {
  df <- data.frame(
    gender                   = c("Male", "Male", "Female"),
    Subspecialty             = c("REI", "MFM", "REI"),
    Provider.Credential.Text = c("MD", "DO", "MD"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_demographics_sentence(df, credential_col = NULL)
  )
  expect_type(result, "character")
  expect_false(grepl("professional qualification", result))
  stats <- attr(result, "stats")
  expect_null(stats$credential)
})

# Test 5: Both optional columns NULL results in gender-only sentence
test_that("demographics_sentence with both optional columns NULL", {
  df <- data.frame(
    gender = c("Male", "Male", "Female", "Male"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_demographics_sentence(
      df,
      subspecialty_col = NULL,
      credential_col = NULL
    )
  )
  expect_type(result, "character")
  expect_true(grepl("physician gender", result))
  expect_false(grepl("subspecialty", result))
  expect_false(grepl("professional qualification", result))
  clauses <- strsplit(result, "Additionally,")[[1]]
  expect_length(clauses, 1L)
})

# Test 6: Correct modal level is identified
test_that("demographics_sentence identifies correct modal level", {
  df <- data.frame(
    gender       = c("Male", "Male", "Female"),
    Subspecialty = c("A", "B", "C"),
    Provider.Credential.Text = c("MD", "DO", "MD"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_demographics_sentence(df)
  )
  stats <- attr(result, "stats")
  expect_equal(stats$gender$level, "Male")
  expect_equal(stats$gender$count, 2L)
  expect_equal(stats$gender$total, 3L)
  expect_equal(stats$gender$pct, 200/3)
})

# Test 7: NA values are excluded from counts
test_that("demographics_sentence excludes NA values correctly", {
  df <- data.frame(
    gender       = c("Male", "Male", "Female", NA),
    Subspecialty = c("REI", "REI", NA, NA),
    Provider.Credential.Text = c("MD", "DO", "MD", NA),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_demographics_sentence(df)
  )
  stats <- attr(result, "stats")
  expect_equal(stats$gender$total, 3L)
  expect_equal(stats$subspecialty$total, 2L)
  expect_equal(stats$credential$total, 3L)
})

# Test 8: Digits parameter controls decimal places
test_that("demographics_sentence respects digits parameter", {
  df <- data.frame(
    gender = c("M", "M", "F"),
    stringsAsFactors = FALSE
  )
  result_1 <- suppressMessages(
    mysterycall_demographics_sentence(
      df,
      digits = 1L,
      subspecialty_col = NULL,
      credential_col = NULL
    )
  )
  result_3 <- suppressMessages(
    mysterycall_demographics_sentence(
      df,
      digits = 3L,
      subspecialty_col = NULL,
      credential_col = NULL
    )
  )
  expect_type(result_1, "character")
  expect_type(result_3, "character")
  # With digits=1, expect ~66.7% (one decimal)
  # With digits=3, expect ~66.667% (three decimals)
  expect_true(grepl("66\\.[0-9]%", result_1))
  expect_true(grepl("66\\.[0-9]{3}%", result_3))
})

# Test 9: Custom labels appear in output
test_that("demographics_sentence uses custom labels", {
  df <- data.frame(
    gender = c("Male", "Female"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_demographics_sentence(
      df,
      label_gender = "doctor gender",
      subspecialty_col = NULL,
      credential_col = NULL
    )
  )
  expect_true(grepl("doctor gender", result))
  expect_false(grepl("physician gender", result))
})

# Test 10: All-NA column in gender
test_that("demographics_sentence handles all-NA column", {
  df <- data.frame(
    gender       = c(NA, NA, NA),
    Subspecialty = c("A", "B", "C"),
    Provider.Credential.Text = c("MD", "DO", "MD"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_demographics_sentence(df)
  )
  stats <- attr(result, "stats")
  expect_true(is.na(stats$gender$level))
  expect_equal(stats$gender$count, 0L)
  expect_equal(stats$gender$total, 0L)
})

# Test 11: Error when gender_col does not exist
test_that("demographics_sentence errors when gender_col missing", {
  df <- data.frame(
    sex = c("Male", "Female"),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_demographics_sentence(df, gender_col = "gender"),
    "must.include"
  )
})

# Test 12: Error when subspecialty_col does not exist (when not NULL)
test_that("demographics_sentence errors when subspecialty_col missing", {
  df <- data.frame(
    gender = c("Male", "Female"),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_demographics_sentence(df, subspecialty_col = "Specialty"),
    "must.include"
  )
})

# Test 13: Error when credential_col does not exist (when not NULL)
test_that("demographics_sentence errors when credential_col missing", {
  df <- data.frame(
    gender = c("Male", "Female"),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_demographics_sentence(df, credential_col = "Credential"),
    "must.include"
  )
})

# Test 14: Error with non-data-frame input
test_that("demographics_sentence errors with invalid data type", {
  expect_error(
    mysterycall_demographics_sentence(list(gender = c("M", "F"))),
    "data.frame"
  )
})

# Test 15: Error when gender_col is not a string
test_that("demographics_sentence errors when gender_col not string", {
  df <- data.frame(gender = c("M", "F"))
  expect_error(
    mysterycall_demographics_sentence(df, gender_col = 1),
    "string"
  )
})

# Test 16: Error with negative digits
test_that("demographics_sentence errors with negative digits", {
  df <- data.frame(
    gender = c("M", "F"),
    Subspecialty = c("A", "B"),
    Provider.Credential.Text = c("MD", "DO")
  )
  expect_error(
    mysterycall_demographics_sentence(df, digits = -1L),
    ">="
  )
})

# Test 17: Tie in modal value (first alphabetically or by table order)
test_that("demographics_sentence handles tie in modal level", {
  df <- data.frame(
    gender = c("Male", "Male", "Female", "Female"),
    Subspecialty = c("A", "B", "A", "B"),
    Provider.Credential.Text = c("MD", "DO", "MD", "DO"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_demographics_sentence(df)
  )
  stats <- attr(result, "stats")
  expect_equal(stats$gender$count, 2L)
  expect_equal(stats$gender$total, 4L)
})

# Test 18: Large dataset with realistic physician data
test_that("demographics_sentence scales to larger dataset", {
  set.seed(42)
  df <- data.frame(
    gender = sample(c("Male", "Female"), 100, replace = TRUE),
    Subspecialty = sample(c("REI", "MFM", "General"), 100, replace = TRUE),
    Provider.Credential.Text = sample(c("MD", "DO"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_demographics_sentence(df)
  )
  expect_type(result, "character")
  stats <- attr(result, "stats")
  expect_equal(stats$gender$total, 100L)
  expect_equal(stats$subspecialty$total, 100L)
  expect_equal(stats$credential$total, 100L)
})
