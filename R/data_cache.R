#' Internal helpers for managing cached external data
#'
#' These helpers provide a small abstraction over the user cache directory
#' used to persist large external resources that are downloaded on demand.
#' They are not exported.
#'
#' @name data_cache_helpers
#' @keywords internal
NULL

# nocov start

#' Determine the cache directory used for downloaded resources
#'
#' @param ... Optional path components appended to the cache directory.
#'
#' @return Character scalar. Absolute path to the cache directory. When `...`
#'   is empty, returns the cache root (created automatically if absent). When
#'   `...` supplies path components, they are appended via `file.path()` before
#'   returning; the directory is not created in that case.
#' @examples
#' mysterycall:::mysterycall_cache_dir()
#' mysterycall:::mysterycall_cache_dir("hrr")
mysterycall_cache_dir <- function(...) {
  cache_root <- if (getRversion() >= "4.0.0") {
    tools::R_user_dir("mysterycall", which = "cache")
  } else {
    file.path(path.expand("~"), ".cache", "mysterycall")
  }

  if (!dir.exists(cache_root)) {
    dir.create(cache_root, recursive = TRUE, showWarnings = FALSE)
  }

  if (missing(...)) {
    cache_root
  } else {
    file.path(cache_root, ...)
  }
}

#' Ensure the Dartmouth Atlas HRR boundary shapefile is available locally
#'
#' Downloads the shapefile archive from the Dartmouth Atlas website when it is
#' not already present in the user's cache directory. The archive is expanded
#' in-place and the path to the `.shp` file is returned.
#'
#' @param quiet Logical flag passed to [mysterycall_download_file()] to silence the
#'   underlying download tooling.
#'
#' @return The absolute path to the HRR boundary shapefile.
#' @examples
#' # Requires internet access to download an ~8 MB shapefile on first call.
#' \dontrun{
#' mysterycall:::ensure_hrr_shapefile()
#' }
ensure_hrr_shapefile <- function(quiet = TRUE) {
  cache_root <- mysterycall_cache_dir()
  archive_path <- file.path(cache_root, "HRR_Bdry__AK_HI_unmodified.zip")
  shapefile_path <- file.path(
    cache_root,
    "HRR_Bdry__AK_HI_unmodified",
    "mysterycall_hrr-shapefile",
    "Hrr98Bdry_AK_HI_unmodified.shp"
  )

  if (!file.exists(shapefile_path)) {
    message("Downloading HRR boundary shapefile (~8 MB). This is a one-time operation.")
    mysterycall_download_file(
      "https://data.dartmouthatlas.org/downloads/geography/HRR_Bdry__AK_HI_unmodified.zip",
      archive_path,
      overwrite = TRUE,
      quiet = quiet
    )

    utils::unzip(archive_path, exdir = cache_root)
    macos_metadata <- file.path(cache_root, "__MACOSX")
    if (dir.exists(macos_metadata)) {
      unlink(macos_metadata, recursive = TRUE, force = TRUE)
    }
  }

  if (!file.exists(shapefile_path)) {
    stop(
      "Failed to retrieve the HRR boundary shapefile. ",
      "Please try again or download it manually from ",
      "https://data.dartmouthatlas.org/supplemental/.",
      call. = FALSE
    )
  }

  shapefile_path
}

# nocov end
