#' Check for required R package dependencies
#'
#' @param packages Character vector of package names to verify.
#' @param install Logical; when `TRUE`, attempt to install missing packages
#'   using [install.packages()]. Defaults to `FALSE`.
#' @param repos Character vector of repositories to forward to
#'   [install.packages()] when `install = TRUE`.
#' @param quietly Logical flag controlling console output. When `TRUE`,
#'   suppresses status messages.
#'
#' @return A tibble summarizing the dependency status for each package.
#' @importFrom tibble as_tibble
#' @importFrom utils installed.packages install.packages
#' @family utilities
#' @export
#' @examples
#' \donttest{
#' mysterycall_check_dependencies(c("dplyr", "sf"), install = FALSE)
#' }
mysterycall_check_dependencies <- function(packages, install = FALSE, repos = getOption("repos"), quietly = FALSE) {
  if (!is.character(packages)) {
    stop("`packages` must be a character vector of package names.", call. = FALSE)
  }

  packages <- unique(packages[nzchar(packages)])
  if (!length(packages)) {
    stop("No packages supplied to `mysterycall_check_dependencies()`.", call. = FALSE)
  }

  installed <- utils::installed.packages()[, c("Package", "Version"), drop = FALSE]
  installed_names <- installed[, "Package"]

  results <- lapply(packages, function(pkg) {
    is_installed <- pkg %in% installed_names
    version <- if (is_installed) installed[installed_names == pkg, "Version"] else NA_character_
    install_command <- sprintf("install.packages(\"%s\")", pkg)
    list(
      package = pkg,
      installed = is_installed,
      version = version,
      install_command = install_command
    )
  })

  summary <- dplyr::bind_rows(results)

  missing_pkgs <- summary$package[!summary$installed]
  if (length(missing_pkgs)) {
    message_fn <- if (isTRUE(quietly)) identity else message
    message_fn(sprintf(
      "Missing %d package(s): %s",
      length(missing_pkgs),
      paste(missing_pkgs, collapse = ", ")
    ))

    if (isTRUE(install)) {
      for (pkg in missing_pkgs) {
        message_fn(sprintf("Installing %s via install.packages().", pkg))
        utils::install.packages(pkg, repos = repos)
      }
    }
  }

  summary
}
