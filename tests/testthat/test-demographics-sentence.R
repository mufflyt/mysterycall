test_that("basic sentence contains modal gender", {
  df <- data.frame(
    gender                   = c("Male", "Male", "Female", "Male"),
    Subspecialty             = c("REI", "MFM", "REI", "REI"),
    Provider.Credential.Text = c("MD", "DO", "MD", "MD"),
    stringsAsFactors = FALSE
  )
  sent <- suppressMessages(mysterycall_demographics_sentence(df))
  expect_type(sent, "character")
  expect_match(sent, "Male")
  expect_match(sent, "REI")
  expect_match(sent, "MD")
})

test_that("sentence contains correct counts and percentages", {
  df <- data.frame(
    gender                   = c("Male", "Male", "Female", "Male"),
    Subspecialty             = c("REI", "MFM", "REI", "REI"),
    Provider.Credential.Text = c("MD", "DO", "MD", "MD"),
    stringsAsFactors = FALSE
  )
  sent <- suppressMessages(mysterycall_demographics_sentence(df))
  # Male appears 3/4 = 75.0%
  expect_match(sent, "75.0")
  # n = 3, N = 4
  expect_match(sent, "n = 3/N = 4")
})

test_that("stats attribute contains correct modal values", {
  df <- data.frame(
    gender                   = c("Male", "Male", "Female"),
    Subspecialty             = c("REI", "REI", "MFM"),
    Provider.Credential.Text = c("MD", "MD", "DO"),
    stringsAsFactors = FALSE
  )
  sent  <- suppressMessages(mysterycall_demographics_sentence(df))
  stats <- attr(sent, "stats")
  expect_equal(stats$gender$level, "Male")
  expect_equal(stats$gender$count, 2L)
  expect_equal(stats$subspecialty$level, "REI")
  expect_equal(stats$credential$level, "MD")
})

test_that("subspecialty_col = NULL omits subspecialty clause", {
  df <- data.frame(
    gender                   = c("Male", "Female"),
    Provider.Credential.Text = c("MD", "MD"),
    stringsAsFactors = FALSE
  )
  sent <- suppressMessages(
    mysterycall_demographics_sentence(df, subspecialty_col = NULL)
  )
  expect_false(grepl("subspecialty", sent, ignore.case = FALSE))
  expect_match(sent, "MD")
})

test_that("credential_col = NULL omits credential clause", {
  df <- data.frame(
    gender       = c("Female", "Male", "Female"),
    Subspecialty = c("REI", "MFM", "REI"),
    stringsAsFactors = FALSE
  )
  sent <- suppressMessages(
    mysterycall_demographics_sentence(df, credential_col = NULL)
  )
  expect_false(grepl("qualification", sent))
  expect_match(sent, "REI")
})

test_that("error on non-data-frame input", {
  expect_error(
    mysterycall_demographics_sentence(list(gender = "Male")),
    "data.frame"
  )
})

test_that("error when gender_col not found", {
  df <- data.frame(sex = "Male", stringsAsFactors = FALSE)
  expect_error(
    mysterycall_demographics_sentence(df, gender_col = "gender"),
    "missing"
  )
})

test_that("error when subspecialty_col not found in data", {
  df <- data.frame(
    gender = c("Male", "Female"),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_demographics_sentence(df, subspecialty_col = "Subspecialty"),
    "missing"
  )
})

test_that("single-level factor still forms a sentence", {
  df <- data.frame(
    gender                   = rep("Female", 5),
    Subspecialty             = rep("MFM", 5),
    Provider.Credential.Text = rep("MD", 5),
    stringsAsFactors = FALSE
  )
  sent <- suppressMessages(mysterycall_demographics_sentence(df))
  expect_match(sent, "Female")
  expect_match(sent, "100.0")
})

test_that("custom labels appear in sentence", {
  df <- data.frame(
    sex  = c("M", "M", "F"),
    spec = c("A", "B", "A"),
    stringsAsFactors = FALSE
  )
  sent <- suppressMessages(
    mysterycall_demographics_sentence(
      df,
      gender_col        = "sex",
      subspecialty_col  = "spec",
      credential_col    = NULL,
      label_gender      = "doctor sex",
      label_subspecialty = "division"
    )
  )
  expect_match(sent, "doctor sex")
  expect_match(sent, "division")
})

test_that("digits parameter controls decimal places", {
  df <- data.frame(
    gender                   = c("Male", "Male", "Female"),
    stringsAsFactors = FALSE
  )
  sent_d0 <- suppressMessages(
    mysterycall_demographics_sentence(df, subspecialty_col = NULL,
                                      credential_col = NULL, digits = 0)
  )
  expect_match(sent_d0, "67%")

  sent_d2 <- suppressMessages(
    mysterycall_demographics_sentence(df, subspecialty_col = NULL,
                                      credential_col = NULL, digits = 2)
  )
  expect_match(sent_d2, "66.67%")
})

test_that("large counts formatted with commas", {
  df <- data.frame(
    gender = rep(c("Male", "Female"), c(1500, 500)),
    stringsAsFactors = FALSE
  )
  sent <- suppressMessages(
    mysterycall_demographics_sentence(df, subspecialty_col = NULL,
                                      credential_col = NULL)
  )
  # scales::comma should produce "1,500" and "2,000"
  expect_match(sent, "1,500")
  expect_match(sent, "2,000")
})

test_that("all-NA gender returns NA level gracefully", {
  df <- data.frame(
    gender = as.character(c(NA, NA, NA)),
    stringsAsFactors = FALSE
  )
  # Should not error; level will be NA
  sent <- suppressMessages(
    mysterycall_demographics_sentence(df, subspecialty_col = NULL,
                                      credential_col = NULL)
  )
  expect_type(sent, "character")
})
