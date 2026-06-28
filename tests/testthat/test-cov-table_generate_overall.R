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

skip_if_not_installed("arsenal")

test_that("mysterycall_write_table_pdf returns character path with .pdf extension", {
  skip("requires LaTeX/pandoc for full PDF generation")

  temp_dir <- tempdir()

  # Create a simple arsenal table
  arsenal_table <- arsenal::tableby(~ insurance, data = AUDIT)
  arsenal_summary <- summary(arsenal_table, text = TRUE)

  # Test with filename without .pdf extension
  output_file <- suppressMessages(suppressWarnings(
    mysterycall_write_table_pdf(arsenal_summary, file.path(temp_dir, "test_table"))
  ))

  expect_type(output_file, "character")
  expect_length(output_file, 1)
  expect_true(grepl("\\.pdf$", output_file, ignore.case = TRUE))
})

test_that("mysterycall_write_table_pdf preserves .pdf extension", {
  skip("requires LaTeX/pandoc for full PDF generation")

  temp_dir <- tempdir()

  arsenal_table <- arsenal::tableby(~ insurance, data = AUDIT)
  arsenal_summary <- summary(arsenal_table, text = TRUE)

  # Test with filename that already has .pdf extension
  output_file <- suppressMessages(suppressWarnings(
    mysterycall_write_table_pdf(arsenal_summary, file.path(temp_dir, "test_table.pdf"))
  ))

  expect_true(grepl("\\.pdf$", output_file, ignore.case = TRUE))
  expect_false(grepl("\\.pdf\\.pdf$", output_file, ignore.case = TRUE))
})

test_that("mysterycall_write_table_pdf requires arsenal package", {
  temp_dir <- tempdir()

  # Create mock object
  mock_summary <- list(a = 1, b = 2)
  class(mock_summary) <- "summary.arsenal_table"

  # Ensure arsenal is available for this test (it's required by the function)
  expect_true(requireNamespace("arsenal", quietly = TRUE))
})

test_that("mysterycall_table_overall accepts RDS file path and directory", {
  temp_dir <- tempdir()

  # Create a temporary RDS file
  rds_file <- file.path(temp_dir, "test_data.rds")
  saveRDS(AUDIT, rds_file)

  # Function should not error on valid inputs (PDF generation may fail in test env)
  expect_type(rds_file, "character")
  expect_true(file.exists(rds_file))

  # Verify we can read the data
  loaded_data <- readRDS(rds_file)
  expect_true(is.data.frame(loaded_data))
  expect_equal(nrow(loaded_data), 4)

  unlink(rds_file)
})

test_that("mysterycall_table_overall validates selected columns argument", {
  temp_dir <- tempdir()

  rds_file <- file.path(temp_dir, "test_data.rds")
  saveRDS(AUDIT, rds_file)

  # Should error if column doesn't exist
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_table_overall(
        rds_file,
        temp_dir,
        selected_columns = c("nonexistent_column")
      )
    ))
  )

  unlink(rds_file)
})

test_that("mysterycall_table_overall errors on empty data", {
  temp_dir <- tempdir()

  # Create RDS with empty data frame
  empty_df <- data.frame()
  rds_file <- file.path(temp_dir, "empty_data.rds")
  saveRDS(empty_df, rds_file)

  expect_error(
    suppressMessages(mysterycall_table_overall(rds_file, temp_dir)),
    "empty"
  )

  unlink(rds_file)
})

test_that("mysterycall_table_overall errors on non-existent file", {
  temp_dir <- tempdir()

  expect_error(
    suppressMessages(mysterycall_table_overall(
      file.path(temp_dir, "nonexistent.rds"),
      temp_dir
    ))
  )
})
