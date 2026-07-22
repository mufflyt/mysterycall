library(testthat)
testthat::skip_if_not_installed("dplyr")
library(dplyr)

test_that("mysterycall_most_common_gender handles empty dataframe correctly", {
  # Create empty test data
  df <- data.frame(
    gender = character(0),
    specialty = character(0),
    Provider.Credential.Text = character(0),
    academic_affiliation = character(0)
  )

  # Expected result
  expected <- "The most common gender in the dataset was  (NaN%). The most common specialty was  (NaN%). The most common training was  (NaN%). The academic affiliation status most frequently occurring was  (NaN%)."

  # Run test
  result <- mysterycall_most_common_gender(df)
  expect_equal(result, expected)
})

test_that("mysterycall_most_common_gender handles large datasets correctly", {
  # Create a large test dataset
  set.seed(123)
  df <- data.frame(
    gender = sample(c("Male", "Female"), 1000, replace = TRUE),
    specialty = sample(c("Cardiology", "Neurology", "Pediatrics"), 1000, replace = TRUE),
    Provider.Credential.Text = sample(c("MD", "DO"), 1000, replace = TRUE),
    academic_affiliation = sample(c("Yes", "No"), 1000, replace = TRUE)
  )

  # Calculate expected result
  gender_info <- df %>% filter(!is.na(gender)) %>% count(gender) %>% arrange(desc(n), gender) %>% slice(1)
  most_gender <- tolower(gender_info$gender)
  proportion_gender <- round((gender_info$n / nrow(df)) * 100, 1)

  specialty_info <- df %>% filter(!is.na(specialty)) %>% count(specialty) %>% arrange(desc(n), specialty) %>% slice(1)
  most_specialty <- specialty_info$specialty
  proportion_specialty <- round((specialty_info$n / nrow(df)) * 100, 1)

  training_info <- df %>% filter(!is.na(Provider.Credential.Text)) %>% count(Provider.Credential.Text) %>% arrange(desc(n), Provider.Credential.Text) %>% slice(1)
  most_training <- training_info$Provider.Credential.Text
  proportion_training <- round((training_info$n / nrow(df)) * 100, 1)

  academic_info <- df %>% filter(!is.na(academic_affiliation)) %>% count(academic_affiliation) %>% arrange(desc(n), academic_affiliation) %>% slice(1)
  most_academic <- tolower(academic_info$academic_affiliation)
  proportion_academic <- round((academic_info$n / nrow(df)) * 100, 1)

  expected <- paste0(
    "The most common gender in the dataset was ", most_gender,
    " (", proportion_gender, "%). The most common specialty was ", most_specialty,
    " (", proportion_specialty, "%). The most common training was ", most_training,
    " (", proportion_training, "%). The academic affiliation status most frequently occurring was ", most_academic,
    " (", proportion_academic, "%)."
  )

  # Run test
  result <- mysterycall_most_common_gender(df)
  expect_equal(result, expected)
})


test_that("most_common_gender folds case: 'Male' and 'male' are one level", {
  # Regression: mixed casing must not split the gender mode into two levels.
  df <- data.frame(
    gender                   = c("Male", "male", "female"),
    specialty                = c("OB/GYN", "OB/GYN", "OB/GYN"),
    Provider.Credential.Text = c("MD", "MD", "MD"),
    academic_affiliation     = c("Yes", "Yes", "No"),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_most_common_gender(df)
  # 2 of 3 are male once case is folded -> "male (66.7%)", not "male (33.3%)"
  expect_match(result, "most common gender in the dataset was male \\(66\\.7%\\)")
})
