library(testthat)
testthat::skip_if_not_installed("dplyr")
if (!requireNamespace("openxlsx", quietly = TRUE)) {
  testthat::skip("Package 'openxlsx' is not installed")
} else {
  library(openxlsx)
}
library(dplyr)

# Test if the function stops when required columns are missing
test_that("Missing required columns handling", {
  # Creating a dataframe intentionally missing the required 'for_redcap', 'id', and 'doctor_id' columns
  test_data <- data.frame(
    not_for_redcap = 1:4,
    not_id = 1:4,
    stringsAsFactors = FALSE
  )

  # Testing if the function throws the correct error when required columns are missing
  expect_error(
    mysterycall_split_and_save(data_or_path = test_data, output_directory = tempdir(), lab_assistant_names = c("Alice", "Bob")),
    "The input data is missing the following columns: for_redcap, id, doctor_id",
    fixed = TRUE  # Ensures that the error message matches exactly
  )
})


# Revised Test: Correct assignment of lab assistants
test_that("Correct assignment of lab assistants", {
  # Setup
  output_dir <- tempdir()

  # Ensure directory is empty
  unlink(list.files(output_dir, full.names = TRUE), recursive = TRUE)

  # Sample data simulating multiple entries, including 'doctor_id'
  data <- data.frame(
    for_redcap = 1:6,
    id = 1:6,
    doctor_id = rep(1:3, each = 2),  # Assuming 3 doctors, 2 records each
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), length.out = 6),
    stringsAsFactors = FALSE
  )

  lab_assistant_names <- c("Tyler", "Cristina")

  # Run function
  suppressMessages(suppressWarnings({
    mysterycall_split_and_save(
      data_or_path = data,
      output_directory = output_dir,
      lab_assistant_names = lab_assistant_names
    )
  }))

  # Check file creation and contents
  output_files <- list.files(output_dir, pattern = "\\.xlsx$", full.names = TRUE)
  expect_length(output_files, length(lab_assistant_names) + 1) # +1 for the complete file

  for (file in output_files) {
    if (!grepl("complete_non_split_version", file)) {
      sheet_data <- openxlsx::read.xlsx(file)
      # Extract the lab assistant name from the file name
      lab_name <- gsub("_.*$", "", basename(file))

      # Log the lab assistant name and the contents of the sheet_data
      cat("Checking file:", file, "\n")
      cat("Expected lab assistant:", lab_name, "\n")
      cat("Lab assistants assigned in file:", unique(sheet_data$lab_assistant_assigned), "\n")

      # Test if all entries are assigned to the correct lab assistant
      expect_true(all(sheet_data$lab_assistant_assigned == lab_name),
                  label = paste("All entries in", file, "should be assigned to", lab_name))
    }
  }
})

test_that("Invalid file path handling", {
  expect_error(
    mysterycall_split_and_save(data_or_path = "nonexistent/path/data.csv", output_directory = tempdir(), lab_assistant_names = c("Alice", "Bob")),
    "File does not exist at the specified path",
    fixed = TRUE
  )
})

test_that("Insufficient lab assistant names handling", {
  data <- data.frame(for_redcap = 1:4, id = 1:4, doctor_id = 1:4,
                     insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), 2),
                     stringsAsFactors = FALSE)
  expect_error(
    mysterycall_split_and_save(data_or_path = data, output_directory = tempdir(), lab_assistant_names = c("Alice")),
    "Please provide at least two lab assistant names for the splits.",
    fixed = TRUE
  )
})

# Regression (BUG 25): round-robin must be balanced across the WHOLE roster,
# not restart within each insurance group (which skewed counts by >1).
test_that("Assignment is balanced within one row across the full frame", {
  output_dir <- file.path(tempdir(), paste0("split_balance_", as.integer(Sys.time())))
  dir.create(output_dir, showWarnings = FALSE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  data <- data.frame(
    for_redcap = 1:10,
    id         = 1:10,
    doctor_id  = 1:10,
    insurance  = rep(c("Medicaid", "Blue Cross/Blue Shield"), length.out = 10),
    stringsAsFactors = FALSE
  )
  lab_assistant_names <- c("Ann", "Bob", "Cy")

  suppressMessages(suppressWarnings(
    mysterycall_split_and_save(
      data_or_path        = data,
      output_directory    = output_dir,
      lab_assistant_names = lab_assistant_names
    )
  ))

  complete_file <- list.files(output_dir, pattern = "complete_non_split_version",
                              full.names = TRUE)
  combined <- openxlsx::read.xlsx(complete_file[[1]])
  counts   <- table(combined$lab_assistant_assigned)
  expect_lte(max(counts) - min(counts), 1L)
})

# Regression (BUG 26): output must follow roster order and include empty
# assistants as zero-row workbooks (base::split() dropped them).
test_that("Every roster name gets a workbook, including zero-row assistants", {
  output_dir <- file.path(tempdir(), paste0("split_roster_", as.integer(Sys.time())))
  dir.create(output_dir, showWarnings = FALSE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  data <- data.frame(
    for_redcap = 1:2,
    id         = 1:2,
    doctor_id  = 1:2,
    insurance  = c("Medicaid", "Blue Cross/Blue Shield"),
    stringsAsFactors = FALSE
  )
  # More assistants than rows -> at least two assistants receive zero rows.
  lab_assistant_names <- c("Ann", "Bob", "Cy", "Dee")

  paths <- suppressMessages(suppressWarnings(
    mysterycall_split_and_save(
      data_or_path        = data,
      output_directory    = output_dir,
      lab_assistant_names = lab_assistant_names
    )
  ))

  # One combined workbook + one per assistant, in roster order.
  expect_length(paths, length(lab_assistant_names) + 1L)
  for (i in seq_along(lab_assistant_names)) {
    expect_true(grepl(lab_assistant_names[[i]], basename(paths[[i + 1L]]), fixed = TRUE))
    expect_true(file.exists(paths[[i + 1L]]))
  }
})
