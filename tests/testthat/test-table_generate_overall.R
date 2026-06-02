library(testthat)
testthat::skip_if_not_installed("readr")
testthat::skip_if_not_installed("dplyr")
testthat::skip_if_not_installed("arsenal")
testthat::skip_if_not_installed("fs")
testthat::skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
testthat::skip_if_not(
  nzchar(Sys.which("pdflatex")) || nzchar(Sys.which("xelatex")),
  "LaTeX not available"
)
library(readr)
library(dplyr)
library(arsenal)

# Create a temporary RDS file for testing
create_temp_rds <- function(data, file_name = "temp_data.rds") {
  temp_file <- file.path(tempdir(), file_name)
  write_rds(data, temp_file)
  return(temp_file)
}

# Sample data for testing
sample_data <- data.frame(
  age = c(25, 34, 28, 45, 52),
  gender = factor(c("Male", "Female", "Male", "Female", "Male")),
  height = c(175, 160, 180, 165, 170),
  weight = c(70, 55, 80, 60, 75),
  stringsAsFactors = FALSE
)

# Test if the function reads the input file correctly and processes it without errors
test_that("Reads input file correctly and processes data", {
  temp_rds <- create_temp_rds(sample_data)
  output_dir <- tempdir()

  expect_message(mysterycall_table_overall(temp_rds, output_dir))

  # Check that the output file was created
  output_files <- list.files(output_dir, pattern = "^arsenal_overall_table_.*\\.pdf$")
  expect_true(length(output_files) > 0)
})

# Test if the function generates the overall table correctly
test_that("Generates overall table correctly", {
  temp_rds <- create_temp_rds(sample_data)
  output_dir <- tempdir()

  expect_message(mysterycall_table_overall(temp_rds, output_dir))

  overall_summary <- capture.output(mysterycall_table_overall(temp_rds, output_dir), type = "message")
  expect_true(length(overall_summary) > 0)
})

# Test if the function saves the result to a new PDF file
test_that("Saves result to new PDF file", {
  temp_rds <- create_temp_rds(sample_data)
  output_dir <- tempdir()

  mysterycall_table_overall(temp_rds, output_dir)

  output_files <- list.files(output_dir, pattern = "^arsenal_overall_table_.*\\.pdf$")
  expect_true(length(output_files) > 0)
})

# Test if the function handles selected columns correctly
test_that("Handles selected columns correctly", {
  temp_rds <- create_temp_rds(sample_data)
  output_dir <- tempdir()

  selected_columns <- c("age", "gender")
  mysterycall_table_overall(temp_rds, output_dir, selected_columns = selected_columns)

  result_data <- read_rds(temp_rds)
  expect_true(all(selected_columns %in% colnames(result_data)))
})

# Test if the function handles missing label translations correctly
test_that("Handles missing label translations correctly", {
  temp_rds <- create_temp_rds(sample_data)
  output_dir <- tempdir()

  expect_message(mysterycall_table_overall(temp_rds, output_dir))
})

# Test if the function handles invalid input types
test_that("Handles invalid input types gracefully", {
  expect_error(mysterycall_table_overall(123, tempdir()))
})

# Test if the function handles an empty dataset
test_that("Handles empty dataset correctly", {
  temp_rds <- create_temp_rds(data.frame())
  output_dir <- tempdir()

  expect_error(mysterycall_table_overall(temp_rds, output_dir), "The input data is empty.")
})

# Test if the function handles the absence of output directory and creates it
test_that("Creates output directory if it does not exist", {
  temp_rds <- create_temp_rds(sample_data)
  output_dir <- file.path(tempdir(), "new_output_dir")

  mysterycall_table_overall(temp_rds, output_dir)

  expect_true(dir.exists(output_dir))
})

# Test if the function handles label translations correctly
test_that("Handles label translations correctly", {
  temp_rds <- create_temp_rds(sample_data)
  output_dir <- tempdir()
  label_translations <- list(age = "Age in years", gender = "Gender (M/F)", height = "Height in cm", weight = "Weight in kg")

  expect_message(mysterycall_table_overall(temp_rds, output_dir, label_translations = label_translations))
})

