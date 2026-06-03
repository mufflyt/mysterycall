#' Resolve project-relative paths from standard aliases
#'
#' @param ... Additional path components appended to the resolved base.
#' @param type Optional alias describing the base path. Supported values are
#'   `"data"`, `"raw-data"`, `"tables"`, `"figures"`, `"docs"`, and `"cache"`.
#'   When `NULL`, `...` are treated as relative to `base_dir`.
#' @param base_dir Base directory to resolve paths from. Defaults to the value
#'   stored in `getOption("mysterycall.base_dir")` or the current working directory.
#' @param create Logical. When `TRUE`, ensure the resolved parent directory
#'   exists.
#'
#' @return A normalized path as a character string.
#' @family utilities
#' @export
#' @examples
#' mysterycall_resolve_path("output.csv", type = "tables", create = FALSE)
mysterycall_resolve_path <- function(..., type = NULL, base_dir = getOption("mysterycall.base_dir", getwd()), create = FALSE) {
  if (!dir.exists(base_dir)) {
    stop(sprintf("Base directory '%s' does not exist.", base_dir), call. = FALSE)
  }

  aliases <- c(
    data = "data",
    `raw-data` = "data-raw",
    tables = "tables",
    figures = file.path("tables", "figures"),
    docs = "docs",
    cache = mysterycall_tempdir("cache")
  )

  base <- base_dir
  if (!is.null(type)) {
    if (!type %in% names(aliases)) {
      stop(sprintf("Unknown path alias '%s'.", type), call. = FALSE)
    }
    base <- file.path(base, aliases[[type]])
  }

  path <- file.path(base, ...)
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)

  if (isTRUE(create)) {
    dir_to_create <- if (dir.exists(path) || grepl("\\.[^/]+$", path)) dirname(path) else path
    if (!dir.exists(dir_to_create)) {
      dir.create(dir_to_create, recursive = TRUE, showWarnings = FALSE)
    }
  }

  path
}

#' Write tabular or graphical outputs with timestamped backups
#'
#' @param x Object to export. Data frames are written as CSV files by default
#'   while `ggplot` objects are saved with [ggplot2::ggsave()]. Other objects
#'   are serialized via [saveRDS()].
#' @param path Destination file path.
#' @param backup Logical flag; when `TRUE` and `path` already exists, create a
#'   timestamped copy before overwriting.
#' @param quiet Logical flag controlling log output.
#'
#' @return The resolved path (invisible).
#' @importFrom ggplot2 ggsave
#' @importFrom readr write_csv
#' @importFrom utils write.table
#' @family utilities
#' @export
#' @examples
#' tmp <- tempfile(fileext = ".csv")
#' mysterycall_export_with_backup(mtcars, tmp)
mysterycall_export_with_backup <- function(x, path, backup = TRUE, quiet = getOption("mysterycall.quiet", FALSE)) {
  if (missing(path) || !nzchar(path)) {
    stop("`path` must be a non-empty string.", call. = FALSE)
  }

  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  if (isTRUE(backup) && file.exists(path)) {
    timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
    backup_path <- sprintf("%s.%s.bak", path, timestamp)
    file.copy(path, backup_path, overwrite = TRUE)
    if (!quiet) {
      message(sprintf("Existing file backed up to %s", backup_path))
    }
  }

  ext <- tolower(tools::file_ext(path))
  if (inherits(x, "ggplot") && nzchar(ext)) {
    ggplot2::ggsave(filename = path, plot = x)
  } else if (is.data.frame(x) && identical(ext, "csv")) {
    readr::write_csv(x, path)
  } else if (identical(ext, "rds")) {
    saveRDS(x, path)
  } else if (identical(ext, "rda")) {
    save(list = deparse(substitute(x)), file = path)
  } else if (is.data.frame(x) && nzchar(ext)) {
    utils::write.table(x, file = path, sep = ",", row.names = FALSE)
  } else {
    saveRDS(x, if (nzchar(ext)) path else sprintf("%s.rds", path))
  }

  invisible(path)
}
