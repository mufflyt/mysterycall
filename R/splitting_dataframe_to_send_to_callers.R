#' Split data into multiple parts and save each part as separate Excel files
#'
#' This function splits the data based on provided lab assistant names and saves each part as a separate Excel file.
#' It allows the arrangement of calls by insurance type to prioritize Medicaid in the first two days and Blue Cross/Blue Shield in the last two days.
#' @name mysterycall_split_and_save
#' @param data_or_path Either a dataframe containing the input data or a path to the input data file (RDS, CSV, Parquet, or XLS/XLSX).
#' @param output_directory Directory where output Excel files will be saved.
#' @param lab_assistant_names Vector of lab assistant names to name the output files.
#' @param seed Seed value for randomization (default is 1978).
#' @param complete_file_prefix Prefix for the complete output file name (default is "complete_non_split_version_").
#' @param split_file_prefix Prefix for each split output file name (default is empty).
#' @param recursive_create Logical indicating if directories should be created recursively (default is TRUE).
#' @param insurance_order Vector of insurance types ordered by priority for call scheduling (default is c("Medicaid", "Blue Cross/Blue Shield")).
#'
#' @importFrom dplyr arrange mutate group_by ungroup n
#' @importFrom readr read_csv
#' @return `invisible()` character vector of absolute file paths to the
#'   created Excel files. Element 1 is the combined "all callers" workbook;
#'   subsequent elements are the per-assistant split workbooks in the order of
#'   `lab_assistant_names`. Capture with
#'   `paths <- mysterycall_split_and_save(...)` to use the paths downstream.
#'
#' @section Contract:
#' **Inputs:**
#' - `lab_assistant_names` must have \eqn{\geq} 2 entries; function errors if only
#'   one name is provided.
#' - `seed` controls the random assignment of rows to assistants; the same seed
#'   always produces the same split.
#' - `output_directory` is created if absent.
#'
#' **Guarantees:**
#' - Every input row appears in exactly one assistant's workbook (no row
#'   duplication, no silent omission).
#' - Workbooks are sorted by `insurance_order` so Medicaid rows appear first.
#' - A combined "all callers" workbook is written in addition to individual files.
#'
#' **Disaster Prevention:**
#' Prevents unequal workload distribution by using round-robin row assignment
#' rather than random block sampling, which can produce highly skewed splits
#' for small rosters.
#'
#' @section Performance:
#' O(n log n) due to sorting. Excel I/O via `openxlsx` dominates for large
#' rosters; expect ~2-5 s for 500 rows.
#'
#' @section Called By:
#' - [mysterycall_run_workflow()]
#'
#' @family workflow
#' @export
#'
#' @examplesIf interactive()
#' input_data <- readr::read_csv("/path/to/your/input/file.csv")
#' output_directory <- "/path/to/your/output/directory"
#' lab_assistant_names <- c("Label1", "Label2", "Label3")
#' insurance_order <- c("Medicaid", "Blue Cross/Blue Shield")
#' mysterycall_split_and_save(
#'   data_or_path = input_data,
#'   output_directory = output_directory,
#'   lab_assistant_names = lab_assistant_names,
#'   insurance_order = insurance_order
#' )
mysterycall_split_and_save <- function(data_or_path, output_directory, lab_assistant_names, seed = 1978,
                           complete_file_prefix = "complete_non_split_version_", split_file_prefix = "",
                           recursive_create = TRUE, insurance_order = c("Medicaid", "Blue Cross/Blue Shield")) {
  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    stop("Package 'openxlsx' is required for this function", call. = FALSE)
  }
  # Validate input data or read from file path
  if (is.character(data_or_path)) {
    if (!base::file.exists(data_or_path)) {
      stop("File does not exist at the specified path: ", data_or_path, call. = FALSE)
    }
    ext <- tolower(tools::file_ext(data_or_path))
    if (ext %in% c("csv", "parquet")) {
      data <- mysterycall_read_table(data_or_path)
    } else if (ext %in% c("rds", "rda")) {
      data <- readRDS(data_or_path)
    } else if (ext %in% c("xls", "xlsx")) {
      if (!requireNamespace("readxl", quietly = TRUE)) {
        stop("Reading Excel workbooks requires the 'readxl' package", call. = FALSE)
      }
      data <- readxl::read_excel(data_or_path)
    } else {
      stop("Unsupported file extension: ", ext, ". Provide a CSV, Parquet, RDS, or Excel file.", call. = FALSE)
    }
  } else if (is.data.frame(data_or_path)) {
    data <- data_or_path
  } else {
    stop("Data input must be either a dataframe or a valid file path.", call. = FALSE)
  }

  # Check for the presence of necessary columns including 'insurance'
  required_columns <- c("for_redcap", "id", "doctor_id", "insurance")
  missing_columns <- base::setdiff(required_columns, base::names(data))
  if (length(missing_columns) > 0) {
    stop("The input data is missing the following columns: ", base::paste(missing_columns, collapse = ", "), call. = FALSE)
  }
  message(
    sprintf(
      "Validated %d required columns for splitting: %s.",
      length(required_columns),
      base::paste(required_columns, collapse = ", ")
    )
  )

  # Ensure that all insurance types in the data are covered by insurance_order
  data_insurance_values <- unique(data$insurance[!is.na(data$insurance)])
  missing_from_order <- setdiff(data_insurance_values, insurance_order)
  if (length(missing_from_order) > 0) {
    stop(sprintf(
      "Data contains insurance value(s) not in insurance_order: %s. Add them to insurance_order.",
      paste(missing_from_order, collapse = ", ")
    ), call. = FALSE)
  }
  # Also warn if insurance_order contains values absent from the data
  extra_in_order <- setdiff(insurance_order, data_insurance_values)
  if (length(extra_in_order) > 0) {
    warning(sprintf(
      "insurance_order contains value(s) not found in the data: %s.",
      paste(extra_in_order, collapse = ", ")
    ), call. = FALSE)
  }

  # Warn about rows with NA insurance  --  they will be assigned to callers but
  # their workbook position is undefined (sorted last, grouped separately).
  n_na_insurance <- sum(is.na(data$insurance))
  if (n_na_insurance > 0) {
    warning(sprintf(
      "%d row(s) have NA insurance and will be assigned to callers with undefined ordering. Set insurance to a value in insurance_order to control placement.",
      n_na_insurance
    ), call. = FALSE)
  }

  # Create a ranking based on the insurance order for sorting
  insurance_rank <- setNames(seq_along(insurance_order), insurance_order)
  data <- data %>%
    dplyr::mutate(insurance_rank = insurance_rank[.data$insurance]) %>%
    dplyr::arrange(.data$insurance_rank, .data$doctor_id)  # Sort by insurance rank, then by doctor_id if necessary
  message(
    sprintf(
      "Arranged %d row(s) by insurance priority: %s.",
      nrow(data),
      paste(insurance_order, collapse = ", ")
    )
  )

  # Check if lab_assistant_names is provided and has at least two names
  if (length(lab_assistant_names) < 2) {
    stop("Please provide at least two lab assistant names for the splits.", call. = FALSE)
  }
  message(
    sprintf(
      "Preparing to split workbooks across %d lab assistant(s): %s.",
      length(lab_assistant_names),
      paste(lab_assistant_names, collapse = ", ")
    )
  )

  # Shuffle rows within each insurance group (seed-controlled), then assign
  # lab assistants via round-robin so every assistant receives at most one row
  # more than any other  --  guaranteed regardless of group size or roster length.
  withr::local_seed(seed)
  if (nrow(data) == 0) {
    message("Input contains zero rows; workbooks will be created without assignments.")
    data <- data %>%
      dplyr::mutate(lab_assistant_assigned = character(dplyr::n()))
  } else {
    data <- data %>%
      dplyr::group_by(.data$insurance_rank) %>%
      dplyr::slice_sample(prop = 1) %>%   # random shuffle within group (seed-controlled)
      dplyr::ungroup() %>%
      # Round-robin over the full sorted frame (counter carried across insurance
      # groups) so no assistant receives more than one row more than any other.
      dplyr::mutate(
        lab_assistant_assigned = lab_assistant_names[
          (seq_len(dplyr::n()) - 1L) %% length(lab_assistant_names) + 1L
        ]
      )
  }

  # Create output directory if it doesn't exist
  if (!dir.exists(output_directory)) {
    tryCatch({
      dir.create(output_directory, recursive = recursive_create, showWarnings = FALSE)
    }, error = function(e) {
      stop("Failed to create output directory. Check directory permissions and try again.", call. = FALSE)
    })
  }

  # Save the complete data to a separate Excel file
  current_datetime <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  complete_output_file <- file.path(output_directory, paste0(complete_file_prefix, current_datetime, ".xlsx"))

  tryCatch({
    openxlsx::write.xlsx(data, complete_output_file)
    message(sprintf("Saved unsplit roster (%d row(s)) to: %s", nrow(data), complete_output_file))
  }, error = function(e) {
    stop("Error saving the complete file. Check if the output directory is writable.", call. = FALSE)
  })

  # Split the data into parts based on lab assistants and save each part.
  # Iterate `lab_assistant_names` explicitly (rather than base::split(), which
  # orders groups alphabetically and drops zero-row assistants) so workbooks are
  # written in roster order, including empty assistants as zero-row files.
  split_paths <- character(length(lab_assistant_names))
  for (i in seq_along(lab_assistant_names)) {
    lab_assistant_name <- lab_assistant_names[[i]]
    assistant_rows <- data[!is.na(data$lab_assistant_assigned) &
                             data$lab_assistant_assigned == lab_assistant_name, , drop = FALSE]
    output_file <- file.path(output_directory,
                             paste0(split_file_prefix, lab_assistant_name, "_", current_datetime, ".xlsx"))
    tryCatch({
      openxlsx::write.xlsx(assistant_rows, output_file)
      message(sprintf(
        "Saved %d row(s) for %s to: %s",
        nrow(assistant_rows),
        lab_assistant_name,
        output_file
      ))
    }, error = function(e) {
      stop("Error saving split data for ", lab_assistant_name, ". Check if the output directory is writable.", call. = FALSE)
    })
    split_paths[[i]] <- output_file
  }
  message(sprintf("Split run complete: generated %d workbook(s).", length(lab_assistant_names)))
  if (isTRUE(interactive()) && requireNamespace("beepr", quietly = TRUE)) beepr::beep(2)
  invisible(c(complete_output_file, split_paths))
}
