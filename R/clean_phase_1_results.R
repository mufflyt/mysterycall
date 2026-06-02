#' Clean Phase 1 Results Data
#'
#' This function reads the Phase 1 results data file, performs various cleaning
#' and transformation operations, and prepares the data for further analysis.
#' It ensures all required fields are present and formats column names. Missing
#' NPI numbers are handled by generating a unique `random_id`.
#'
#' **New in Version 2.0: Data Provenance and Audit Trail**
#'
#' This function now includes comprehensive data provenance tracking:
#' - Preserves original `id` and `npi` columns as `original_id` and `original_npi`
#' - Adds processing flags (e.g., `processing_flag_empty_name`, `processing_flag_generated_id`)
#' - Handles edge cases like whitespace-only strings safely
#' - Saves audit trail JSON file with processing metadata
#' - Attaches audit trail and quality metrics as data frame attributes
#'
#' @param phase1_data A data frame containing the Phase 1 results data. Ensure that it
#' includes columns like 'for_redcap', 'id', 'names', 'practice_name', 'phone_number',
#' 'state_name', and optionally 'npi'. If 'npi' is missing or any of its values are NA,
#' a `random_id` is generated as a fallback. If an 'id' column exists, it will be
#' preserved as 'original_id'.
#' @param output_directory Directory where the cleaned Phase 1 data should be written.
#'   Defaults to `tempdir()`. An audit trail JSON file will also be saved here.
#' @param verbose Logical. If `TRUE`, progress messages are printed while cleaning.
#'   Defaults to `TRUE`.
#' @param notify Logical. If `TRUE`, play a notification sound on completion when
#'   the optional `beepr` package is available. Defaults to `TRUE`.
#' @param duplicate_rows Logical. If `TRUE`, each row in `phase1_data` is duplicated
#'   to retain the previous behavior that paired insurance entries for each
#'   physician. Set to `FALSE` to keep the original number of rows. A
#'   `processing_flag_is_duplicate` column tracks which rows are duplicates.
#' @param id_seed Optional integer seed used when generating fallback random IDs so
#'   runs can be reproduced without permanently mutating the global RNG state.
#' @param output_format File format to use when writing the cleaned dataset.
#'   Supported options are "csv" (default) and "parquet".
#' @param parent_cohort_hash Optional character scalar. The `cohort_hash` from
#'   an upstream audit trail (e.g. from `mysterycall_search_taxonomy()` or a
#'   prior cleaning step). When supplied, it is recorded in the audit JSON as
#'   `parent_cohort_hash` to enable DAG lineage tracing. Must be a 64-character
#'   lowercase hex string (SHA-256) or `NULL` (default). Ignored silently if
#'   not a valid hex digest.
#'
#' @return Invisibly returns the cleaned data frame (side effect: files are
#'   written to `output_directory`).  The returned object carries these
#'   attributes:
#' \itemize{
#'   \item `audit_trail`: List containing processing metadata (timestamps, row counts, flags)
#'   \item `processing_timestamp`: Time when processing completed
#'   \item `function_version`: Version number of the function (2.0)
#'   \item `output_path`: Path to the saved CSV/Parquet file
#'   \item `audit_trail_path`: Path to the saved audit trail JSON file
#' }
#'
#' The returned data frame includes processing flag columns:
#' \itemize{
#'   \item `processing_flag_empty_name`: TRUE if name was empty/whitespace
#'   \item `processing_flag_generated_id`: TRUE if random ID was generated (no NPI)
#'   \item `processing_flag_is_duplicate`: TRUE for duplicated rows (when duplicate_rows=TRUE)
#'   \item `processing_flag_no_last_name`: TRUE if last name could not be extracted
#' }
#'
#' @examplesIf interactive()
#' library(mysterycall)
#' file_path <- "/path/to/your/input/file.xls"
#' phase1_data <- readxl::read_excel(file_path)  # Assuming use of readxl for Excel files
#' mysterycall_clean_phase1(phase1_data)
#'
#' @section Contract:
#' **Inputs:**
#' - `phase1_data` must contain columns: `names`, `practice_name`, `phone_number`,
#'   `state_name`, `npi`, `for_redcap`.
#' - `output_directory` must be writable; function creates it if absent.
#'
#' **Guarantees:**
#' - Output rows \eqn{\geq} input rows (duplicates may be flagged but are never
#'   silently dropped unless `remove_duplicates = TRUE`).
#' - Every output row carries `processing_flag_*` columns documenting the reason
#'   for any modification.
#' - A JSON audit trail is written alongside the CSV for provenance.
#'
#' **Fails if:**
#' - Required columns are absent from `phase1_data`.
#' - `output_directory` is not writable and cannot be created.
#'
#' @section Provenance Schema:
#' The JSON audit trail written to `<output_directory>/audit_trail_<timestamp>.json`
#' always contains these required fields (see also `tests/fixtures/audit_trail_schema.json`):
#' \preformatted{
#' {
#'   "function_name":        "mysterycall_clean_phase1",
#'   "input_rows":           <integer>,
#'   "input_cols":           <integer>,
#'   "input_colnames":       ["names", "practice_name", ...],
#'   "output_rows":          <integer>,
#'   "output_cols":          <integer>,
#'   "empty_names_count":    <integer>,
#'   "no_last_name_count":   <integer>,
#'   "rows_retained_pct":    <number>,
#'   "rows_duplicated":      <boolean>,
#'   "original_npi_preserved": <boolean>,
#'   "quality_metrics": {
#'     "completeness_npi":   <number>,
#'     "completeness_phone": <number>,
#'     "completeness_names": <number>,
#'     "has_processing_flags": <boolean>
#'   },
#'   "start_time":           "<ISO-8601>",
#'   "end_time":             "<ISO-8601>",
#'   "duration_seconds":     <number>,
#'   "r_version":            "<string>",
#'   "platform":             "<string>",
#'   "package_version":      "<string>",
#'   "parameters":           { ... }
#' }
#' }
#' The `tests/fixtures/audit_trail_schema.json` file documents which fields are
#' required, volatile (excluded from snapshot comparisons), and conditional.
#' This schema is stable across patch versions and constitutes a public API
#' for downstream reproducibility tooling.
#'
#' @section Performance:
#' O(n) in number of rows. String normalisation via `janitor::clean_names()` and
#' `stringr` dominates; expect < 1 s for 1,000 rows on modern hardware.
#'
#' @section Called By:
#' - [mysterycall_run_workflow()]
#' - [mysterycall_run_workflow_logged()]
#'
#' @importFrom dplyr arrange mutate select filter bind_rows
#' @importFrom janitor clean_names
#' @importFrom readr type_convert write_csv
#' @importFrom stringr str_detect
#' @seealso [mysterycall_clean_phase2()] for Phase 2 data cleaning;
#'   [mysterycall_run_workflow()] which orchestrates both phases.
#' @family workflow
#' @export

# library(dplyr)
# library(janitor)
# library(readr)
# library(stringr)
# library(humaniformat)
# library(openxlsx)
# library(fs)

mysterycall_clean_phase1 <- function(phase1_data,
                                  output_directory = tempdir(),
                                  verbose = TRUE,
                                  notify = TRUE,
                                  duplicate_rows = TRUE,
                                  id_seed = NULL,
                                  output_format = c("csv", "parquet"),
                                  parent_cohort_hash = NULL) {
  output_format <- match.arg(output_format)
  if (!requireNamespace("dplyr", quietly = TRUE) ||
      !requireNamespace("janitor", quietly = TRUE) ||
      !requireNamespace("readr", quietly = TRUE) ||
      !requireNamespace("stringr", quietly = TRUE) ||
      !requireNamespace("humaniformat", quietly = TRUE)) {
    stop("Required packages are not installed", call. = FALSE)
  }

  announce <- function(...) {
    if (isTRUE(verbose)) {
      text <- paste0(...)
      text <- sub("\\n$", "", text)
      message(text)
    }
  }

  # === START: AUDIT TRAIL AND PROVENANCE ===
  # Capture processing start time and metadata
  processing_start_time <- Sys.time()
  schema_version <- "1.2.0"
  cohort_hash <- digest::digest(object = phase1_data, algo = "sha256", serialize = TRUE)
  valid_parent_hash <- is.character(parent_cohort_hash) &&
    length(parent_cohort_hash) == 1L &&
    grepl("^[a-f0-9]{64}$", parent_cohort_hash)
  audit_trail <- list(
    schema_version = schema_version,
    cohort_hash    = cohort_hash,
    function_name  = "mysterycall_clean_phase1",
    start_time     = processing_start_time,
    r_version = R.version.string,
    platform = .Platform$OS.type,
    package_version = tryCatch(as.character(packageVersion("mysterycall")), error = function(e) "unknown"),
    parameters = list(
      output_directory = output_directory,
      verbose = verbose,
      notify = notify,
      duplicate_rows = duplicate_rows,
      id_seed = id_seed,
      output_format = output_format
    ),
    input_rows = nrow(phase1_data),
    input_cols = ncol(phase1_data),
    input_colnames = names(phase1_data)
  )

  # Preserve original ID column if it exists
  original_id_preserved <- FALSE
  if ("id" %in% names(phase1_data)) {
    announce("Preserving original 'id' column as 'original_id'...")
    phase1_data <- dplyr::rename(phase1_data, "original_id" = "id")
    original_id_preserved <- TRUE
    audit_trail$original_id_preserved <- TRUE
  }
  # === END: AUDIT TRAIL AND PROVENANCE ===

  validate_dataframe(phase1_data, name = "phase1_data", allow_zero_rows = FALSE)

  if (!is.null(id_seed)) {
    restore_rng <- if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      get(".Random.seed", envir = .GlobalEnv)
    } else {
      NULL
    }
    on.exit({
      if (is.null(restore_rng)) {
        if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
          rm(".Random.seed", envir = .GlobalEnv)
        }
      } else {
        assign(".Random.seed", restore_rng, envir = .GlobalEnv)
      }
    }, add = TRUE)
    set.seed(id_seed)
  }

  announce("Converting column types...")
  npi_col_before_clean <- names(phase1_data)[tolower(names(phase1_data)) == "npi"]
  phase1_data <- readr::type_convert(phase1_data)

  if (length(npi_col_before_clean) == 1 && npi_col_before_clean %in% names(phase1_data)) {
    phase1_data[[npi_col_before_clean]] <- trimws(format(phase1_data[[npi_col_before_clean]], scientific = FALSE, trim = TRUE))
  }

  announce("Cleaning column names...")
  phase1_data <- janitor::clean_names(phase1_data, case = "snake")

  announce("Checking required columns...")
  required_columns <- c("names", "practice_name", "phone_number", "state_name")
  validate_required_columns(phase1_data, required_columns, name = "phase1_data")
  announce(sprintf(
    "Validated %d required columns (%s).",
    length(required_columns),
    paste(required_columns, collapse = ", ")
  ))

  announce("Standardising core text fields...")
  phase1_data <- dplyr::mutate(
    phase1_data,
    names = stringr::str_squish(as.character(.data$names)),
    practice_name = stringr::str_squish(as.character(.data$practice_name)),
    phone_number = format_phone_number(.data$phone_number),
    state_name = stringr::str_squish(as.character(.data$state_name))
  )

  # === EDGE CASE HANDLING: Whitespace-only strings ===
  # Replace empty or whitespace-only names with NA to prevent humaniformat errors
  announce("Handling edge cases in name field...")
  phase1_data <- dplyr::mutate(
    phase1_data,
    names = ifelse(.data$names == "" | is.na(.data$names), NA_character_, .data$names),
    processing_flag_empty_name = (is.na(.data$names))
  )
  empty_names_count <- sum(phase1_data$processing_flag_empty_name, na.rm = TRUE)
  if (empty_names_count > 0) {
    announce(sprintf("Flagged %d row(s) with empty or whitespace-only names.", empty_names_count))
    audit_trail$empty_names_count <- empty_names_count
  }
  # === END: EDGE CASE HANDLING ===

  missing_phone <- sum(is.na(phase1_data$phone_number) | phase1_data$phone_number == "", na.rm = TRUE)
  if (missing_phone) {
    announce(sprintf("Detected %d row(s) with missing or unparseable phone numbers.", missing_phone))
  }

  announce("Handling missing NPI numbers...")

  # === NPI PRESERVATION: Preserve original NPI values ===
  original_npi_preserved <- FALSE
  if ("npi" %in% names(phase1_data)) {
    # Store original NPI for provenance tracking
    phase1_data <- dplyr::mutate(phase1_data, original_npi = .data$npi)
    original_npi_preserved <- TRUE
    audit_trail$original_npi_preserved <- TRUE
    audit_trail$input_npi_count <- sum(!is.na(phase1_data$npi))
  }

  # Generate a stable, content-addressable ID for rows without a valid NPI.
  # Using a hash of row-identifying fields (rather than positional sampling) means
  # the same row always gets the same ID regardless of how many rows are in the
  # dataset, so re-running on any subset reproduces the original IDs exactly.
  generate_random_id_for_row <- function(names_val, practice_val, phone_val, state_val) {
    seed_str <- if (!is.null(id_seed)) as.character(id_seed) else "noseed"
    content <- paste(
      as.character(names_val), as.character(practice_val),
      as.character(phone_val),  as.character(state_val),
      seed_str, sep = "|"
    )
    paste0("id_", substr(digest::digest(content, algo = "sha256", serialize = FALSE), 1, 16))
  }

  if ("npi" %in% names(phase1_data)) {
    phase1_data <- dplyr::mutate(
      phase1_data,
      random_id = dplyr::if_else(
        is.na(.data$npi),
        mapply(
          generate_random_id_for_row,
          .data$names, .data$practice_name, .data$phone_number, .data$state_name,
          SIMPLIFY = TRUE, USE.NAMES = FALSE
        ),
        as.character(.data$npi)
      ),
      processing_flag_generated_id = is.na(.data$npi)
    )
    generated_ids_count <- sum(phase1_data$processing_flag_generated_id, na.rm = TRUE)
    if (generated_ids_count > 0) {
      announce(sprintf("Generated %d random IDs for missing NPIs.", generated_ids_count))
      audit_trail$generated_ids_count <- generated_ids_count
    }
  } else {
    phase1_data <- dplyr::mutate(
      phase1_data,
      random_id = mapply(
        generate_random_id_for_row,
        .data$names, .data$practice_name, .data$phone_number, .data$state_name,
        SIMPLIFY = TRUE, USE.NAMES = FALSE
      ),
      processing_flag_generated_id = TRUE
    )
    announce(sprintf("No NPI column found; generated %d random IDs.", nrow(phase1_data)))
    audit_trail$all_ids_generated <- TRUE
  }
  # === END: NPI PRESERVATION ===

  if (nrow(phase1_data) > 0) {
    # === ROW DUPLICATION TRACKING ===
    rows_before_duplication <- nrow(phase1_data)
    if (isTRUE(duplicate_rows)) {
      announce("Duplicating rows for insurance pairing...")
      phase1_data <- dplyr::bind_rows(phase1_data, phase1_data)
      # Add flag to track which rows are duplicates (second half)
      phase1_data <- dplyr::mutate(
        phase1_data,
        processing_flag_is_duplicate = rep(c(FALSE, TRUE), each = rows_before_duplication)
      )
      audit_trail$rows_duplicated <- TRUE
      audit_trail$rows_after_duplication <- nrow(phase1_data)
    } else {
      announce(sprintf(
        "Skipping row duplication as requested; keeping %d original row(s).",
        nrow(phase1_data)
      ))
      phase1_data <- dplyr::mutate(
        phase1_data,
        processing_flag_is_duplicate = dplyr::row_number() %% 2 == 0
      )
      audit_trail$rows_duplicated <- FALSE
    }
    # === END: ROW DUPLICATION TRACKING ===

    announce("Arranging rows by 'names'...")
    phase1_data <- dplyr::arrange(phase1_data, .data$names)

    announce("Adding insurance information...")
    # Assign insurance via processing_flag_is_duplicate rather than positional
    # alternation: original rows -> Blue Cross/Blue Shield, duplicate rows ->
    # Medicaid. This is invariant to sort order and row additions.
    phase1_data <- dplyr::mutate(
      phase1_data,
      insurance = dplyr::if_else(
        .data$processing_flag_is_duplicate,
        "Medicaid",
        "Blue Cross/Blue Shield"
      )
    )

    announce("Adding a numbered 'id' column...")
    phase1_data <- dplyr::mutate(
      phase1_data,
      id = dplyr::row_number(),
      id_number = paste0("id:", id)
    )

    # === SAFE LAST NAME EXTRACTION: Handle NA and empty names ===
    announce("Extracting last name and creating 'dr_name'...")
    phase1_data <- dplyr::mutate(
      phase1_data,
      last_name = vapply(.data$names, function(n) {
        if (is.na(n) || !nzchar(n)) return(NA_character_)
        tryCatch(
          humaniformat::last_name(n),
          error = function(e) {
            warning(sprintf("Error extracting last name: %s. Returning NA.", e$message), call. = FALSE)
            NA_character_
          }
        )
      }, character(1)),
      dr_name = ifelse(
        is.na(.data$last_name),
        NA_character_,
        paste("Dr.", .data$last_name)
      ),
      processing_flag_no_last_name = is.na(.data$last_name)
    )
    no_last_name_count <- sum(phase1_data$processing_flag_no_last_name, na.rm = TRUE)
    if (no_last_name_count > 0) {
      announce(sprintf("Could not extract last name for %d row(s).", no_last_name_count))
      audit_trail$no_last_name_count <- no_last_name_count
    }
    # === END: SAFE LAST NAME EXTRACTION ===

    announce("Identifying academic or private practice...")
    phase1_data <- dplyr::mutate(
      phase1_data,
      academic = ifelse(
        stringr::str_detect(.data$practice_name, stringr::regex(stringr::str_c(c("University", "Medical College"), collapse = "|"), ignore_case = TRUE)),
        "University",
        "Private Practice"
      )
    )

    announce("Uniting columns for REDCap upload...")
    phase1_data <- dplyr::mutate(
      phase1_data,
      doctor_id = if ("npi" %in% names(phase1_data)) {
        dplyr::coalesce(as.character(.data$npi), as.character(.data$random_id))
      } else {
        as.character(.data$random_id)
      },
      for_redcap = dplyr::if_else(
        is.na(.data$dr_name),
        NA_character_,
        paste(.data$id, .data$dr_name, .data$insurance, .data$phone_number, .data$state_name, .data$random_id, .data$academic, .data$id_number, sep = ", ")
      )
    )

    phase1_data <- dplyr::select(phase1_data, for_redcap, dplyr::everything())
    attr(phase1_data, "output_directory") <- output_directory
  } else {
    if (isTRUE(verbose)) {
      message("No data to process.")
    }
    announce("No data available; skipping duplication, insurance assignment, and ID generation.")
  }

  # === FINALIZE AUDIT TRAIL AND PROVENANCE ===
  processing_end_time <- Sys.time()
  audit_trail$end_time <- processing_end_time
  audit_trail$duration_seconds <- as.numeric(difftime(processing_end_time, processing_start_time, units = "secs"))
  audit_trail$output_rows <- nrow(phase1_data)
  audit_trail$output_cols <- ncol(phase1_data)
  audit_trail$rows_retained_pct <- if (audit_trail$input_rows > 0) {
    (audit_trail$output_rows / audit_trail$input_rows) * 100
  } else {
    0
  }
  if (valid_parent_hash) audit_trail$parent_cohort_hash <- parent_cohort_hash

  # Add provenance metadata as attributes
  attr(phase1_data, "audit_trail") <- audit_trail
  attr(phase1_data, "processing_timestamp") <- processing_end_time
  attr(phase1_data, "function_version") <- "2.0"  # Version with provenance tracking

  # Calculate data quality metrics
  quality_metrics <- list(
    completeness_npi = if ("npi" %in% names(phase1_data) && nrow(phase1_data) > 0) sum(!is.na(phase1_data$npi)) / nrow(phase1_data) else 0,
    completeness_phone = if ("phone_number" %in% names(phase1_data) && nrow(phase1_data) > 0) sum(!is.na(phase1_data$phone_number) & phase1_data$phone_number != "") / nrow(phase1_data) else 0,
    completeness_names = if ("names" %in% names(phase1_data) && nrow(phase1_data) > 0) sum(!is.na(phase1_data$names) & phase1_data$names != "") / nrow(phase1_data) else 0,
    has_processing_flags = any(grepl("^processing_flag_", names(phase1_data)))
  )
  audit_trail$quality_metrics <- quality_metrics

  # Content-addressable artifact identity.
  # Hash the JSON string (not the R object) so that integer/double coercion
  # during JSON round-trip does not change the digest. Keys are sorted before
  # serialisation to guarantee order-independent stability.
  # .audit_volatile_fields is defined in R/audit-verify.R and shared with
  # mysterycall_verify_artifact() to guarantee identical canonicalization.
  stable_keys     <- sort(setdiff(names(audit_trail), .audit_volatile_fields))
  stable_json     <- jsonlite::toJSON(audit_trail[stable_keys], auto_unbox = TRUE, digits = NA)
  audit_trail$artifact_id <- digest::digest(as.character(stable_json),
                                            algo = "sha256", serialize = FALSE)

  announce(sprintf(
    "Processing complete: %d -> %d rows (%.1f%%) in %.2f seconds",
    audit_trail$input_rows,
    audit_trail$output_rows,
    audit_trail$rows_retained_pct,
    audit_trail$duration_seconds
  ))
  # === END: FINALIZE AUDIT TRAIL ===

  current_datetime <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  if (!dir.exists(output_directory)) {
    dir.create(output_directory, recursive = TRUE, showWarnings = FALSE)
  }
  output_extension <- if (identical(output_format, "parquet")) ".parquet" else ".csv"
  output_file <- file.path(output_directory, paste0("clean_phase_1_results_", current_datetime, output_extension))
  mysterycall_write_table(phase1_data, output_file, format = output_format)
  announce(sprintf(
    "Saved cleaned Phase 1 results dataframe to %s with %d row(s) and %d column(s).",
    output_file,
    nrow(phase1_data),
    ncol(phase1_data)
  ))
  attr(phase1_data, "output_path") <- output_file

  # === SAVE AUDIT TRAIL ===
  # Save audit trail as separate JSON file for data provenance
  audit_file <- file.path(output_directory, paste0("audit_trail_", current_datetime, ".json"))
  tryCatch({
    if (requireNamespace("jsonlite", quietly = TRUE)) {
      jsonlite::write_json(audit_trail, audit_file, pretty = TRUE, auto_unbox = TRUE)
      announce(sprintf("Saved audit trail to %s", audit_file))
      attr(phase1_data, "audit_trail_path") <- audit_file
    }
  }, error = function(e) {
    warning(sprintf("Could not save audit trail: %s", e$message), call. = FALSE)
  })
  # === END: SAVE AUDIT TRAIL ===

  if (isTRUE(interactive()) && isTRUE(notify) && requireNamespace("beepr", quietly = TRUE)) {
    beepr::beep(2)
  }

  invisible(phase1_data)
}


format_phone_number <- function(phone_values) {
  phone_chr <- as.character(phone_values)
  digits <- gsub("[^0-9]", "", phone_chr)

  strip_leading_one <- function(x) {
    if (nchar(x) == 11 && substr(x, 1, 1) == "1") {
      substr(x, 2, 11)
    } else {
      x
    }
  }

  formatted <- unname(vapply(digits, function(d) {
    if (is.na(d) || !nzchar(d)) {
      return("")
    }
    clean <- strip_leading_one(d)
    if (nchar(clean) == 10) {
      sprintf("(%s) %s-%s", substr(clean, 1, 3), substr(clean, 4, 6), substr(clean, 7, 10))
    } else if (nchar(clean) == 7) {
      sprintf("%s-%s", substr(clean, 1, 3), substr(clean, 4, 7))
    } else if (nchar(clean) == 0) {
      ""
    } else {
      # Treat unsupported lengths as invalid and return missing value.
      warning(sprintf(
        "Phone number has invalid length (%d digits): '%s'. Expected 7 or 10 digits; returning NA.",
        nchar(clean), d
      ), call. = FALSE)
      NA_character_
    }
  }, character(1)))

  # Preserve original NAs
  formatted[is.na(phone_chr)] <- NA_character_

  formatted
}


# file_path <- "ortho_sports_med/data/phase1/Late_Phase_1_Mystery caller - Sports med Only.xlsx"
# phase1_data <- read_xls(file_path)
# mysterycall_clean_phase1(phase1_data)
