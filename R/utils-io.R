#' Internal helpers for reading and writing roster files
#'
#' These helpers standardize how the package reads and writes tabular
#' datasets so that functions can transparently support both CSV and Parquet
#' storage without duplicating logic.
#'
#' @name io_helpers
#' @keywords internal
NULL

# nocov start

#' Normalize File Format for I/O
#'
#' @param format Optional character scalar: "csv" or "parquet".
#' @param path Optional character scalar. File path to infer format from.
#' @param default Character scalar to return if format cannot be inferred.
#'
#' @return Character scalar: "csv" or "parquet".
#' @family utilities
#' @keywords internal
mysterycall_normalize_file_format <- function(format = NULL, path = NULL, default = "csv") {
  choices <- c("csv", "parquet")
  if (!is.null(format)) {
    return(match.arg(format, choices))
  }
  if (!is.null(path)) {
    ext <- tolower(tools::file_ext(path))
    if (nzchar(ext) && ext %in% choices) {
      return(ext)
    }
  }
  default
}

#' Require arrow Package for Parquet Support
#'
#' @return `invisible(NULL)`; stops if arrow is missing.
#' @family utilities
#' @keywords internal
mysterycall_require_arrow <- function() {
  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop(
      "The 'arrow' package is required to read or write Parquet files. ",
      "",
      call. = FALSE
    )
  }
}

#' Read a tabular data file (CSV or Parquet)
#'
#' Transparently reads a dataset from disk using either [readr::read_csv()] or
#' [arrow::read_parquet()] based on the file extension or the `format` argument.
#' If an `npi` column is present and numeric, it is automatically coerced to
#' character to prevent loss of leading zeros or precision.
#'
#' @param path Character scalar. Path to the file.
#' @param format Optional character scalar: `"csv"` or `"parquet"`. If `NULL`,
#'   the format is inferred from the `path` extension.
#' @param ... Additional arguments passed to the underlying reader.
#'
#' @return A data frame (tibble).
#' @family utilities
#' @export
#' @examples
#' \donttest{
#' tmp <- tempfile(fileext = ".csv")
#' write.csv(mtcars, tmp, row.names = FALSE)
#' df <- mysterycall_read_table(tmp)
#' }
mysterycall_read_table <- function(path, format = NULL, ...) {
  fmt <- mysterycall_normalize_file_format(format, path = path)
  df <- if (identical(fmt, "csv")) {
    if (!requireNamespace("readr", quietly = TRUE)) {
      stop("Package 'readr' is required for CSV reading. Install it or write/read in Parquet via the 'arrow' package.", call. = FALSE)
    }
    readr::read_csv(path, show_col_types = FALSE, ...)
  } else {
    mysterycall_require_arrow()
    arrow::read_parquet(path, as_data_frame = TRUE)
  }
  if ("npi" %in% names(df) && is.numeric(df[["npi"]])) {
    npi_vals <- df[["npi"]]
    non_integer <- !is.na(npi_vals) & (npi_vals != floor(npi_vals))
    if (any(non_integer)) {
      warning(sprintf(
        paste0(
          "%d NPI value(s) are stored as non-integer numeric (e.g. %g) and will be ",
          "rounded to the nearest integer, which may produce invalid NPIs. ",
          "Save the source file with the NPI column as character type to prevent this."
        ),
        sum(non_integer), npi_vals[which(non_integer)[1L]]
      ), call. = FALSE)
    }
    df[["npi"]] <- sprintf("%.0f", npi_vals)
  }
  df
}

#' Write a data frame to a tabular file (CSV or Parquet)
#'
#' Transparently writes a data frame to disk using either [readr::read_csv()]
#' or [arrow::write_parquet()]. For CSV format, writes are performed atomically
#' to a temporary file then renamed to reduce the risk of file corruption
#' during concurrent access.
#'
#' @param data A data frame to save.
#' @param path Character scalar. Destination path.
#' @param format Optional character scalar: `"csv"` or `"parquet"`. If `NULL`,
#'   the format is inferred from the `path` extension.
#' @param append Logical. If `TRUE`, appends to the existing file. Only
#'   supported for CSV; for Parquet, this reads the existing file and re-writes
#'   the combined dataset.
#' @param col_names Logical. Whether to write column names. Default `TRUE`.
#' @param ... Additional arguments passed to the underlying writer.
#'
#' @return The input `path` (invisibly).
#' @family utilities
#' @export
#' @examples
#' \donttest{
#' tmp <- tempfile(fileext = ".csv")
#' mysterycall_write_table(mtcars, tmp)
#' }
mysterycall_write_table <- function(data, path, format = NULL, append = FALSE, col_names = TRUE, ...) {
  fmt <- mysterycall_normalize_file_format(format, path = path)
  if (identical(fmt, "csv")) {
    if (!requireNamespace("readr", quietly = TRUE)) {
      stop("Package 'readr' is required for CSV writing. Install it or write in Parquet via the 'arrow' package.", call. = FALSE)
    }
    # Atomic write for non-append mode to reduce race-condition risk when
    # multiple processes target the same path.
    if (!append) {
      tmp <- tempfile(
        pattern = paste0(basename(path), "_"),
        tmpdir = dirname(path),
        fileext = ".tmp"
      )
      on.exit(if (file.exists(tmp)) unlink(tmp, force = TRUE), add = TRUE)
      readr::write_csv(data, tmp, append = FALSE, col_names = col_names, ...)
      if (!file.rename(tmp, path)) {
        stop("Failed to atomically replace file: ", path, call. = FALSE)
      }
    } else {
      readr::write_csv(data, path, append = TRUE, col_names = col_names, ...)
    }
  } else {
    mysterycall_require_arrow()
    if (inherits(data, "grouped_df")) {
      data <- dplyr::ungroup(data)
    }
    if (append && file.exists(path)) {
      existing <- mysterycall_read_table(path, format = "parquet")
      data <- dplyr::bind_rows(existing, data)
    }
    arrow::write_parquet(data, sink = path, ...)
  }
  invisible(path)
}

# nocov end
