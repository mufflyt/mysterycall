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

test_that("mysterycall_split_and_save returns character vector of file paths with valid inputs", {
  skip_if_not_installed("openxlsx")

  out_dir <- tempdir()
  test_data <- data.frame(
    for_redcap = 1:6,
    id = letters[1:6],
    doctor_id = rep(c("DOC1", "DOC2", "DOC3"), 2),
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), 3),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_split_and_save(
      data_or_path = test_data,
      output_directory = out_dir,
      lab_assistant_names = c("Assistant_A", "Assistant_B"),
      seed = 1,
      insurance_order = c("Medicaid", "Blue Cross/Blue Shield")
    )
  )

  expect_type(result, "character")
  expect_true(length(result) >= 2)
})

test_that("mysterycall_split_and_save requires at least 2 lab assistant names", {
  skip_if_not_installed("openxlsx")

  out_dir <- tempdir()
  test_data <- data.frame(
    for_redcap = 1:2,
    id = c("a", "b"),
    doctor_id = c("D1", "D2"),
    insurance = c("Medicaid", "Blue Cross/Blue Shield"),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      mysterycall_split_and_save(
        data_or_path = test_data,
        output_directory = out_dir,
        lab_assistant_names = c("OnlyOne"),
        insurance_order = c("Medicaid", "Blue Cross/Blue Shield")
      )
    ),
    "at least two"
  )
})

test_that("mysterycall_split_and_save errors when required columns are missing", {
  skip_if_not_installed("openxlsx")

  out_dir <- tempdir()
  incomplete_data <- data.frame(
    id = c("a", "b"),
    doctor_id = c("D1", "D2"),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      mysterycall_split_and_save(
        data_or_path = incomplete_data,
        output_directory = out_dir,
        lab_assistant_names = c("A", "B"),
        insurance_order = c("Medicaid", "Blue Cross/Blue Shield")
      )
    ),
    "missing"
  )
})

test_that("mysterycall_split_and_save warns when insurance column has NA values", {
  skip_if_not_installed("openxlsx")

  out_dir <- tempdir()
  data_with_na <- data.frame(
    for_redcap = 1:3,
    id = c("a", "b", "c"),
    doctor_id = c("D1", "D2", "D3"),
    insurance = c(NA, "Medicaid", "Blue Cross/Blue Shield"),
    stringsAsFactors = FALSE
  )

  result <- expect_warning(
    suppressMessages(
      mysterycall_split_and_save(
        data_or_path = data_with_na,
        output_directory = out_dir,
        lab_assistant_names = c("A", "B"),
        insurance_order = c("Medicaid", "Blue Cross/Blue Shield")
      )
    ),
    "NA insurance"
  )

  expect_true(!is.null(result))
})

test_that("mysterycall_split_and_save errors on unknown insurance values not in insurance_order", {
  skip_if_not_installed("openxlsx")

  out_dir <- tempdir()
  bad_insurance_data <- data.frame(
    for_redcap = 1:2,
    id = c("a", "b"),
    doctor_id = c("D1", "D2"),
    insurance = c("UnknownInsurance", "Medicaid"),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      mysterycall_split_and_save(
        data_or_path = bad_insurance_data,
        output_directory = out_dir,
        lab_assistant_names = c("A", "B"),
        insurance_order = c("Medicaid", "Blue Cross/Blue Shield")
      )
    ),
    "not in insurance_order"
  )
})

test_that("mysterycall_split_and_save handles empty dataframe gracefully", {
  skip_if_not_installed("openxlsx")

  out_dir <- tempdir()
  empty_data <- data.frame(
    for_redcap = integer(0),
    id = character(0),
    doctor_id = character(0),
    insurance = character(0),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_split_and_save(
      data_or_path = empty_data,
      output_directory = out_dir,
      lab_assistant_names = c("A", "B"),
      insurance_order = c("Medicaid", "Blue Cross/Blue Shield")
    )
  )

  expect_type(result, "character")
  expect_true(length(result) >= 1)
})

test_that("mysterycall_split_and_save errors on invalid input type (not dataframe or path)", {
  skip_if_not_installed("openxlsx")

  out_dir <- tempdir()

  expect_error(
    suppressMessages(
      mysterycall_split_and_save(
        data_or_path = list(a = 1, b = 2),
        output_directory = out_dir,
        lab_assistant_names = c("A", "B"),
        insurance_order = c("Medicaid", "Blue Cross/Blue Shield")
      )
    ),
    "dataframe or a valid file path"
  )
})

test_that("mysterycall_split_and_save respects seed parameter for reproducibility", {
  skip_if_not_installed("openxlsx")

  out_dir <- tempdir()
  test_data <- data.frame(
    for_redcap = 1:12,
    id = letters[1:12],
    doctor_id = rep(c("D1", "D2", "D3", "D4"), 3),
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), 6),
    stringsAsFactors = FALSE
  )

  set.seed(2)
  result1 <- suppressMessages(
    mysterycall_split_and_save(
      data_or_path = test_data,
      output_directory = out_dir,
      lab_assistant_names = c("A", "B", "C"),
      seed = 42,
      insurance_order = c("Medicaid", "Blue Cross/Blue Shield")
    )
  )

  set.seed(2)
  result2 <- suppressMessages(
    mysterycall_split_and_save(
      data_or_path = test_data,
      output_directory = out_dir,
      lab_assistant_names = c("A", "B", "C"),
      seed = 42,
      insurance_order = c("Medicaid", "Blue Cross/Blue Shield")
    )
  )

  expect_type(result1, "character")
  expect_type(result2, "character")
  expect_length(result1, length(result2))
})
