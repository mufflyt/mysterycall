#' Rename columns by substring match
#'
#' For each `target_strings[i]`, finds the first column whose name contains
#' that substring and renames it to `new_names[i]`. When multiple columns
#' match, the first match is used and a warning is issued. When no column
#' matches, a message is emitted and that rename is skipped.
#'
#' @param data A data frame whose columns need renaming.
#' @param target_strings Character vector of substrings to search for within
#'   column names. Must be the same length as `new_names`.
#' @param new_names Character vector of replacement column names, aligned with
#'   `target_strings`.
#' @return A data frame with matched columns renamed. Unmatched targets are
#'   silently skipped; a warning is issued when multiple columns match.
#' @family data management
#' @export
#' @importFrom stats setNames
#' @importFrom utils head
#' @examples
#' df <- data.frame(
#'   doctor_info = 1:5,
#'   patient_contact_data = 6:10
#' )
#' # Renaming 'doctor_info' to 'physician_info'
#' df <- mysterycall_rename_columns(df,
#'                                   target_strings = c("doctor"),
#'                                   new_names = c("physician_info"))
#' print(df)
#'
#' # More complex example with multiple renamings
#' df <- data.frame(
#'   doc_information = 1:5,
#'   patient_contact = 6:10,
#'   doctor_notes = 11:15
#' )
#' # Renaming 'doc_information' to 'doctor_info' and 'doctor_notes' to 'notes'
#' df <- mysterycall_rename_columns(df,
#'                                   target_strings = c("doc_information", "doctor_notes"),
#'                                   new_names = c("doctor_info", "notes"))
#' print(df)
mysterycall_rename_columns <- function(data, target_strings, new_names) {
  # Initial checks and setup
  validate_dataframe(data, name = "data")
  if (!length(target_strings) && !length(new_names)) {
    return(invisible(data))
  }
  checkmate::assert_character(target_strings, any.missing = FALSE, min.len = 1, .var.name = "target_strings")
  checkmate::assert_character(new_names, any.missing = FALSE, min.len = 1, .var.name = "new_names")

  if (length(target_strings) != length(new_names)) {
    stop("target_strings and new_names must have the same length.", call. = FALSE)
  }
  if (any(!nzchar(trimws(target_strings)))) {
    stop("`target_strings` cannot contain empty or whitespace-only entries.", call. = FALSE)
  }
  if (any(!nzchar(trimws(new_names)))) {
    stop("`new_names` cannot contain empty or whitespace-only entries.", call. = FALSE)
  }

  message("--- Starting to search and rename columns based on target substrings ---")
  # Loop over all target strings
  rename_log <- list()
  rename_index <- 0L
  for (i in seq_along(target_strings)) {
    target <- tolower(trimws(target_strings[i]))
    replacement <- trimws(new_names[i])
    normalized_names <- tolower(names(data))

    # Prefer exact case-insensitive matches first.
    matches <- normalized_names == target
    # Fall back to substring matching to preserve historical behavior and
    # prevent downstream column mismatch errors when callers pass patterns.
    matched_by <- "exact"
    if (!any(matches)) {
      matches <- grepl(target, normalized_names, fixed = TRUE)
      matched_by <- "substring"
    }
    matched_cols <- names(data)[matches]

    # Detailed log of what matches were found
    if (any(matches)) {
      message(sprintf(
        "Matched %d column(s) by %s match for '%s': %s",
        sum(matches),
        matched_by,
        target_strings[i],
        paste(matched_cols, collapse = ", ")
      ))
      # Error if more than one match is found to avoid ambiguous renames.
      if (length(matched_cols) > 1) {
        warning(sprintf(
          "Multiple columns matched '%s': %s. Renaming only the first match.",
          target_strings[i],
          paste(matched_cols, collapse = ", ")
        ), call. = FALSE)
        matched_cols <- matched_cols[1]
      }
      # Rename the matching column
      if (replacement %in% names(data) && replacement != matched_cols[1]) {
        stop(sprintf(
          "Cannot rename '%s' to '%s' because '%s' already exists.",
          matched_cols[1], replacement, replacement
        ), call. = FALSE)
      }
      names(data)[which(matches)[1]] <- replacement
      rename_index <- rename_index + 1L
      rename_log[[rename_index]] <- data.frame(
        pattern = target_strings[i],
        renamed_from = matched_cols[1],
        renamed_to = replacement,
        stringsAsFactors = FALSE
      )
      message(sprintf(
        "Renamed '%s' to '%s'.",
        matched_cols[1],
        replacement
      ))
    } else {
      warning(sprintf("No columns matched '%s'; nothing was renamed for this pattern.", target_strings[i]))
    }
    message("")  # Adding a blank line for better separation
  }

  message(sprintf(
    "--- Column renaming complete. Final column set: %s ---",
    paste(names(data), collapse = ", ")
  ))
  if (length(rename_log)) {
    attr(data, "rename_log") <- do.call(rbind, rename_log)
  }
  return(data)
}

#' Clean and process Phase 2 data
#'
#' This function reads data from a file or data frame, cleans column names, and applies renaming based on specified criteria to facilitate data analysis. The function logs each step of the process, including data loading, column cleaning, and renaming for transparency.
#'
#' @param data_or_path Path to the data file or a data frame.
#' @param required_strings Vector of substrings for which to search in column names.
#' @param standard_names Character vector of replacement names, the same length
#'   as `required_strings`, applied to matched columns in order.
#' @param output_directory Directory where the cleaned dataset should be written.
#'   Defaults to a session-specific folder inside [tempdir()] when not provided.
#' @param output_format File format to use when persisting the cleaned dataset.
#'   Supported values are "csv" (default) and "parquet".
#' @return A data frame with processed data.
#'
#' @section Column name transformation:
#'   All input column names are converted to **lowercase snake_case** by
#'   [janitor::clean_names()] **unconditionally** before `required_strings`
#'   pattern matching. Transformation cannot be disabled. Common examples:
#'   \tabular{ll}{
#'     **Input column name** \tab **After `clean_names()`** \cr
#'     `"Physician Information"` \tab `"physician_information"` \cr
#'     `"NPI Number"` \tab `"npi_number"` \cr
#'     `"Q1-2023 Revenue"` \tab `"q1_2023_revenue"` \cr
#'     `"able_to_contact_office"` \tab `"able_to_contact_office"` (unchanged) \cr
#'     `"ContactOfficeYN"` \tab `"contact_office_yn"`
#'   }
#'   To preview the exact names your data will have, run
#'   `names(janitor::clean_names(your_data))` before calling this function,
#'   then write `required_strings` to match those transformed names.
#'
#' @section Output file timestamps:
#'   Output filenames include a timestamp from [Sys.time()], which uses the
#'   **local system timezone** (not UTC). Filenames produced on systems in
#'   different timezones will reflect different local times for the same
#'   wall-clock moment. To force UTC filenames, wrap the call:
#'   ```r
#'   withr::with_timezone("UTC", {
#'     mysterycall_clean_phase2(data, required_strings, standard_names)
#'   })
#'   ```
#'
#' @seealso [mysterycall_clean_phase1()] for Phase 1 data cleaning;
#'   [mysterycall_run_workflow()] which orchestrates both phases;
#'   [mysterycall_rename_columns()] for the underlying column-renaming logic.
#' @family workflow
#' @export
#' @importFrom readr read_csv write_csv
#' @importFrom dplyr filter mutate
#' @importFrom janitor clean_names
#' @examplesIf interactive()
#' # Assuming an input path to a CSV file
#' input_path <- "path_to_your_data.csv"
#' required_strings <- c("physician_information", "able_to_contact_office")
#' standard_names <- c("physician_info", "contact_office")
#' cleaned_data <- mysterycall_clean_phase2(input_path, required_strings, standard_names)
#'
#' # Directly using a data frame
#' df <- data.frame(
#'   doc_info = 1:5,
#'   contact_data = 6:10
#' )
#' required_strings <- c("doc_info", "contact_data")
#' standard_names <- c("doctor_info", "patient_contact_info")
#' cleaned_df <- mysterycall_clean_phase2(df, required_strings, standard_names)
#' print(cleaned_df)
mysterycall_clean_phase2 <- function(
  data_or_path,
  required_strings,
  standard_names,
  output_directory = NULL,
  output_format = c("csv", "parquet")
) {
  output_format <- match.arg(output_format)
  # Data loading and initial checks
  if (is.character(data_or_path)) {
    if (!file.exists(data_or_path)) {
      stop("File does not exist at the specified path: ", data_or_path, call. = FALSE)
    }
    input_format <- mysterycall_normalize_file_format(path = data_or_path)
    data <- mysterycall_read_table(data_or_path, format = input_format)
    message(sprintf("Loaded Phase 2 data from %s with %d row(s) and %d column(s).", data_or_path, nrow(data), ncol(data)))
  } else if (is.data.frame(data_or_path)) {
    data <- data_or_path
    message(sprintf("Loaded Phase 2 data from provided data frame with %d row(s) and %d column(s).", nrow(data), ncol(data)))
  } else {
    stop("Data input must be either a dataframe or a valid file path.", call. = FALSE)
  }

  validate_dataframe(data, name = "phase2_data")

  if (missing(required_strings) || !length(required_strings)) {
    stop("`required_strings` must supply at least one pattern to search for.", call. = FALSE)
  }
  if (missing(standard_names) || !length(standard_names)) {
    stop("`standard_names` must supply at least one column name to apply.", call. = FALSE)
  }
  if (length(required_strings) != length(standard_names)) {
    stop("`required_strings` and `standard_names` must have the same length.", call. = FALSE)
  }

  if (length(unique(standard_names)) != length(standard_names)) {
    warning("Duplicate values detected in `standard_names`; later entries may overwrite earlier renames.")
  }

  # Clean and standardize column names
  data <- janitor::clean_names(data)
  message("Converted column names to snake_case format.")

  # Apply the renaming function with detailed logging
  data <- mysterycall_rename_columns(data, required_strings, standard_names)
  rename_log <- attr(data, "rename_log")
  if (!is.null(rename_log)) {
    message("Summary of applied renames:")
    for (line in utils::capture.output(print(rename_log))) message(line)
  }
  message("Standardized Phase 2 column names based on required patterns.")

  # Validate post-rename schema: every standard_name must be present
  missing_after_rename <- setdiff(standard_names, names(data))
  if (length(missing_after_rename)) {
    warning(sprintf(
      "Phase 2 schema validation: %d expected column(s) missing after renaming: %s. Available: %s",
      length(missing_after_rename),
      paste(missing_after_rename, collapse = ", "),
      paste(names(data), collapse = ", ")
    ), call. = FALSE)
  }

  # Additional data processing
  message("Proceeding with additional data processing steps...")

  available_standard <- intersect(standard_names, names(data))
  if (length(available_standard)) {
    data <- dplyr::select(data, dplyr::all_of(available_standard), dplyr::everything())
  }

  # Saving the cleaned data
  if (is.null(output_directory)) {
    output_directory <- mysterycall_tempdir("phase2", create = TRUE)
  } else if (!dir.exists(output_directory)) {
    dir.create(output_directory, recursive = TRUE, showWarnings = FALSE)
  }

  current_datetime <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  output_extension <- if (identical(output_format, "parquet")) ".parquet" else ".csv"
  output_file_path <- file.path(output_directory, paste0("cleaned_phase_2_data_", current_datetime, output_extension))
  mysterycall_write_table(data, output_file_path, format = output_format)
  message(sprintf("Cleaned Phase 2 data (%d row(s), %d column(s)) saved to: %s", nrow(data), ncol(data), output_file_path))

  attr(data, "output_path") <- output_file_path

  return(data)
}

# Example usage
# required_strings <- c("physician_information", "able_to_contact_office", "are_we_including",
#                       "reason_for_exclusions", "appointment_date", "number_of_transfers",
#                       "call_time", "hold_time", "notes", "person_completing")
# standard_names <- c("physician_info", "contact_office", "included_in_study",
#                     "exclusion_reasons", "appt_date", "transfer_count",
#                     "call_duration", "hold_duration", "notes", "completed_by")

# Assuming an input path, you would run it like this:
# input_file <- "/path/to/your/data.csv"
# cleaned_data <- mysterycall_clean_phase2(input_file, required_strings, standard_names)
