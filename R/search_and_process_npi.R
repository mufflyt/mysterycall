#' Search and Process NPI Numbers
#'
#' Searches the NPI registry by provider name, filters by taxonomy and
#' credentials, and accumulates results across batches.  Supports resume
#' capability for interrupted runs (via `resume = TRUE`), structured logging to
#' CSV or plain-text files, and optional progress callbacks for long-running
#' workflows.  Failed searches are automatically retried (up to 3 attempts)
#' with exponential backoff.
#'
#' @param data A data frame with columns `first` and `last` containing the
#'   provider names to search.
#' @param enumeration_type The enumeration type for NPI search (e.g., "ind", "org", "all"). Default is "ind".
#' @param limit The maximum number of search results to request for each name pair. Default is 5.
#' @param country_code Filter for only the "US".
#' @param filter_credentials A character vector containing the credentials to filter the NPI results. Default is c("MD", "DO").
#' @param save_chunk_size The number of results to save per chunk. Default is 10.
#' @param dest_dir Destination directory to save chunked results. Default is NULL (no files written).
#'   Files are written using the format specified by `file_format`.
#' @param file_format Optional override controlling whether chunked and accumulated
#'   results are saved as "csv" or "parquet". When `NULL`, the format defaults to CSV
#'   unless `accumulate_path` ends with ".parquet".
#' @param accumulate_path Optional output path that accumulates every non-empty result.
#'   When provided, results are appended after each successful lookup using the
#'   format inferred from `file_format` or the file extension.
#' @param resume Logical. If `TRUE` and `accumulate_path` already exists, names that
#'   have been processed previously (based on the `search_term` column) are skipped.
#' @param progress_log Optional file path used to log progress updates. The log file
#'   is appended to and created automatically if it does not exist.
#' @param notify Logical. If `TRUE`, play a notification sound when processing
#'   completes (requires the optional `beepr` package). Defaults to `TRUE`.
#' @param progress_callback Optional function invoked with a named list each
#'   time progress is updated. The list contains fields such as `event`,
#'   `timestamp`, `search_term`, `rows`, `index`, and `total`.
#' @param heartbeat_seconds Optional numeric value specifying how frequently
#'   (in seconds) to emit a "still processing" heartbeat update while iterating
#'   over names. Set to `NULL` to disable the heartbeat.
#' @param progress_log_format Either "text" (default) to append human readable
#'   lines to `progress_log` or "csv" to write structured entries with columns
#'   `timestamp`, `event`, `search_term`, `rows`, and `detail`.
#' @return A data frame with 8 columns:
#'   \describe{
#'     \item{`npi`}{Character. 10-digit NPI identifier; deduplicated within
#'       results.}
#'     \item{`first_name`}{Character. Provider first name from the NPI
#'       registry.}
#'     \item{`last_name`}{Character. Provider last name from the NPI
#'       registry.}
#'     \item{`middle_name`}{Character. Provider middle name; `NA` when
#'       absent.}
#'     \item{`credential`}{Character. Degree credential string (e.g., `"MD"`,
#'       `"DO"`).}
#'     \item{`taxonomies_desc`}{Character. Taxonomy classification from the
#'       NPI registry.}
#'     \item{`search_term`}{Character. The `first last` name string that was
#'       looked up.}
#'     \item{`resume_row_index`}{Integer. Row number from input `data`;
#'       disambiguates providers with identical names.}
#'   }
#'   Rows are deduplicated by NPI and sorted by `last_name`, `first_name`.
#'   When `resume = TRUE` and `accumulate_path` already exists, previously
#'   processed names are skipped and new results are appended to that file.
#'   Returns an empty data frame with these columns when no matches pass the
#'   credential and taxonomy filters.
#'
#' @seealso [mysterycall_validate_npi()] for downstream NPI validation;
#'   [mysterycall_run_workflow()] which orchestrates this function;
#'   [mysterycall_search_taxonomy()] for taxonomy-based registry searches.
#' @importFrom dplyr filter mutate select rename distinct arrange bind_rows tibble
#' @importFrom stringr str_detect
#' @importFrom npi npi_search npi_flatten
#' @importFrom readr write_csv read_csv
#' @family npi
#' @export
#' @examplesIf interactive()
#' df <- data.frame(first = "John", last = "Doe")
#' results <- mysterycall_search_and_process_npi(df)
mysterycall_search_and_process_npi <- function(data,
                                   enumeration_type = "ind",
                                   limit = NULL,
                                   country_code = "US",
                                   filter_credentials = c("MD", "DO"),
                                   save_chunk_size = 10,
                                   dest_dir = NULL,
                                   file_format = NULL,
                                   accumulate_path = NULL,
                                   resume = FALSE,
                                   progress_log = NULL,
                                   notify = TRUE,
                                   progress_callback = NULL,
                                   heartbeat_seconds = NULL,
                                   progress_log_format = c("text", "csv")) {
  if (!requireNamespace("readr", quietly = TRUE)) {
    stop("Package 'readr' is required for mysterycall_search_and_process_npi(). Install it with install.packages('readr').", call. = FALSE)
  }
  validate_dataframe(data, name = "data")

  progress_log_format <- match.arg(progress_log_format)
  validate_scalar_positive_numeric(
    heartbeat_seconds,
    name = "heartbeat_seconds",
    allow_null = TRUE
  )

  table_format <- mysterycall_normalize_file_format(file_format, path = accumulate_path)

  validate_required_columns(data, required = c("first", "last"), name = "data")

  # Validate that required columns contain actual data, not all NA (Bug #7 fix)
  if (nrow(data) > 0) {
    if (all(is.na(data$first))) {
      stop("Column 'first' must contain non-missing values (currently all NA).", call. = FALSE)
    }
    if (all(is.na(data$last))) {
      stop("Column 'last' must contain non-missing values (currently all NA).", call. = FALSE)
    }
    # Remove rows where both first and last are NA
    valid_rows <- !is.na(data$first) & !is.na(data$last)
    if (!any(valid_rows)) {
      stop("No rows have both 'first' and 'last' name values. Cannot proceed with NPI search.", call. = FALSE)
    }
    if (sum(!valid_rows) > 0) {
      warning(sprintf(
        "Removing %d row(s) with missing 'first' or 'last' name values.",
        sum(!valid_rows)
      ))
      data <- data[valid_rows, , drop = FALSE]
    }
  }

  write_structured_log <- function(timestamp, event, search_term, rows, detail) {
    if (is.null(progress_log)) {
      return(invisible(NULL))
    }
    dir.create(dirname(progress_log), showWarnings = FALSE, recursive = TRUE)
    if (identical(progress_log_format, "text")) {
      detail_msg <- if (!is.null(detail) && nzchar(detail)) {
        paste0(" - ", detail)
      } else {
        ""
      }
      search_msg <- if (!is.na(search_term) && nzchar(search_term)) {
        paste0(" [", search_term, "]")
      } else {
        ""
      }
      rows_msg <- if (!is.na(rows)) {
        paste0(" (rows: ", rows, ")")
      } else {
        ""
      }
      cat(sprintf("[%s] %s%s%s%s\n", timestamp, event, search_msg, rows_msg, detail_msg),
        file = progress_log, append = TRUE)
    } else {
      new_row <- data.frame(
        timestamp = timestamp,
        event = event,
        search_term = if (is.na(search_term)) "" else search_term,
        rows = rows,
        detail = if (is.null(detail)) "" else detail,
        stringsAsFactors = FALSE
      )
      readr::write_csv(
        new_row,
        progress_log,
        append = file.exists(progress_log),
        col_names = !file.exists(progress_log)
      )
    }
  }

  dispatch_progress <- function(event,
                                 search_term = NA_character_,
                                 rows = NA_integer_,
                                 detail = NULL,
                                 index = NA_integer_) {
    timestamp <- Sys.time()
    timestamp_chr <- format(timestamp, "%Y-%m-%d %H:%M:%S")
    write_structured_log(timestamp_chr, event, search_term, rows, detail)

    if (is.function(progress_callback)) {
      update <- list(
        event = event,
        timestamp = timestamp,
        search_term = if (!is.na(search_term)) search_term else NULL,
        rows = if (!is.na(rows)) rows else NULL,
        detail = detail,
        index = if (!is.na(index)) index else NULL,
        total = if (exists("total_names", inherits = FALSE)) total_names else NULL
      )
      try(progress_callback(update), silent = TRUE)
    }
  }

  read_existing_accumulation <- function() {
    if (is.null(accumulate_path) || !file.exists(accumulate_path)) {
      return(NULL)
    }
    tryCatch(
      mysterycall_read_table(accumulate_path, format = table_format),
      error = function(e) {
        dispatch_progress(
          event = "accumulation_error",
          detail = sprintf("Unable to read accumulation file '%s': %s", accumulate_path, e$message)
        )
        NULL
      }
    )
  }

  existing_accumulated <- NULL
  processed_resume_keys <- character(0)
  if (isTRUE(resume)) {
    existing_accumulated <- read_existing_accumulation()
    if (!is.null(existing_accumulated) &&
        all(c("search_term", "resume_row_index") %in% names(existing_accumulated))) {
      processed_resume_keys <- unique(paste(
        existing_accumulated$resume_row_index,
        existing_accumulated$search_term,
        sep = ""
      ))
    } else if (!is.null(existing_accumulated) && "search_term" %in% names(existing_accumulated)) {
      # Legacy accumulation file without resume_row_index: fall back to name-only matching.
      # Store just the search_term values; the skip check below also tests search_term directly.
      processed_resume_keys <- unique(existing_accumulated$search_term[!is.na(existing_accumulated$search_term)])
    }
  }

  if (!nrow(data)) {
    final_result <- if (!is.null(existing_accumulated)) existing_accumulated else dplyr::tibble()
    dispatch_progress(
      event = if (!is.null(existing_accumulated)) "cached" else "skipped",
      rows = nrow(final_result),
      detail = if (!is.null(existing_accumulated)) {
        "No new names provided; returning cached accumulation."
      } else {
        "No names provided; skipping search."
      }
    )
    if (isTRUE(interactive()) && isTRUE(notify) && requireNamespace("beepr", quietly = TRUE)) {
      beepr::beep(2)
    }
    return(final_result)
  }

  first_names <- as.character(data$first)
  last_names <- as.character(data$last)
  total_names <- length(first_names)

  dispatch_progress(
    event = "start",
    detail = sprintf("Processing %d name(s)", total_names)
  )

  # Derive accepted taxonomy descriptions from the package's canonical taxonomy
  # dataset instead of a hardcoded list. When taxonomy is updated, this filter
  # automatically picks up the new specialties without any code change.
  allowed_taxonomies <- unique(mysterycall::taxonomy$Classification)
  credential_filter <- NULL
  if (!is.null(filter_credentials)) {
    credential_filter <- tolower(gsub("[^A-Za-z0-9]", "", filter_credentials))
  }

  pb <- NULL
  if (total_names > 0) {
    if (requireNamespace("progress", quietly = TRUE)) {
      pb <- progress::progress_bar$new(total = total_names, clear = FALSE, show_after = 0)
    }
  }

  heartbeat_enabled <- !is.null(heartbeat_seconds)
  last_heartbeat <- Sys.time()

  save_results <- function(result, file_prefix, directory) {
    if (is.null(directory) || is.na(directory) || !nrow(result)) {
      return(invisible(NULL))
    }
    dir.create(directory, showWarnings = FALSE, recursive = TRUE)
    timestamp <- format(Sys.time(), "%Y%m%d%H%M%S")
    extension <- if (identical(table_format, "parquet")) ".parquet" else ".csv"
    file_name <- file.path(directory, paste0(file_prefix, "_chunk_", timestamp, extension))
    mysterycall_write_table(result, file_name, format = table_format)
    dispatch_progress(
      event = "chunk_saved",
      search_term = basename(file_name),
      rows = nrow(result),
      detail = "Chunk saved to disk"
    )
  }

  append_accumulated <- function(result) {
    if (is.null(accumulate_path) || is.na(accumulate_path) || !nrow(result)) {
      return(invisible(NULL))
    }
    dir.create(dirname(accumulate_path), showWarnings = FALSE, recursive = TRUE)
    append_mode <- file.exists(accumulate_path)
    tryCatch({
      mysterycall_write_table(result, accumulate_path, format = table_format, append = append_mode, col_names = !append_mode)
      dispatch_progress(
        event = "accumulated",
        rows = nrow(result),
        detail = sprintf("Appended to %s", accumulate_path)
      )
    }, error = function(e) {
      dispatch_progress(
        event = "accumulation_error",
        detail = sprintf("Unable to append to '%s': %s", accumulate_path, e$message)
      )
    })
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

  mysterycall_search_npi <- function(first_name, last_name, index) {
    attempt <- 1L
    search_term <- trimws(paste(first_name, last_name))

    repeat {
      result <- tryCatch({
        # Build search parameters conditionally to avoid artificial limits
        search_params <- list(
          first_name = first_name,
          last_name = last_name,
          enumeration_type = enumeration_type,
          country_code = country_code
        )

        # Only add limit if explicitly specified (not NULL)
        if (!is.null(limit)) {
          search_params$limit <- limit
        }

        npi_obj <- do.call(npi::npi_search, search_params)

        if (is.null(npi_obj)) {
          return(NULL)
        }

        flattened <- npi::npi_flatten(npi_obj, cols = c("basic", "taxonomies"))
        if (is.null(flattened) || !nrow(flattened)) {
          return(NULL)
        }

        critical_cols <- c("npi", "taxonomies_desc")
        missing_critical <- setdiff(critical_cols, names(flattened))
        if (length(missing_critical)) {
          warning(sprintf(
            "npi::npi_flatten() for '%s' is missing column(s): %s. The npi package schema may have changed. Columns returned: %s",
            search_term,
            paste(missing_critical, collapse = ", "),
            paste(names(flattened), collapse = ", ")
          ), call. = FALSE)
          return(NULL)
        }

        filtered <- dplyr::filter(flattened, .data$taxonomies_desc %in% allowed_taxonomies)
        if (!nrow(filtered)) {
          return(NULL)
        }

        if (!"basic_credential" %in% names(filtered)) {
          filtered$basic_credential <- NA_character_
        }
        if (!"basic_first_name" %in% names(filtered)) {
          filtered$basic_first_name <- NA_character_
        }
        if (!"basic_last_name" %in% names(filtered)) {
          filtered$basic_last_name <- NA_character_
        }
        if (!"basic_middle_name" %in% names(filtered)) {
          filtered$basic_middle_name <- NA_character_
        }

        filtered <- dplyr::mutate(
          filtered,
          credential = .data$basic_credential,
          credential_clean = tolower(gsub("[^A-Za-z0-9]", "", .data$credential))
        )

        if (!is.null(credential_filter)) {
          pattern <- paste0("\\b(", paste(credential_filter, collapse = "|"), ")\\b")
          filtered <- dplyr::filter(
            filtered,
            is.na(.data$credential_clean) | stringr::str_detect(.data$credential_clean, pattern)
          )
        }

        filtered <- dplyr::rename(
          filtered,
          "first_name" = "basic_first_name",
          "last_name" = "basic_last_name",
          "middle_name" = "basic_middle_name"
        )

        filtered <- dplyr::mutate(filtered, search_term = search_term)
        filtered <- dplyr::select(filtered, -dplyr::all_of(c("credential_clean", "basic_credential")))
        filtered <- dplyr::distinct(filtered, .data$npi, .keep_all = TRUE)
        filtered <- dplyr::arrange(filtered, .data$last_name, .data$first_name)
        filtered
      }, error = function(e) {
        e
      })

      if (inherits(result, "error")) {
        reason <- extract_status(result$message)
        message(sprintf(
          "Attempt %d/%d for %s failed %s.",
          attempt,
          max_attempts,
          if (nzchar(search_term)) search_term else "NPI search",
          reason
        ))
        dispatch_progress(
          event = "retry",
          search_term = search_term,
          detail = sprintf("Attempt %d/%d %s", attempt, max_attempts, reason),
          index = index
        )

        if (attempt >= max_attempts) {
          message(sprintf(
            "Giving up on %s after %d attempt%s.",
            if (nzchar(search_term)) search_term else "NPI search",
            max_attempts,
            if (max_attempts == 1) "" else "s"
          ))
          dispatch_progress(
            event = "search_error",
            search_term = search_term,
            detail = result$message,
            index = index
          )
          return(NULL)
        }

        delay <- base_delay * 2^(attempt - 1)
        message(sprintf("Retrying %s in %.1f seconds...", search_term, delay))
        Sys.sleep(delay)
        attempt <- attempt + 1L
        next
      }

      return(result)
    }
  }

  out <- vector("list", length = total_names)
  for (i in seq_len(total_names)) {
    first_name <- first_names[[i]]
    last_name <- last_names[[i]]
    if (!is.null(pb)) {
      pb$tick()
    }
    if (heartbeat_enabled) {
      now <- Sys.time()
      if (difftime(now, last_heartbeat, units = "secs") >= heartbeat_seconds) {
        message("Still processing...")
        dispatch_progress(event = "heartbeat", detail = "Processing in progress")
        last_heartbeat <- now
      }
    }
    search_term <- trimws(paste(first_name, last_name))
    # Resume key = row index + name so two rows with the same name at different
    # positions are treated as distinct lookups (different practices / providers).
    resume_key <- paste0(i, search_term)
    # Match current-format keys (index + name) OR legacy-format keys (name only).
    already_processed <- isTRUE(resume) && length(processed_resume_keys) &&
      (resume_key %in% processed_resume_keys || search_term %in% processed_resume_keys)
    if (already_processed) {
      dispatch_progress(
        event = "skipped",
        search_term = search_term,
        detail = "Already present in accumulation (row index matched)",
        index = i
      )
      next
    }

    result <- mysterycall_search_npi(first_name, last_name, i)

    if (is.null(result) || !nrow(result)) {
      dispatch_progress(
        event = "no_results",
        search_term = search_term,
        detail = "Search returned no data",
        index = i
      )
      next
    }

    # Stamp the source row index so resume logic can match by (index, name)
    # rather than name alone, preventing duplicate-name providers from being skipped.
    result$resume_row_index <- i

    should_save <- is.numeric(save_chunk_size) && !is.na(save_chunk_size) && save_chunk_size > 0 && nrow(result) >= save_chunk_size
    if (should_save) {
      save_results(result, "results_of_search_and_process_npi", dest_dir)
    }

    append_accumulated(result)
    dispatch_progress(
      event = "result",
      search_term = search_term,
      rows = nrow(result),
      detail = "Retrieved rows",
      index = i
    )

    out[[i]] <- result
  }

  npi_data <- Filter(function(x) is.data.frame(x) && nrow(x) > 0, out)
  if (!length(npi_data)) {
    final_result <- if (!is.null(existing_accumulated)) existing_accumulated else dplyr::tibble()
  } else {
    result <- dplyr::bind_rows(npi_data)
    if (!is.null(existing_accumulated)) {
      final_result <- dplyr::bind_rows(existing_accumulated, result)
      if ("npi" %in% names(final_result)) {
        final_result <- dplyr::distinct(final_result, .data$npi, .keep_all = TRUE)
      } else {
        final_result <- dplyr::distinct(final_result)
      }
    } else {
      final_result <- result
    }
  }

  dispatch_progress(
    event = "completed",
    rows = nrow(final_result),
    detail = "Finished processing all names"
  )

  if (isTRUE(interactive()) && isTRUE(notify) && requireNamespace("beepr", quietly = TRUE)) {
    beepr::beep(2)
  }

  final_result
}
