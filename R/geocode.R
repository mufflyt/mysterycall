#' Geocode unique addresses from a file
#'
#' Reads an input dataset containing an `address` column, geocodes the unique
#' addresses using the Google Maps API via `ggmap::geocode`, and returns the
#' data with additional `latitude` and `longitude` columns. Optionally writes the
#' result to `output_file_path`.
#'
#' @param file_path Path to a CSV, RDS or XLSX file containing an `address`
#'   column.
#' @param google_maps_api_key A valid Google Maps API key.
#' @param output_file_path Optional path to save the geocoded dataset as CSV.
#' @param failed_output_path Optional path that captures rows that failed to
#'   geocode after all retries. When supplied, a timestamped backup is created
#'   before overwriting existing results.
#' @param notify Logical. If `TRUE`, play a notification sound when geocoding
#'   finishes (requires the optional `beepr` package). Defaults to `TRUE`.
#' @param quiet Logical flag controlling log verbosity. Defaults to the package
#'   quiet-mode option.
#' @param tracker Optional progress tracker created with [mysterycall_progress_tracker()].
#'   When supplied, the step named by `tracker_step` is automatically started and
#'   marked as complete or failed with an appropriate quality tier.
#' @param tracker_step Character string describing the step name used when
#'   updating `tracker`.
#'
#' @return A data frame with all original columns from the input file plus two
#'   new numeric columns:
#'   \describe{
#'     \item{`latitude`}{Numeric. Geographic latitude in decimal degrees
#'       (WGS 84). `NA` for addresses that failed geocoding after all retries.}
#'     \item{`longitude`}{Numeric. Geographic longitude in decimal degrees
#'       (WGS 84). `NA` for addresses that failed geocoding after all retries.}
#'   }
#'   Side effects: when `output_file_path` is non-`NULL`, the enriched data
#'   frame is written as CSV; when `failed_output_path` is non-`NULL`, rows
#'   that could not be geocoded are written separately (with a timestamped
#'   backup if the file already exists).
#'
#' @section Requirements:
#'   Geocoding requires the `ggmap` package (listed in `Suggests`, not
#'   `Imports`) and a Google Maps Platform API key with the **Geocoding API**
#'   enabled. Steps to obtain a key:
#'   \enumerate{
#'     \item Create a project at <https://console.cloud.google.com/>.
#'     \item Enable the **Geocoding API** under APIs & Services > Library.
#'     \item Create a key under APIs & Services > Credentials.
#'     \item Enable **billing** on the project (required even for free-tier usage;
#'           Google provides a $200/month credit that covers ~40,000 geocodes).
#'   }
#'
#'   Common errors and remedies:
#'   \tabular{ll}{
#'     **Error message** \tab **Cause / fix** \cr
#'     `"ggmap is required"` \tab Run `install.packages("ggmap")`. \cr
#'     `"REQUEST_DENIED"` \tab Geocoding API not enabled for the key. \cr
#'     `"OVER_QUERY_LIMIT"` \tab Daily free quota (40,000 calls) exceeded. \cr
#'     `"INVALID_REQUEST"` \tab Malformed address string in the data.
#'   }
#'
#'   An invalid or expired key is only detected at the first geocoding
#'   request, not at function entry. Run [mysterycall_preflight_check()] with
#'   `check_apis = TRUE` before a long workflow to catch key problems early.
#'
#' @seealso [mysterycall_preflight_check()] to validate API keys before a long
#'   workflow; [mysterycall_create_isochrones()] to compute drive-time polygons
#'   from geocoded coordinates.
#' @family geospatial helpers
#' @export
#' @examplesIf interactive()
#' result <- mysterycall_geocode("addresses.csv", "my_api_key")
#' @importFrom readr read_csv write_csv
#' @importFrom dplyr left_join distinct mutate
#' @importFrom tibble tibble
#' @importFrom stats complete.cases
#'
mysterycall_geocode <- function(file_path, google_maps_api_key,
                                     output_file_path = NULL,
                                     failed_output_path = NULL,
                                     notify = TRUE,
                                     quiet = getOption("mysterycall.quiet", FALSE),
                                     tracker = NULL,
                                     tracker_step = "Geocoding") {
  if (!file.exists(file_path)) {
    stop("Input file not found.", call. = FALSE)
  }

  # Read input based on extension
  ext <- tools::file_ext(file_path)
  data <- switch(tolower(ext),
                 csv = {
                   if (!requireNamespace("readr", quietly = TRUE)) {
                     stop("Package 'readr' is required to read CSV input.", call. = FALSE)
                   }
                   readr::read_csv(file_path, show_col_types = FALSE)
                 },
                 rds = readRDS(file_path),
                 xlsx = {
                   if (!requireNamespace("readxl", quietly = TRUE)) {
                     stop("Package 'readxl' is required to read Excel files", call. = FALSE)
                   }
                   readxl::read_excel(file_path)
                 },
                 stop("Unsupported file type: ", ext, call. = FALSE))

  if (!"address" %in% names(data)) {
    stop("The dataset must have a column named 'address' for geocoding.", call. = FALSE)
  }

  if (!requireNamespace("ggmap", quietly = TRUE)) {
    stop("Package 'ggmap' is required for mysterycall_geocode()", call. = FALSE)
  }
  ggmap::register_google(key = google_maps_api_key)

  unique_add <- dplyr::distinct(data, address)
  total_unique <- nrow(unique_add)
  if (!isTRUE(quiet)) {
    mysterycall_log_info(sprintf("Geocoding %d unique address(es).", total_unique))
    mysterycall_log_info(sprintf("Found %d total address records, %d unique", nrow(data), total_unique))
  }

  if (!is.null(tracker) && inherits(tracker, "mysterycall_progress_tracker")) {
    mysterycall_progress_start(tracker, tracker_step, note = sprintf("%d unique address(es)", total_unique))
  }

  extract_status <- function(msg) {
    code <- regmatches(msg, regexpr("\\b[0-9]{3}\\b", msg))
    if (length(code) && nzchar(code)) {
      return(paste("after", code))
    }
    msg_clean <- gsub("\\s+", " ", msg)
    paste("due to", substr(msg_clean, 1, 120))
  }

  max_attempts <- 3L
  base_delay <- 1
  coords <- tibble::tibble(lat = numeric(), lon = numeric())
  if (total_unique) {
    first_address <- unique_add$address[[1]]
    for (attempt in seq_len(max_attempts)) {
      attempt_result <- tryCatch({
        ggmap::geocode(unique_add$address, key = google_maps_api_key)
      }, error = function(e) e)

      if (inherits(attempt_result, "error")) {
        reason <- extract_status(attempt_result$message)
        if (!isTRUE(quiet)) {
          mysterycall_log_info(sprintf(
            "Attempt %d/%d for address '%s' failed %s.",
            attempt,
            max_attempts,
            first_address,
            reason
          ))
        }

        if (attempt == max_attempts) {
          failure_reason <- sprintf("Geocoding failed after %d attempts: %s", max_attempts, attempt_result$message)
          if (!is.null(failed_output_path)) {
            failure_tbl <- tibble::tibble(address = unique_add$address, reason = failure_reason)
            mysterycall_export_with_backup(failure_tbl, failed_output_path, quiet = quiet)
          }
          if (!is.null(tracker) && inherits(tracker, "mysterycall_progress_tracker")) {
            mysterycall_tracker_fail(tracker, tracker_step, reason = failure_reason)
          }
          stop(failure_reason, call. = FALSE)
        }

        delay <- base_delay * 2^(attempt - 1)
        if (!isTRUE(quiet)) mysterycall_log_info(sprintf("Retrying geocode request in %.1f seconds...", delay))
        Sys.sleep(delay)
      } else {
        coords <- attempt_result

        # Validate geocoding result structure immediately (Bug #11 fix)
        if (!is.data.frame(coords)) {
          stop("Geocoding API returned unexpected data type (expected data frame).", call. = FALSE)
        }
        if (!"lat" %in% names(coords) || !"lon" %in% names(coords)) {
          stop(sprintf(
            "Geocoding API returned unexpected structure. Expected 'lat' and 'lon' columns, got: %s",
            paste(names(coords), collapse = ", ")
          ), call. = FALSE)
        }
        checkmate::assert_true(length(coords$lat) == nrow(coords), .var.name = "lat length")
        checkmate::assert_true(length(coords$lon) == nrow(coords), .var.name = "lon length")

        break
      }
    }
  }

  if (nrow(coords) != nrow(unique_add)) {
    message(sprintf(
      "Geocoding returned %d row(s) but %d were expected; setting all coordinates to NA to prevent misassignment.",
      nrow(coords), nrow(unique_add)
    ))
    coords <- tibble::tibble(lat = rep(NA_real_, nrow(unique_add)), lon = rep(NA_real_, nrow(unique_add)))
  }
  unique_add <- dplyr::mutate(unique_add,
                              latitude = coords$lat,
                              longitude = coords$lon)

  failed_rows <- unique_add[!stats::complete.cases(unique_add[, c("latitude", "longitude")]), , drop = FALSE]
  success_rate <- if (total_unique) 1 - nrow(failed_rows) / total_unique else 1
  success_count <- total_unique - nrow(failed_rows)
  checkmate::assert_number(success_rate, lower = 0, upper = 1)
  checkmate::assert_int(success_count, lower = 0)
  checkmate::assert_true(success_count <= total_unique, .var.name = "success_count bound")

  # Comprehensive logging: Report geocoding results
  if (!isTRUE(quiet)) {
    if (success_rate >= 0.95) {
      mysterycall_log_success(sprintf("Geocoding complete: %d/%d succeeded (%.1f%%)",
                               success_count, total_unique, success_rate * 100),
                       indent = TRUE)
    } else if (success_rate >= 0.80) {
      mysterycall_log_warning(sprintf("Geocoding finished with warnings: %d/%d succeeded (%.1f%%)",
                               success_count, total_unique, success_rate * 100),
                       indent = TRUE)
    } else {
      mysterycall_log_error(sprintf("Geocoding had low success rate: %d/%d succeeded (%.1f%%)",
                             success_count, total_unique, success_rate * 100),
                     indent = TRUE)
    }
  }

  if (nrow(failed_rows) && !is.null(failed_output_path)) {
    mysterycall_export_with_backup(failed_rows, failed_output_path, quiet = quiet)
    if (!isTRUE(quiet)) mysterycall_log_info(sprintf("Exported %d failed address(es) to %s", nrow(failed_rows), failed_output_path))
  }

  if (!is.null(tracker) && inherits(tracker, "mysterycall_progress_tracker")) {
    mysterycall_progress_finish(tracker, tracker_step, score = success_rate, note = sprintf("%d/%d succeeded", total_unique - nrow(failed_rows), total_unique))
  }

  data <- dplyr::left_join(data, unique_add, by = "address")

  if (!is.null(output_file_path)) {
    mysterycall_export_with_backup(data, output_file_path, quiet = quiet, backup = TRUE)
    if (!quiet) {
      mysterycall_log_save(output_file_path, n_rows = nrow(data))
    }
  }

  if (isTRUE(interactive()) && isTRUE(notify) && requireNamespace("beepr", quietly = TRUE)) {
    beepr::beep(2)
  }
  data
}
