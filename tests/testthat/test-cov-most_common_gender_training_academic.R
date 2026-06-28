library(testthat)
library(mysterycall)

# Shared fixture: a small well-formed data frame
PROVIDER_DF <- data.frame(
  gender                  = c("Male", "Female", "Female", "Male", "Male"),
  specialty               = c("Cardiology", "Cardiology", "Neurology", "Cardiology", "Neurology"),
  Provider.Credential.Text = c("MD", "MD", "DO", "MD", "DO"),
  academic_affiliation    = c("Yes", "No", "Yes", "No", "Yes"),
  stringsAsFactors        = FALSE
)


# Happy path: correct sentence structure and majority values
test_that("mysterycall_most_common_gender returns correct sentence for basic input", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_most_common_gender(PROVIDER_DF)
  ))

  expect_type(result, "character")
  expect_length(result, 1L)

  # Gender: Male (3/5 = 60%) — stored lower-cased in the sentence
  expect_true(grepl("male", result, ignore.case = FALSE))
  expect_true(grepl("60", result))

  # Specialty: Cardiology (3/5 = 60%)
  expect_true(grepl("Cardiology", result))

  # Training: MD (3/5 = 60%)
  expect_true(grepl("MD", result))

  # Academic affiliation: Yes (3/5 = 60%) — stored lower-cased
  expect_true(grepl("yes", result, ignore.case = FALSE))
})


# Happy path: dataset with NA values in every required column
test_that("mysterycall_most_common_gender ignores NAs and reports correct proportions", {
  df_na <- data.frame(
    gender                  = c("Male", NA, "Female", "Male", "Male"),
    specialty               = c("Cardiology", "Cardiology", "Neurology", NA, "Neurology"),
    Provider.Credential.Text = c("MD", "MD", "DO", "MD", "DO"),
    academic_affiliation    = c("Yes", "No", "Yes", "No", NA),
    stringsAsFactors        = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_most_common_gender(df_na)
  ))

  expect_type(result, "character")
  expect_length(result, 1L)
  # After NA removal: Male 3/4 = 75 %
  expect_true(grepl("75", result))
})


# Edge case: all values in one column are NA -> proportion is NaN
test_that("mysterycall_most_common_gender handles all-NA column gracefully", {
  df_all_na <- data.frame(
    gender                  = c(NA_character_, NA_character_, NA_character_),
    specialty               = c("Cardiology", "Cardiology", "Neurology"),
    Provider.Credential.Text = c("MD", "DO", "MD"),
    academic_affiliation    = c("Yes", "No", "Yes"),
    stringsAsFactors        = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_most_common_gender(df_all_na)
  ))

  expect_type(result, "character")
  # When total_count == 0, proportion is NaN; sentence should still be a string
  expect_true(grepl("NaN", result))
})


# Edge case: zero-row data frame -> all proportions are NaN
test_that("mysterycall_most_common_gender handles zero-row data frame", {
  df_empty <- data.frame(
    gender                  = character(0),
    specialty               = character(0),
    Provider.Credential.Text = character(0),
    academic_affiliation    = character(0),
    stringsAsFactors        = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_most_common_gender(df_empty)
  ))

  expect_type(result, "character")
  expect_length(result, 1L)
})


# Bad input: missing required columns -> expect_error
test_that("mysterycall_most_common_gender errors when required columns are absent", {
  df_bad <- data.frame(
    gender    = c("Male", "Female"),
    specialty = c("OB/GYN", "OB/GYN"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_most_common_gender(df_bad),
    regexp = "Provider\\.Credential\\.Text|academic_affiliation"
  )
})


# Tie-breaking: alphabetically earlier value is selected
test_that("mysterycall_most_common_gender breaks ties alphabetically", {
  df_tie <- data.frame(
    gender                  = c("Female", "Male"),          # tie -> "Female" wins
    specialty               = c("Cardiology", "Neurology"), # tie -> "Cardiology" wins
    Provider.Credential.Text = c("DO", "MD"),               # tie -> "DO" wins
    academic_affiliation    = c("No", "Yes"),               # tie -> "No" wins
    stringsAsFactors        = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_most_common_gender(df_tie)
  ))

  expect_true(grepl("female",      result, ignore.case = FALSE))
  expect_true(grepl("Cardiology",  result))
  expect_true(grepl("DO",          result))
  expect_true(grepl("no",          result, ignore.case = FALSE))
})
