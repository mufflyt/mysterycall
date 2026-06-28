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


test_that("mysterycall:::mysterycall_tempdir() returns character path to base mysterycall directory", {
  result <- mysterycall:::mysterycall_tempdir()
  expect_type(result, "character")
  expect_length(result, 1L)
  expect_true(grepl("mysterycall", result, fixed = TRUE))
  expect_true(grepl(tempdir(), result, fixed = TRUE))
})


test_that("mysterycall:::mysterycall_tempdir() with subdir components builds correct path", {
  result <- mysterycall:::mysterycall_tempdir("logs", "session_001")
  expect_type(result, "character")
  expect_length(result, 1L)
  expect_true(grepl("mysterycall", result, fixed = TRUE))
  expect_true(grepl("logs", result, fixed = TRUE))
  expect_true(grepl("session_001", result, fixed = TRUE))
})


test_that("mysterycall:::mysterycall_tempdir(create=FALSE) does not create directory", {
  test_path <- mysterycall:::mysterycall_tempdir("test_nocreate_xyz")
  expect_false(dir.exists(test_path))
  result <- mysterycall:::mysterycall_tempdir("test_nocreate_xyz", create = FALSE)
  expect_false(dir.exists(result))
})


test_that("mysterycall:::mysterycall_tempdir(create=TRUE) creates directory with recursive=TRUE", {
  test_path <- mysterycall:::mysterycall_tempdir("nested", "deep", "path", "structure")
  # Clean up if it exists from prior runs
  if (dir.exists(test_path)) {
    unlink(test_path, recursive = TRUE)
  }

  expect_false(dir.exists(test_path))
  result <- mysterycall:::mysterycall_tempdir("nested", "deep", "path", "structure", create = TRUE)
  expect_true(dir.exists(result))
  expect_equal(result, test_path)
})


test_that("mysterycall:::mysterycall_tempdir(create=TRUE) idempotent: calling twice succeeds", {
  test_path <- mysterycall:::mysterycall_tempdir("idempotent_test_xyz")
  # Clean up if it exists
  if (dir.exists(test_path)) {
    unlink(test_path, recursive = TRUE)
  }

  result1 <- mysterycall:::mysterycall_tempdir("idempotent_test_xyz", create = TRUE)
  expect_true(dir.exists(result1))

  # Call again - should not fail
  result2 <- mysterycall:::mysterycall_tempdir("idempotent_test_xyz", create = TRUE)
  expect_true(dir.exists(result2))
  expect_equal(result1, result2)
})
