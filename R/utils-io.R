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

mysterycall_require_arrow <- function() {
  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop(
      "The 'arrow' package is required to read or write Parquet files. ",
      "",
      call. = FALSE
    )
  }
}

mysterycall_read_table <- function(path, format = NULL, ...) {
  fmt <- mysterycall_normalize_file_format(format, path = path)
  df <- if (identical(fmt, "csv")) {
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

mysterycall_write_table <- function(data, path, format = NULL, append = FALSE, col_names = TRUE, ...) {
  fmt <- mysterycall_normalize_file_format(format, path = path)
  if (identical(fmt, "csv")) {
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
