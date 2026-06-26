#' Download a large file with resume support
#'
#' Provides a resilient download helper that prefers `wget` with
#' continuation support, falling back to `curl` and then base R's
#' `download.file()`. Downloads are written to a temporary `.download`
#' file and moved to the requested destination once the transfer is
#' complete. A lightweight lock file prevents concurrent downloads of
#' the same target path.
#'
#' @param url URL of the file to download.
#' @param dest Destination file path for the downloaded file.
#' @param overwrite Logical. If `TRUE`, overwrite any existing file at
#'   `dest`. Defaults to `FALSE`.
#' @param quiet Logical. When `TRUE` (default) suppress command output
#'   emitted by the underlying download tools.
#'
#' @return The path to the downloaded file (i.e. `dest`).
#' @export
#'
#' @examplesIf interactive()
#' mysterycall_download_file(
#'   "https://example.org/big-file.zip",
#'   file.path(tempdir(), "big-file.zip")
#' )
#'
#' @importFrom httr HEAD headers timeout
#' @family utilities
#' @seealso [utils::download.file()]
mysterycall_download_file <- function(url, dest, overwrite = FALSE, quiet = TRUE) {
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("Package 'httr' is required for mysterycall_download_file(). Install it with install.packages('httr').", call. = FALSE)
  }
  if (!is.character(url) || length(url) != 1L || !nzchar(url)) {
    stop("`url` must be a non-empty character string.", call. = FALSE)
  }
  if (!is.character(dest) || length(dest) != 1L || !nzchar(dest)) {
    stop("`dest` must be a non-empty character string.", call. = FALSE)
  }

  dest <- normalizePath(dest, mustWork = FALSE)
  dest_dir <- dirname(dest)
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  }

  expected_size <- get_content_length(url)

  dest_tmp <- paste0(dest, ".download")
  lock_path <- paste0(dest, ".lock")
  download_success <- FALSE
  lock_owned <- FALSE

  lock_age_ok <- function(path) {
    info <- file.info(path)
    if (is.na(info$mtime)) {
      return(FALSE)
    }
    difftime(Sys.time(), info$mtime, units = "hours") < 6
  }

  create_lock <- function(path) {
    tryCatch({
      con <- file(path, open = "wx")
      close(con)
      TRUE
    }, error = function(e) {
      FALSE
    })
  }

  if (file.exists(lock_path)) {
    if (lock_age_ok(lock_path)) {
      if (!isTRUE(overwrite) && is_download_complete(dest, expected_size)) {
        return(dest)
      }
      stop(sprintf(
        "Download for '%s' appears to be in progress and destination is not complete.",
        dest
      ), call. = FALSE)
    }
    unlink(lock_path)
  }

  lock_owned <- create_lock(lock_path)
  if (!lock_owned) {
    if (file.exists(lock_path) && lock_age_ok(lock_path)) {
      if (!isTRUE(overwrite) && is_download_complete(dest, expected_size)) {
        return(dest)
      }
      stop(sprintf(
        "Download for '%s' appears to be in progress and destination is not complete.",
        dest
      ), call. = FALSE)
    }
    stop(sprintf("Unable to create lock file '%s'.", lock_path), call. = FALSE)
  }
  on.exit(if (lock_owned && file.exists(lock_path)) unlink(lock_path), add = TRUE)

  if (file.exists(dest)) {
    if (isTRUE(overwrite)) {
      unlink(dest)
    } else if (is_download_complete(dest, expected_size)) {
      return(dest)
    } else {
      if (file.exists(dest_tmp)) {
        unlink(dest_tmp)
      }
      if (!file.rename(dest, dest_tmp)) {
        stop("Failed to move existing file to temporary path for resuming download.", call. = FALSE)
      }
    }
  }

  if (file.exists(dest_tmp) && isTRUE(overwrite)) {
    unlink(dest_tmp)
  }

  if (!file.exists(dest_tmp)) {
    if (!file.create(dest_tmp)) {
      stop(sprintf("Unable to create temporary file '%s'.", dest_tmp), call. = FALSE)
    }
    on.exit(if (file.exists(dest_tmp) && !download_success) unlink(dest_tmp), add = TRUE)
  }

  attempts <- list(download_with_wget, download_with_curl, download_with_download_file)

  for (attempt in attempts) {
    succeeded <- isTRUE(attempt(url, dest_tmp, quiet))
    if (succeeded && is_download_complete(dest_tmp, expected_size)) {
      download_success <- TRUE
      break
    }
  }

  if (!download_success) {
    stop(sprintf("Failed to download '%s' to '%s'.", url, dest), call. = FALSE)
  }

  if (file.exists(dest)) {
    unlink(dest)
  }

  if (!file.rename(dest_tmp, dest)) {
    stop("Unable to move downloaded file into place.", call. = FALSE)
  }

  dest
}

get_content_length <- function(url, timeout_sec = 30) {
  tryCatch({
    resp <- httr::HEAD(url, httr::timeout(timeout_sec))
    headers <- httr::headers(resp)
    len <- headers[["content-length"]]
    if (is.null(len)) {
      len <- headers[["Content-Length"]]
    }
    if (is.null(len)) {
      return(NA_real_)
    }
    suppressWarnings(as.numeric(len))
  }, error = function(e) {
    NA_real_
  })
}

is_download_complete <- function(path, expected_size) {
  if (!file.exists(path)) {
    return(FALSE)
  }
  info <- file.info(path)
  size <- info$size
  if (is.na(size) || size < 1) {
    return(FALSE)
  }
  if (is.na(expected_size) || !is.finite(expected_size)) {
    return(TRUE)
  }
  size >= expected_size
}

download_with_wget <- function(url, dest, quiet = TRUE) {
  cmd <- Sys.which("wget")
  if (!nzchar(cmd)) {
    return(FALSE)
  }
  args <- c("--timeout=600", "--tries=3", "--continue", "-O", shQuote(dest), shQuote(url))
  stdout <- if (quiet) FALSE else ""
  stderr <- if (quiet) FALSE else ""
  status <- suppressWarnings(system2(cmd, args, stdout = stdout, stderr = stderr))
  identical(status, 0)
}

download_with_curl <- function(url, dest, quiet = TRUE) {
  cmd <- Sys.which("curl")
  if (!nzchar(cmd)) {
    return(FALSE)
  }
  args <- c("--fail", "--location", "--retry", "3", "--continue-at", "-", "--max-time", "600", "--output", shQuote(dest), shQuote(url))
  if (quiet) {
    args <- c("--silent", "--show-error", args)
  }
  stdout <- if (quiet) FALSE else ""
  stderr <- if (quiet) FALSE else ""
  status <- suppressWarnings(system2(cmd, args, stdout = stdout, stderr = stderr))
  identical(status, 0)
}

download_with_download_file <- function(url, dest, quiet = TRUE) {
  tryCatch({
    utils::download.file(url, dest, quiet = quiet, mode = "wb")
    TRUE
  }, error = function(e) {
    FALSE
  })
}
