#' Physician gender from the NPPES registry
#'
#' Returns the **registry-reported** sex for each NPI, read straight from the
#' NPPES `basic_sex` field via the \pkg{npi} package. This is the authoritative
#' self-/registrant-reported value and is the preferred gender source for
#' mystery-caller studies -- unlike first-name inference (Genderize.io), it does
#' not guess, has no per-name error, and needs no external quota.
#'
#' NPPES covers essentially every US clinician with an NPI, so coverage is
#' near-complete; a small number of records leave `basic_sex` blank and return
#' `NA`.
#'
#' @param npi Character or numeric vector of 10-digit NPIs.
#' @param verbose Logical; print a one-line coverage summary. Default `FALSE`.
#'
#' @return A [tibble::tibble()] with one row per **unique** input NPI:
#'   \describe{
#'     \item{npi}{The NPI, as character.}
#'     \item{gender}{`"Male"`, `"Female"`, or `NA`.}
#'     \item{gender_source}{`"NPPES"` when found, else `NA`.}
#'   }
#'
#' @details
#' One NPPES query per unique NPI (the \pkg{npi} package has no bulk-by-number
#' endpoint). Invalid NPIs, lookup failures, and records without a sex code all
#' yield `NA` gender rather than an error.
#'
#' @family npi
#' @seealso [mysterycall_get_clinician_data()], which attaches DAC gender and can
#'   fall back to this function; [mysterycall_genderize()], the name-inference
#'   approach this is designed to replace.
#' @examplesIf interactive()
#' mysterycall_nppes_gender(c("1710933130", "1033299938"))
#' @export
mysterycall_nppes_gender <- function(npi, verbose = FALSE) {
  checkmate::assert(
    checkmate::check_character(npi),
    checkmate::check_numeric(npi)
  )
  if (!requireNamespace("npi", quietly = TRUE)) {
    stop("Package 'npi' is required for mysterycall_nppes_gender(). ",
         "Install it with install.packages('npi').", call. = FALSE)
  }

  ids <- unique(as.character(npi))
  sex <- vapply(ids, .mc_nppes_sex_one, character(1L), USE.NAMES = FALSE)
  gender <- .mc_normalize_sex(sex)

  out <- tibble::tibble(
    npi           = ids,
    gender        = gender,
    gender_source = ifelse(is.na(gender), NA_character_, "NPPES")
  )
  if (verbose) {
    message(sprintf("NPPES gender: %d/%d resolved (%.0f%%)",
                    sum(!is.na(out$gender)), nrow(out),
                    100 * mean(!is.na(out$gender))))
  }
  out
}

#' Read one NPI's NPPES sex code
#'
#' @param npi A single NPI (character).
#' @return `"M"`, `"F"`, or `NA_character_`.
#' @family npi
#' @keywords internal
.mc_nppes_sex_one <- function(npi) {
  npi <- as.character(npi)
  if (is.na(npi) || nchar(npi) != 10L || grepl("\\D", npi)) return(NA_character_)
  res <- tryCatch(suppressMessages(npi::npi_search(number = npi)),
                  error = function(e) NULL)
  if (is.null(res)) return(NA_character_)
  fl <- tryCatch(suppressMessages(npi::npi_flatten(res, "basic")),
                 error = function(e) NULL)
  if (is.null(fl) || !"basic_sex" %in% names(fl) || !nrow(fl)) return(NA_character_)
  as.character(fl$basic_sex[[1L]])
}

#' Normalise assorted sex/gender codes to "Male"/"Female"
#'
#' Maps NPPES (`M`/`F`) and DAC (`M`/`F`/`Male`/`Female`) values -- in any case
#' -- to `"Male"`/`"Female"`; anything else (including blanks, `"U"`, unknown)
#' becomes `NA`.
#'
#' @param x Character vector of raw sex/gender codes.
#' @return Character vector of `"Male"` / `"Female"` / `NA`.
#' @family npi
#' @keywords internal
.mc_normalize_sex <- function(x) {
  x <- toupper(trimws(as.character(x)))
  dplyr::case_when(
    x %in% c("M", "MALE")   ~ "Male",
    x %in% c("F", "FEMALE") ~ "Female",
    TRUE ~ NA_character_
  )
}
