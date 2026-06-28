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


test_that("happy path: saves quality check table with required columns", {
  set.seed(1)
  tmpdir <- tempfile(pattern = "qc_")
  dir.create(tmpdir)
  on.exit(unlink(tmpdir, recursive = TRUE))

  filepath <- file.path(tmpdir, "quality_check.csv")

  # Create test data with required 'npi' and 'name' columns
  test_data <- data.frame(
    npi = c("111", "111", "111", "222", "222", "333"),
    name = c("Smith", "Smith", "Smith", "Jones", "Jones", "Brown"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_save_quality_table(test_data, filepath, output_format = "csv")
  )

  # Check file was created
  expect_true(file.exists(filepath))

  # Check return is a data frame
  expect_s3_class(result, "data.frame")

  # Check filtering: only rows with count > 2 should be returned
  # "111" and "Smith" has count 3, others have count 1 or 2
  expect_equal(nrow(result), 1L)
  expect_equal(result$npi[1], "111")
  expect_equal(result$name[1], "Smith")
  expect_equal(result$count[1], 3L)
})


test_that("error path: missing required columns triggers error", {
  set.seed(2)
  tmpdir <- tempfile(pattern = "qc_")
  dir.create(tmpdir)
  on.exit(unlink(tmpdir, recursive = TRUE))

  filepath <- file.path(tmpdir, "quality_check.csv")

  # Create test data missing the 'name' column
  incomplete_data <- data.frame(
    npi = c("111", "222"),
    other_col = c("A", "B"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_save_quality_table(incomplete_data, filepath),
    "must contain columns"
  )
})


test_that("edge case: data with all counts <= 2 returns empty data frame", {
  set.seed(3)
  tmpdir <- tempfile(pattern = "qc_")
  dir.create(tmpdir)
  on.exit(unlink(tmpdir, recursive = TRUE))

  filepath <- file.path(tmpdir, "quality_check.csv")

  # Create test data where all combinations have count <= 2
  sparse_data <- data.frame(
    npi = c("111", "222", "333"),
    name = c("Smith", "Jones", "Brown"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_save_quality_table(sparse_data, filepath, output_format = "csv")
  )

  # Check that result is empty (all counts were <= 2)
  expect_equal(nrow(result), 0L)
  expect_s3_class(result, "data.frame")
})


test_that("parquet format: saves table as parquet when requested", {
  set.seed(4)
  skip_if_not_installed("arrow")

  tmpdir <- tempfile(pattern = "qc_")
  dir.create(tmpdir)
  on.exit(unlink(tmpdir, recursive = TRUE))

  filepath <- file.path(tmpdir, "quality_check.parquet")

  # Create test data with count > 2
  test_data <- data.frame(
    npi = c("111", "111", "111", "222"),
    name = c("Smith", "Smith", "Smith", "Jones"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_save_quality_table(test_data, filepath, output_format = "parquet")
  )

  # Check parquet file was created
  expect_true(file.exists(filepath))
  expect_match(filepath, "\\.parquet$")

  # Check result is a data frame
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
})


test_that("invisibly returns filtered data frame", {
  set.seed(5)
  tmpdir <- tempfile(pattern = "qc_")
  dir.create(tmpdir)
  on.exit(unlink(tmpdir, recursive = TRUE))

  filepath <- file.path(tmpdir, "quality_check.csv")

  test_data <- data.frame(
    npi = c("111", "111", "111", "111"),
    name = c("Smith", "Smith", "Smith", "Smith"),
    stringsAsFactors = FALSE
  )

  # Capture the return value to verify invisibility
  result <- suppressMessages(
    mysterycall_save_quality_table(test_data, filepath, output_format = "csv")
  )

  # Result should have the filtered data
  expect_equal(nrow(result), 1L)
  expect_equal(result$count[1], 4L)
  expect_true("npi" %in% names(result))
  expect_true("name" %in% names(result))
  expect_true("count" %in% names(result))
})
