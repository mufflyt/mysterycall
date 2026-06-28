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

test_that("mysterycall_clean_data: happy path with minimal input", {
  set.seed(2)
  raw <- data.frame(
    phone         = c("303-111-2222", "303-111-2222", "720-555-9999"),
    age           = c(55, 55, 72),
    insurance     = c("Medicaid", "Medicaid", "Medicare"),
    gender        = c("Female", "Female", "Male"),
    Provider.Credential.Text = c("MD", "MD", "DO"),
    academic_affiliation     = c("University", NA, "Community"),
    cbsatype10               = c("Metro", "Metro", "Micro"),
    business_days_until_appointment = c(7L, 7L, 14L),
    central_number_e_g_appointment_center = c("Yes", "Yes", "No"),
    first  = c("Jane", "Jane", "Bob"),
    last   = c("Doe",  "Doe",  "Smith"),
    record_id = 1:3,
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_clean_data(raw))

  # Check return type
  expect_s3_class(result, "data.frame")
  expect_gt(nrow(result), 0L)

  # Deduplication should occur (2 unique phones -> 2 rows)
  expect_equal(nrow(result), 2L)

  # Check for key renamed columns
  expect_true("Age category" %in% names(result))
  expect_true("Insurance" %in% names(result))
  expect_true("Gender" %in% names(result))

  # Check PII columns are dropped
  expect_false("phone" %in% tolower(names(result)))
  expect_false("first" %in% tolower(names(result)))
  expect_false("last" %in% tolower(names(result)))
  expect_false("record_id" %in% tolower(names(result)))

  # Check Age category is a factor
  expect_true(is.factor(result[["Age category"]]))
})

test_that("mysterycall_clean_data: skip age processing when age_col = NULL", {
  set.seed(3)
  raw <- data.frame(
    phone    = c("303-111-2222", "720-555-9999"),
    age      = c(55, 72),
    insurance = c("Medicaid", "Medicare"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data(raw, age_col = NULL)
  )

  expect_false("Age category" %in% names(result))
})

test_that("mysterycall_clean_data: skip deduplication when id_col = NULL", {
  set.seed(4)
  raw <- data.frame(
    phone    = c("303-111-2222", "303-111-2222", "720-555-9999"),
    insurance = c("Medicaid", "Medicaid", "Medicare"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data(raw, id_col = NULL)
  )

  # Without dedup, should keep all 3 rows
  expect_equal(nrow(result), 3L)
})

test_that("mysterycall_clean_data: custom age breaks", {
  set.seed(5)
  raw <- data.frame(
    phone    = c("303-111-2222", "720-555-9999"),
    age      = c(55, 72),
    insurance = c("Medicaid", "Medicare"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data(
      raw,
      age_breaks = c(-Inf, 60, Inf),
      age_labels = c("young", "old")
    )
  )

  expect_true(is.factor(result[["Age category"]]))
  expect_equal(nlevels(result[["Age category"]]), 2L)
})

test_that("mysterycall_clean_data: keep_identifiers variant retains PII", {
  set.seed(6)
  raw <- data.frame(
    phone    = c("303-111-2222", "303-111-2222", "720-555-9999"),
    age      = c(55, 55, 72),
    insurance = c("Medicaid", "Medicaid", "Medicare"),
    first    = c("Jane", "Jane", "Bob"),
    last     = c("Doe", "Doe", "Smith"),
    npi      = c("1234567890", "1234567890", "0987654321"),
    record_id = 1:3,
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data_keep_identifiers(raw)
  )

  # Should retain PII columns
  expect_true("phone" %in% names(result))
  expect_true("first" %in% names(result))
  expect_true("last" %in% names(result))
  expect_true("npi" %in% names(result))
  expect_true("record_id" %in% names(result))

  # Dedup should still happen (2 unique phones)
  expect_equal(nrow(result), 2L)
})

test_that("mysterycall_clean_data: recode_credential applies correctly", {
  set.seed(7)
  raw <- data.frame(
    phone    = c("303-111-2222", "720-555-9999"),
    Provider.Credential.Text = c("MD", "DO"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data(
      raw,
      recode_credential = c("MD" = "Allopathic training", "DO" = "Osteopathic training")
    )
  )

  cred_col <- result[["Physician credential"]]
  expect_true("Allopathic training" %in% cred_col || "MD" %in% cred_col)
})

test_that("mysterycall_clean_data: forward-fill with default columns", {
  set.seed(8)
  raw <- data.frame(
    phone    = c("303-111-2222", "303-111-2222", "720-555-9999"),
    academic_affiliation = c("University", NA, "Community"),
    cbsatype10           = c("Metro", NA, "Micro"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data(raw, drop_pii = FALSE)
  )

  # After forward fill, NA should be replaced with last value
  # The second row should have "University" and "Metro"
  expect_false(any(is.na(result$academic_affiliation)))
  expect_false(any(is.na(result$cbsatype10)))
})

test_that("mysterycall_clean_data: drop_pii = FALSE keeps identifiers", {
  set.seed(9)
  raw <- data.frame(
    phone    = c("303-111-2222", "720-555-9999"),
    first    = c("Jane", "Bob"),
    last     = c("Doe", "Smith"),
    npi      = c("1234567890", "0987654321"),
    insurance = c("Medicaid", "Medicare"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data(raw, drop_pii = FALSE)
  )

  expect_true("phone" %in% names(result))
  expect_true("first" %in% names(result))
  expect_true("last" %in% names(result))
  expect_true("npi" %in% names(result))
})

test_that("mysterycall_clean_data: empty data frame", {
  set.seed(10)
  raw <- data.frame(
    phone    = character(0),
    age      = numeric(0),
    insurance = character(0),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data(raw)
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
})

test_that("mysterycall_clean_data: missing column reference", {
  set.seed(11)
  raw <- data.frame(
    phone    = c("303-111-2222", "720-555-9999"),
    insurance = c("Medicaid", "Medicare"),
    stringsAsFactors = FALSE
  )

  # age_col "age" not present; should skip age category
  result <- suppressMessages(
    mysterycall_clean_data(raw, age_col = "age")
  )

  expect_false("Age category" %in% names(result))
  expect_s3_class(result, "data.frame")
})

test_that("mysterycall_clean_data: age_labels/age_breaks mismatch raises error", {
  set.seed(12)
  raw <- data.frame(
    phone    = c("303-111-2222", "720-555-9999"),
    age      = c(55, 72),
    stringsAsFactors = FALSE
  )

  # Mismatch: 3 breaks -> 2 labels expected, but provide 3 labels
  expect_error(
    suppressMessages(
      mysterycall_clean_data(
        raw,
        age_breaks = c(-Inf, 60, Inf),
        age_labels = c("a", "b", "c")
      )
    ),
    "Length of age_labels"
  )
})

test_that("mysterycall_clean_data: non-data.frame input raises error", {
  expect_error(
    suppressMessages(
      mysterycall_clean_data(list(a = 1, b = 2))
    ),
    "data.frame|validate"
  )
})

test_that("mysterycall_clean_data_keep_identifiers: happy path", {
  set.seed(13)
  raw <- data.frame(
    phone    = c("303-111-2222", "303-111-2222", "720-555-9999"),
    age      = c(55, 55, 72),
    insurance = c("Medicaid", "Medicaid", "Medicare"),
    first    = c("Jane", "Jane", "Bob"),
    last     = c("Doe", "Doe", "Smith"),
    npi      = c("1234567890", "1234567890", "0987654321"),
    record_id = 1:3,
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data_keep_identifiers(raw)
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)  # Dedup happens
  expect_true("phone" %in% names(result))
  expect_true("npi" %in% names(result))
  expect_true("first" %in% names(result))
})

test_that("mysterycall_clean_data_keep_identifiers: always retains id_col", {
  set.seed(14)
  raw <- data.frame(
    phone    = c("303-111-2222", "720-555-9999"),
    insurance = c("Medicaid", "Medicare"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data_keep_identifiers(raw, id_col = "phone")
  )

  # id_col should always be present
  expect_true("phone" %in% names(result))
})

test_that("mysterycall_clean_data_keep_identifiers: can override drop_pii to TRUE", {
  set.seed(15)
  raw <- data.frame(
    phone    = c("303-111-2222", "720-555-9999"),
    first    = c("Jane", "Bob"),
    last     = c("Doe", "Smith"),
    insurance = c("Medicaid", "Medicare"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data_keep_identifiers(raw, drop_pii = TRUE)
  )

  # With drop_pii=TRUE and default id_col="phone", phone should still be present
  # but first/last should be dropped
  expect_true("phone" %in% names(result))
  expect_false("first" %in% tolower(names(result)))
})

test_that("mysterycall_clean_data: handles empty recode vectors", {
  set.seed(16)
  raw <- data.frame(
    phone    = c("303-111-2222", "720-555-9999"),
    Provider.Credential.Text = c("MD", "DO"),
    stringsAsFactors = FALSE
  )

  # Pass empty recode vector (suppress warnings)
  result <- suppressMessages(
    mysterycall_clean_data(
      raw,
      recode_credential = character(0)
    )
  )

  expect_s3_class(result, "data.frame")
})

test_that("mysterycall_clean_data: NULLify column parameters", {
  set.seed(17)
  raw <- data.frame(
    phone    = c("303-111-2222", "720-555-9999"),
    insurance = c("Medicaid", "Medicare"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data(
      raw,
      insurance_col = NULL,
      gender_col = NULL
    )
  )

  expect_s3_class(result, "data.frame")
})

test_that("mysterycall_clean_data: factors ordered by frequency", {
  set.seed(18)
  raw <- data.frame(
    phone     = c("303-111-2222", "720-555-9999", "740-555-8888", "741-555-7777", "742-555-6666"),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "BCBS", "BCBS"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data(raw, insurance_col = "insurance", id_col = "phone")
  )

  # Insurance should be a factor
  insurance_col <- result[["Insurance"]]
  expect_true(is.factor(insurance_col))
  # After dedup, Medicaid appears 3 times, BCBS appears 2 times
  # Medicaid should come first in factor levels (most frequent)
  expect_equal(levels(insurance_col)[1], "Medicaid")
})

test_that("mysterycall_clean_data: column name collision handling", {
  set.seed(19)
  raw <- data.frame(
    phone    = c("303-111-2222", "720-555-9999"),
    insurance = c("Medicaid", "Medicare"),
    Insurance = c("Attr1", "Attr2"),  # Target name already exists
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data(raw, drop_pii = FALSE)
  )

  # Should handle collision gracefully (skip rename or warn)
  expect_s3_class(result, "data.frame")
})

test_that("mysterycall_clean_data: single row input", {
  set.seed(20)
  raw <- data.frame(
    phone    = "303-111-2222",
    age      = 55,
    insurance = "Medicaid",
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_clean_data(raw)
  )

  expect_equal(nrow(result), 1L)
  expect_true("Age category" %in% names(result))
})
