#' Preflight Checks for Mysterycall Workflows
#'
#' Pre-flight validation system that checks all requirements before starting
#' long-running workflows. Catches errors early, estimates resources, and
#' gives users confidence before committing hours to processing.
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name preflight-checks
NULL

#' Run comprehensive preflight checks before workflow
#'
#' Validates all requirements for a successful workflow run including API keys,
#' data quality, output directories, estimated resources, and dependencies.
#' Provides a go/no-go decision before starting long-running operations.
#'
#' @param input_data Either a file path (character scalar) to a CSV/Parquet
#'   roster, or an already-loaded data frame. If a path, the file must exist and
#'   be readable; if a data frame it is validated in memory.
#' @param output_dir Character scalar. Destination directory for workflow
#'   outputs. Created if it does not exist.
#' @param google_maps_api_key Character scalar. Google Maps Platform API key.
#'   Required only when geocoding is part of the workflow; leave `NULL`
#'   to skip geocoding validation.
#' @param here_api_key Character scalar. HERE Routing API key. Required only
#'   when creating drive-time isochrones; leave `NULL` to skip.
#' @param check_apis Logical. If `TRUE` (default), validates each non-`NULL`
#'   API key by making a minimal test request. Set to `FALSE` to skip
#'   live validation (e.g., in tests or when offline).
#' @param estimate_resources Logical. If `TRUE` (default), estimates wall-clock
#'   time and peak memory consumption before the run starts.
#' @param prompt_user Logical. If `TRUE` (default in interactive sessions),
#'   prints a go/no-go summary and waits for user confirmation. Set to
#'   `FALSE` in non-interactive scripts.
#' @param interactive Alias for `prompt_user`; if non-`NULL` it takes
#'   precedence over `prompt_user`. Provided for back-compatibility with
#'   scripts that pass `interactive = FALSE`.
#' @param required_columns Character vector of column names that must be present
#'   in `input_data`. Defaults to `c("first", "last")`.
#'
#' @return `invisible()` list with elements: `passed` (logical), `checks`
#'   (list of individual check results), `errors` (character vector of
#'   blocking issues), `warnings` (character vector of non-blocking issues),
#'   `data` (the validated input data frame), `n_rows` (integer), and
#'   `estimates` (list from [mysterycall_estimate_resources()], or `NULL`
#'   when `estimate_resources = FALSE`). Stops with an informative error if
#'   any required check fails.
#'
#' @section Data quality thresholds:
#'   Input data is scored from 0-1 by [mysterycall_assess_data_quality()].
#'   Scores below **0.70** cause this function to stop with an error; scores
#'   between 0.70 and 0.80 emit a warning. A score below 0.70 typically means
#'   a required name column has more than 50\% missing values. See
#'   [mysterycall_assess_data_quality()] for the full penalty schedule and
#'   worked examples.
#'
#'   The thresholds are **not configurable** via parameters. To investigate
#'   quality issues without stopping, call [mysterycall_assess_data_quality()]
#'   directly and inspect the returned `$issues` list:
#'   ```r
#'   report <- mysterycall_assess_data_quality(my_data)
#'   report$score          # numeric 0-1
#'   report$issues         # list of issue records with $severity and $message
#'   ```
#'
#' @seealso [mysterycall_assess_data_quality()] for the scoring formula and
#'   per-issue details; [mysterycall_estimate_resources()] for runtime and
#'   memory projections.
#'
#' @family utilities
#' @export
#'
#' @examplesIf interactive()
#' # Basic preflight check
#' mysterycall_preflight_check(
#'   input_data = "physicians.csv",
#'   output_dir = "output/",
#'   google_maps_api_key = Sys.getenv("GOOGLE_API_KEY"),
#'   here_api_key = Sys.getenv("HERE_API_KEY")
#' )
#'
#' # Non-interactive (for scripts)
#' mysterycall_preflight_check(
#'   input_data = data,
#'   output_dir = "output/",
#'   interactive = FALSE
#' )
mysterycall_preflight_check <- function(input_data,
                                   output_dir,
                                   google_maps_api_key = NULL,
                                   here_api_key = NULL,
                                   check_apis = TRUE,
                                   estimate_resources = TRUE,
                                   prompt_user = interactive(),
                                   interactive = NULL,
                                   required_columns = c("first", "last")) {

  if (!is.null(interactive)) prompt_user <- interactive
  checkmate::assert_flag(check_apis)
  checkmate::assert_flag(estimate_resources)
  checkmate::assert_flag(prompt_user)
  checkmate::assert_character(required_columns, any.missing = FALSE)

  message("")
  message("\u256D", strrep("\u2500", 58), "\u256E")
  message("\u2502", "   mysterycall - Preflight Check", strrep(" ", 26), "\u2502")
  message("\u2570", strrep("\u2500", 58), "\u256F")
  message("")

  checks <- list(
    data = FALSE,
    output_dir = FALSE,
    api_keys = FALSE,
    data_quality = FALSE,
    resources = FALSE
  )

  errors <- character()
  warnings <- character()
  estimates <- NULL

  # ==================== Check 1: Input Data ====================
  message("\U0001F4CA Checking input data...")

  data_check <- tryCatch({
    if (is.character(input_data)) {
      if (!file.exists(input_data)) {
        errors <- c(errors, sprintf("Input file not found: %s. Provide an existing CSV/Parquet path or pass a data frame directly.", input_data))
        list(success = FALSE, n_rows = 0, data = NULL)
      } else {
        data <- mysterycall_read_table(input_data)
        checks$data <- TRUE
        message(sprintf("  \u2713 Input file found: %s (%s rows)",
                       basename(input_data),
                       format(nrow(data), big.mark = ",")))
        list(success = TRUE, n_rows = nrow(data), data = data)
      }
    } else if (is.data.frame(input_data)) {
      checks$data <- TRUE
      message(sprintf("  \u2713 Input data frame validated (%s rows)",
                     format(nrow(input_data), big.mark = ",")))
      list(success = TRUE, n_rows = nrow(input_data), data = input_data)
    } else {
      errors <- c(errors, sprintf("`input_data` must be either a file path or a data frame; received class: %s.", paste(class(input_data), collapse = ", ") ))
      list(success = FALSE, n_rows = 0, data = NULL)
    }
  }, error = function(e) {
    errors <<- c(errors, sprintf("Failed to load `input_data`: %s. Confirm the file format and read permissions.", e$message))
    list(success = FALSE, n_rows = 0, data = NULL)
  })

  # ==================== Check 2: Required Columns ====================
  if (data_check$success && !is.null(data_check$data)) {
    missing_cols <- setdiff(required_columns, names(data_check$data))
    if (length(missing_cols) > 0) {
      errors <- c(errors, sprintf(
        "Input data is missing required column(s): %s. Check column names/casing before retrying.",
        paste(missing_cols, collapse = ", ")
      ))
    } else {
      message(sprintf("  \u2713 All required columns present: %s",
                     paste(required_columns, collapse = ", ")))
    }
  }

  # ==================== Check 3: Output Directory ====================
  message("")
  message("\U0001F4BE Checking output directory...")

  if (!dir.exists(output_dir)) {
    tryCatch({
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
      checks$output_dir <- TRUE
      message(sprintf("  \u2713 Created output directory: %s", output_dir))
    }, error = function(e) {
      errors <<- c(errors, sprintf("Cannot create output directory '%s': %s. Check parent path and permissions.", output_dir, e$message))
    })
  } else {
    # Check if writable
    test_file <- file.path(output_dir, ".mysterycall_write_test")
    can_write <- tryCatch({
      writeLines("test", test_file)
      file.remove(test_file)
      TRUE
    }, error = function(e) FALSE)

    if (can_write) {
      checks$output_dir <- TRUE
      message(sprintf("  \u2713 Output directory writable: %s", output_dir))
    } else {
      errors <- c(errors, sprintf("Output directory is not writable: %s. Update permissions or choose another directory.", output_dir))
    }
  }

  # ==================== Check 4: API Keys ====================
  message("")
  message("\U0001F511 Checking API keys...")

  google_ok <- FALSE
  here_ok <- FALSE

  if (!is.null(google_maps_api_key) && !is.na(google_maps_api_key) && nzchar(google_maps_api_key)) {
    if (check_apis) {
      google_check <- mysterycall_validate_google_api(google_maps_api_key)
      if (google_check$valid) {
        message("  \u2713 Google Maps API key valid")
        google_ok <- TRUE
      } else {
        errors <- c(errors, sprintf("Google Maps API key validation failed: %s. Confirm the key is active and Geocoding API access is enabled.", google_check$error))
      }
    } else {
      message("  \u2713 Google Maps API key provided (not tested)")
      google_ok <- TRUE
    }
  } else {
    warnings <- c(warnings, "No Google Maps API key provided; geocoding steps will fail unless `google_maps_api_key` is supplied.")
  }

  if (!is.null(here_api_key) && !is.na(here_api_key) && nzchar(here_api_key)) {
    if (check_apis) {
      here_check <- mysterycall_validate_here_api(here_api_key)
      if (here_check$valid) {
        message("  \u2713 routing API key valid")
        here_ok <- TRUE
      } else {
        errors <- c(errors, sprintf("routing API key validation failed: %s. Confirm the key is active and has isochrone permissions.", here_check$error))
      }
    } else {
      message("  \u2713 routing API key provided (not tested)")
      here_ok <- TRUE
    }
  } else {
    warnings <- c(warnings, "No routing API key provided; isochrone generation will fail unless `here_api_key` is supplied.")
  }

  # api_keys is TRUE when every *provided* optional key is valid.
  # An absent key is not a failure  --  it only becomes one if the downstream
  # step that needs it is actually invoked.
  google_provided <- !is.null(google_maps_api_key) && !is.na(google_maps_api_key) && nzchar(google_maps_api_key)
  here_provided   <- !is.null(here_api_key)        && !is.na(here_api_key)        && nzchar(here_api_key)
  checks$api_keys <- (!google_provided || google_ok) && (!here_provided || here_ok)

  # ==================== Check 5: Data Quality ====================
  message("")
  message("\U0001F50D Checking data quality...")

  if (data_check$success && !is.null(data_check$data)) {
    quality_report <- mysterycall_assess_data_quality(
      data_check$data,
      required_columns = required_columns
    )

    checks$data_quality <- quality_report$score >= 0.70

    message(sprintf("  Data Quality Score: %.1f%% %s",
                   quality_report$score * 100,
                   if (quality_report$score >= 0.80) "\u2713" else "\u26A0"))

    if (quality_report$score < 0.70) {
      errors <- c(errors, "Data quality too low (< 70%). Review and clean data first.")
    } else if (quality_report$score < 0.80) {
      warnings <- c(warnings, sprintf(
        "Data quality acceptable but not ideal (%.1f%%). Consider cleaning data.",
        quality_report$score * 100
      ))
    }

    # Report specific issues
    for (issue in quality_report$issues) {
      if (issue$severity == "error") {
        message(sprintf("    \u2717 %s", issue$message))
      } else {
        message(sprintf("    \u26A0 %s", issue$message))
      }
    }
  }

  # ==================== Check 6: Resource Estimation ====================
  if (estimate_resources && data_check$success) {
    message("")
    message("\U0001F4CA Estimating resources...")

    estimates <- mysterycall_estimate_resources(data_check$n_rows)

    message(sprintf("  \u23F1 Estimated runtime: %s (for %s records)",
                   estimates$runtime_str,
                   format(data_check$n_rows, big.mark = ",")))
    message(sprintf("  \U0001F4BE Estimated memory: %s",
                   estimates$memory_str))

    if (estimates$memory_gb > 8) {
      warnings <- c(warnings, sprintf(
        "High memory usage estimated (%.1f GB). Ensure sufficient RAM available.",
        estimates$memory_gb
      ))
    }

    if (estimates$runtime_hours > 2) {
      warnings <- c(warnings, sprintf(
        "Long runtime estimated (%.1f hours). Consider running overnight or in batches.",
        estimates$runtime_hours
      ))
    }

    checks$resources <- TRUE
  }

  # ==================== Check 7: Dependencies ====================
  message("")
  message("\U0001F4E6 Checking dependencies...")

  core_packages <- c("dplyr", "npi")
  optional_packages <- c("tidyr", "sf", "ggmap")
  missing_core <- character()
  missing_optional <- character()

  for (pkg in core_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      missing_core <- c(missing_core, pkg)
    }
  }
  for (pkg in optional_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      missing_optional <- c(missing_optional, pkg)
    }
  }

  if (length(missing_core) > 0) {
    errors <- c(errors, sprintf(
      "Missing required packages: %s",
      paste(missing_core, collapse = ", ")
    ))
  } else {
    message(sprintf("  \u2713 Core packages installed (%d checked)",
                   length(core_packages)))
  }
  if (length(missing_optional) > 0) {
    warnings <- c(warnings, sprintf(
      "Optional packages not installed (only needed for specific workflows): %s",
      paste(missing_optional, collapse = ", ")
    ))
  }

  # ==================== Summary ====================
  message("")
  message(strrep("\u2500", 60))

  all_passed <- length(errors) == 0
  has_warnings <- length(warnings) > 0

  if (all_passed && !has_warnings) {
    message("")
    message("  \u2705 All preflight checks PASSED")
    message("")
  } else if (all_passed && has_warnings) {
    message("")
    message("  \u26A0 Preflight checks passed with WARNINGS:")
    for (w in warnings) {
      message(sprintf("    - %s", w))
    }
    message("")
  } else {
    message("")
    message("  \u274C Preflight checks FAILED:")
    for (e in errors) {
      message(sprintf("    - %s", e))
    }
    if (has_warnings) {
      message("")
      message("  Warnings:")
      for (w in warnings) {
        message(sprintf("    - %s", w))
      }
    }
    message("")
    message(strrep("\u2500", 60))
    stop("Preflight checks failed. Fix errors above before proceeding.", call. = FALSE)
  }

  # ==================== User Confirmation ====================
  if (prompt_user && all_passed) {
    message(strrep("\u2500", 60))
    message("")
    if (data_check$success) {
      message(sprintf("  Ready to process %s records",
                     format(data_check$n_rows, big.mark = ",")))
      if (estimate_resources && exists("estimates", inherits = FALSE)) {
        message(sprintf("  Estimated time: %s", estimates$runtime_str))
        message(sprintf("  Estimated memory: %s", estimates$memory_str))
      }
    }
    message("")

    response <- readline(prompt = "  \u25B6 Proceed with workflow? [Y/n]: ")

    if (tolower(trimws(response)) %in% c("n", "no")) {
      message("")
      message("  \u26A0 Workflow cancelled by user")
      message("")
      stop("User cancelled workflow", call. = FALSE)
    }

    message("")
    message("  \u2705 Starting workflow...")
    message("")
  }

  message(strrep("\u2500", 60))
  message("")

  invisible(list(
    passed = all_passed,
    checks = checks,
    errors = errors,
    warnings = warnings,
    data = data_check$data,
    n_rows = data_check$n_rows,
    estimates = if (estimate_resources) estimates else NULL
  ))
}


#' Validate Google Maps API key
#'
#' @param api_key Google Maps API key
#' @return List with valid (logical) and error (character) fields
#' @keywords internal
mysterycall_validate_google_api <- function(api_key) {
  if (!requireNamespace("ggmap", quietly = TRUE)) {
    return(list(valid = FALSE, error = "Package 'ggmap' is required to validate the Google Maps API key"))
  }
  tryCatch({
    # Try a simple geocoding request
    ggmap::register_google(key = api_key)
    result <- ggmap::geocode("1600 Amphitheatre Parkway, Mountain View, CA", key = api_key)

    if (is.data.frame(result) && nrow(result) == 1) {
      list(valid = TRUE, error = NULL)
    } else {
      list(valid = FALSE, error = "API returned unexpected result")
    }
  }, error = function(e) {
    list(valid = FALSE, error = e$message)
  })
}


#' Validate routing API key
#'
#' @param api_key routing API key
#' @return List with valid (logical) and error (character) fields
#' @keywords internal
mysterycall_validate_here_api <- function(api_key) {
  if (!requireNamespace("httr", quietly = TRUE)) {
    return(list(valid = FALSE, error = "Package 'httr' is required to validate the HERE API key"))
  }
  tryCatch({
    # Use query parameters so the key is never embedded in the URL string and
    # cannot leak into logs, error messages, or httr verbose output.
    response <- httr::GET(
      "https://isoline.router.hereapi.com/v8/isolines",
      query = list(
        transportMode    = "car",
        origin           = "40.7128,-74.0060",
        "range[type]"   = "time",
        "range[values]" = "300",
        apiKey           = api_key
      ),
      httr::timeout(10)
    )

    if (httr::status_code(response) == 200) {
      list(valid = TRUE, error = NULL)
    } else if (httr::status_code(response) == 401) {
      list(valid = FALSE, error = "API key unauthorized (401)")
    } else if (httr::status_code(response) == 403) {
      list(valid = FALSE, error = "API key forbidden (403)")
    } else {
      list(valid = FALSE, error = sprintf("API returned status %d", httr::status_code(response)))
    }
  }, error = function(e) {
    list(valid = FALSE, error = e$message)
  })
}


#' Assess data quality
#'
#' Scores a data frame for completeness and validity on a 0-1 scale, returning
#' both the overall score and a detailed list of specific issues that may affect
#' downstream workflow steps.  Penalties are applied for missing values in
#' required columns (>50% missing = -3 pts, 20-50% = -1 pt), excessive
#' duplicate rows (>10% = -1 pt), and non-character NPI or name columns.
#'
#' @param data Data frame to assess.
#' @param required_columns Character vector of column names that must be present
#'   and sufficiently complete. Defaults to \code{c("first", "last")}.
#'
#' @return A named list with elements \code{score} (numeric 0-1) and
#'   \code{issues} (list of issue records with \code{severity} and
#'   \code{message} fields).
#'
#' @section Scoring method:
#'   Quality is scored on a 0-1 scale by subtracting penalties from a
#'   maximum of 10:
#'   \itemize{
#'     \item Required column with > 50\% missing values: -3 points
#'     \item Required column with 20-50\% missing values: -1 point
#'     \item More than 10\% duplicate rows: -1 point
#'     \item Required column is not character or factor type: -0.5 points
#'   }
#'   Final score = max(0, 1 - penalties / 10).
#'
#'   Worked examples for a 1,000-row physician roster with `required_columns
#'   = c("first", "last")`:
#'   \itemize{
#'     \item All names present, < 10\% duplicates -> **1.00** (100\%, pass)
#'     \item 30\% of `first` names missing -> **0.90** (90\%, pass)
#'     \item 60\% of `first` names missing -> **0.70** (70\%, borderline pass with warning)
#'     \item Both columns > 50\% missing (-3 each) -> **0.40** (40\%, preflight stops)
#'   }
#'   The 0.70 and 0.80 thresholds in [mysterycall_preflight_check()] were
#'   chosen to catch severely incomplete data while tolerating modest
#'   missingness in large rosters.
#'
#' @seealso [mysterycall_preflight_check()] which calls this function;
#'   [mysterycall_estimate_resources()] for runtime/memory projections.
#' @family utilities
#' @export
#' @examples
#' df <- data.frame(first = c("Jane", NA), last = c("Doe", "Smith"))
#' mysterycall_assess_data_quality(df)
mysterycall_assess_data_quality <- function(data, required_columns = c("first", "last")) {
  issues <- list()
  penalties <- 0
  max_penalties <- 10

  if (!nrow(data)) {
    return(list(score = 0, issues = list(list(severity = "error", message = "Input data has zero rows")), penalties = max_penalties))
  }

  # Check for missing values in required columns
  for (col in required_columns) {
    if (col %in% names(data)) {
      na_count <- sum(is.na(data[[col]]))
      na_pct <- if (nrow(data) > 0) na_count / nrow(data) else 0

      if (na_pct > 0.5) {
        issues <- c(issues, list(list(
          severity = "error",
          message = sprintf("Column '%s' has %.1f%% missing values", col, na_pct * 100)
        )))
        penalties <- penalties + 3
      } else if (na_pct > 0.2) {
        issues <- c(issues, list(list(
          severity = "warning",
          message = sprintf("Column '%s' has %.1f%% missing values", col, na_pct * 100)
        )))
        penalties <- penalties + 1
      }
    }
  }

  # Check for duplicate rows
  dup_count <- sum(duplicated(data))
  dup_pct <- if (nrow(data) > 0) dup_count / nrow(data) else 0

  if (dup_pct > 0.1) {
    issues <- c(issues, list(list(
      severity = "warning",
      message = sprintf("%.1f%% duplicate rows detected", dup_pct * 100)
    )))
    penalties <- penalties + 1
  }

  # Check for data type consistency
  for (col in required_columns) {
    if (col %in% names(data)) {
      if (!is.character(data[[col]]) && !is.factor(data[[col]])) {
        issues <- c(issues, list(list(
          severity = "warning",
          message = sprintf("Column '%s' should be character/text type", col)
        )))
        penalties <- penalties + 0.5
      }
    }
  }

  score <- if (max_penalties == 0) 1 else max(0, 1 - (penalties / max_penalties))

  list(
    score = score,
    issues = issues,
    penalties = penalties
  )
}


#' Estimate workflow resources
#'
#' Projects the approximate runtime and memory requirements for a mystery caller
#' workflow based on the number of input rows.
#'
#' @param n_rows Integer number of input rows.
#'
#' @return A named `list` with elements:
#' \describe{
#'   \item{`runtime_seconds`}{`numeric`. Total estimated wall time in seconds.}
#'   \item{`runtime_hours`}{`numeric`. Total estimated wall time in hours.}
#'   \item{`runtime_str`}{`character`. Human-readable runtime string
#'     (e.g., `"45 minutes"` or `"2h 15m"`).}
#'   \item{`memory_mb`}{`numeric`. Estimated peak memory in megabytes.}
#'   \item{`memory_gb`}{`numeric`. Estimated peak memory in gigabytes.}
#'   \item{`memory_str`}{`character`. Human-readable memory string
#'     (e.g., `"1.5 GB"` or `"700 MB"`).}
#' }
#'
#' @section Estimation method:
#'   Runtime is estimated as `n_rows x 4.5` seconds: 1.5 s/row for NPI
#'   registry lookups, 0.5 s/row for geocoding (assumes a warm Google Maps
#'   cache), and 2.5 s/row for HERE isochrone generation. Memory is
#'   `(n_rows x 2) + 500` MB.
#'
#'   Reference values for the full workflow:
#'   \tabular{rrl}{
#'     **Rows** \tab **Est. runtime** \tab **Est. memory** \cr
#'     100 \tab ~8 min \tab ~700 MB \cr
#'     500 \tab ~38 min \tab ~1.5 GB \cr
#'     1,000 \tab ~75 min \tab ~2.5 GB \cr
#'     5,000 \tab ~6.3 h \tab ~10.3 GB
#'   }
#'   These constants reflect typical US residential broadband with warm API
#'   caches. Slow networks or cold caches can **triple** the runtime estimate.
#'   Benchmark on 50-100 rows before committing to a large run.
#'
#'   If only a subset of the pipeline is used (e.g., NPI lookup only), the
#'   relevant per-row constant is 1.5 s (NPI), 0.5 s (geocoding), or 2.5 s
#'   (isochrones), not the combined 4.5 s.
#'
#' @seealso [mysterycall_preflight_check()] which calls this function;
#'   [mysterycall_assess_data_quality()] for data completeness scoring.
#' @family utilities
#' @export
#' @examples
#' mysterycall_estimate_resources(500)
mysterycall_estimate_resources <- function(n_rows) {
  # Rough estimates based on typical performance
  # These should be calibrated with real-world data

  # Time estimates (seconds per row for each major operation)
  time_per_row_npi <- 1.5  # NPI search
  time_per_row_geocode <- 0.5  # Geocoding (cached)
  time_per_row_isochrone <- 2.5  # Isochrone generation

  total_seconds <- n_rows * (time_per_row_npi + time_per_row_geocode + time_per_row_isochrone)
  runtime_hours <- total_seconds / 3600

  # Memory estimates (MB per row)
  memory_per_row <- 2  # Rough estimate for full workflow
  memory_mb <- n_rows * memory_per_row + 500  # +500 MB base
  memory_gb <- memory_mb / 1024

  # Format strings
  if (runtime_hours < 1) {
    runtime_minutes <- total_seconds / 60
    runtime_str <- sprintf("%.0f minutes", runtime_minutes)
  } else {
    hours <- floor(runtime_hours)
    minutes <- round((runtime_hours - hours) * 60)
    runtime_str <- sprintf("%dh %dm", hours, minutes)
  }

  if (memory_gb < 1) {
    memory_str <- sprintf("%.0f MB", memory_mb)
  } else {
    memory_str <- sprintf("%.1f GB", memory_gb)
  }

  list(
    runtime_seconds = total_seconds,
    runtime_hours = runtime_hours,
    runtime_str = runtime_str,
    memory_mb = memory_mb,
    memory_gb = memory_gb,
    memory_str = memory_str
  )
}
