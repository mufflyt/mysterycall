#' Retrieve Clinician Data
#'
#' Retrieves clinician data from the `provider` package for each valid NPI in
#' the input.  Accepts either a data frame with an `npi` column or a path to a
#' CSV file.  Invalid NPIs are filtered out via [mysterycall_validate_npi()]
#' before any API calls are made.
#'
#' @param input_data A data frame with an `npi` column, or a character scalar
#'   path to a CSV file that contains an `npi` column.
#'
#' @return A tibble with one row per valid NPI and columns from
#'   `provider::clinicians()` (name, specialty, address, etc.), plus an
#'   `npi_is_valid` column. Returns a zero-row tibble when no valid NPIs are
#'   found. Returns `NULL` silently per NPI when the `provider` package is not
#'   installed.
#'
#' @section Subspecialty source warning:
#'   The `taxonomies_desc` column in the returned tibble reflects NPPES
#'   taxonomy codes (broad specialty groupings from the NPI registry). **Do not
#'   use `taxonomies_desc` to assign subspecialty.** NPPES does not
#'   reliably distinguish subspecialties such as Neurotology or Pediatric
#'   Otolaryngology. Subspecialty must be derived exclusively from board
#'   certification data using [mysterycall_parse_certification_subspecialty()]
#'   and reconciled via [mysterycall_reconcile_specialty()].
#' @seealso [mysterycall_luhn_check()] to validate NPI checksums;
#'   [mysterycall_validate_npi()] for row-level NPI filtering;
#'   [mysterycall_safe_left_join()] to attach clinician data to a roster.
#' @importFrom readr read_csv cols col_character col_guess
#' @importFrom dplyr mutate bind_rows
#' @family npi
#' @export
#' @examplesIf interactive()
#' clinician_df <- mysterycall_get_clinician_data("clinicians.csv")
mysterycall_get_clinician_data <- function(input_data) {
  if (is.data.frame(input_data)) {
    clinician_df <- input_data
  } else if (is.character(input_data) && length(input_data) == 1) {
    if (!file.exists(input_data)) {
      stop(sprintf("CSV file not found: %s", input_data), call. = FALSE)
    }
    if (!requireNamespace("readr", quietly = TRUE)) {
      stop("Package 'readr' is required to read CSV input. Install it with install.packages('readr'), or pass a data frame instead.", call. = FALSE)
    }

    clinician_df <- readr::read_csv(
      input_data,
      col_types = readr::cols(.default = readr::col_guess(), npi = readr::col_character())
    )
  } else {
    stop(sprintf("`input_data` must be a data frame or a single CSV file path; received class: %s.", paste(class(input_data), collapse = ", ")), call. = FALSE)
  }

  if (!"npi" %in% names(clinician_df)) {
    stop(sprintf("`input_data` is missing required column `npi`. Available columns: %s", if (length(names(clinician_df))) paste(names(clinician_df), collapse = ", ") else "<none>"), call. = FALSE)
  }

  cleaned_df <- mysterycall_validate_npi(clinician_df)
  if (!nrow(cleaned_df)) {
    cleaned_df$npi_is_valid <- logical()
    return(cleaned_df)
  }

  get_clinician_data <- function(npi) {
    npi <- as.character(npi)
    if (nchar(npi) != 10 || grepl("\\D", npi)) {
      return(NULL)
    }

    provider_pkg <- "provider"
    if (!requireNamespace(provider_pkg, quietly = TRUE)) {
      message(sprintf(
        "NPI %s: package '%s' is not installed.",
        npi, provider_pkg
      ))
      return(NULL)
    }
    clinicians_fn <- get0("clinicians", envir = asNamespace(provider_pkg), mode = "function")
    if (is.null(clinicians_fn)) {
      warning(sprintf(
        "NPI %s: the '%s' package is installed but does not export a 'clinicians()' function; returning NULL.",
        npi, provider_pkg
      ), call. = FALSE)
      return(NULL)
    }

    clinician_info <- tryCatch(
      clinicians_fn(npi = npi),
      error = function(e) {
        message(sprintf("provider::clinicians() failed for NPI %s: %s", npi, conditionMessage(e)))
        NULL
      }
    )
    if (is.null(clinician_info) || !nrow(clinician_info)) {
      return(NULL)
    }
    as.data.frame(clinician_info, stringsAsFactors = FALSE)
  }

  cleaned_df <- cleaned_df %>%
    dplyr::mutate(clinician_data = lapply(.data$npi, get_clinician_data))

  has_results <- vapply(cleaned_df$clinician_data, function(x) {
    !is.null(x) && nrow(x) > 0
  }, logical(1))

  base_cols <- setdiff(names(cleaned_df), "clinician_data")

  if (!any(has_results)) {
    return(cleaned_df[FALSE, base_cols, drop = FALSE])
  }

  rows_with_results <- cleaned_df[has_results, , drop = FALSE]
  expanded <- lapply(seq_len(nrow(rows_with_results)), function(idx) {
    base_row <- rows_with_results[idx, base_cols, drop = FALSE]
    clinician_rows <- rows_with_results$clinician_data[[idx]]
    clinician_rows <- as.data.frame(clinician_rows, stringsAsFactors = FALSE)

    base_expanded <- base_row[rep(1, nrow(clinician_rows)), , drop = FALSE]
    combined <- cbind(base_expanded, clinician_rows)
    as.data.frame(combined, stringsAsFactors = FALSE)
  })

  result <- dplyr::bind_rows(expanded)

  if (isTRUE(interactive()) && requireNamespace("beepr", quietly = TRUE)) {
    beepr::beep(2)
  }

  result
}
