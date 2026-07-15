#' Classify physician practice setting from facility/organization name
#'
#' @name mysterycall_classify_practice_setting
NULL

# -- Built-in pattern lists ----------------------------------------------------

.mc_academic_patterns <- c(
  "university", "medical center", "med center", "medical college",
  "school of medicine", "teaching hospital", "academic",
  "children's hospital", "childrens hospital",
  "mayo clinic", "cleveland clinic", "johns hopkins",
  "memorial sloan", "md anderson", "duke", "stanford",
  "\\bucsf\\b", "\\bucla\\b", "\\busc\\b", "\\bnyu\\b", "columbia", "harvard",
  "yale", "\\bpenn\\b", "cornell", "\\bupmc\\b", "vanderbilt",
  "emory", "baylor", "ohio state", "michigan medicine",
  "northwestern", "mount sinai", "brigham", "jefferson",
  "health sciences center", "cancer center", "cancer ctr",
  "sch of med", "dept of oto", "infirmary", "health system",
  "henry ford", "\\buab\\b", "\\bsuny\\b", "oto dept"
)

.mc_government_patterns <- c(
  "\\bvamc\\b", "\\bva medical", "\\bva hospital", "veterans", "veteran affairs",
  "dod ", "department of defense", "military",
  "army", "navy", "air force", "walter reed",
  "tricare", "indian health", "ihs",
  "federal", "county health", "public health"
)

.mc_private_patterns <- c(
  "private practice", "associates", "group",
  "ear nose throat", "ent ", "otolaryngology",
  " md$", " md,", "pllc", "llc", "inc", "\\bpc\\b", "\\bpa\\b"
)


#' Classify a facility name as Academic, Government, or Private Practice
#'
#' Applies a three-tier keyword search to facility or organization names:
#' Government > Academic > Private Practice. Government is checked first so
#' that VA and military facilities are not mis-classified as Academic when
#' their name also contains "Medical Center" or a university name. If the
#' name matches no pattern but is non-empty, it defaults to
#' `"Private Practice"`. Missing or empty values return `na_label`.
#'
#' This is a pure-R, vectorized function with no package dependencies beyond
#' base R.
#'
#' @param facility_name Character vector of facility or organization names.
#' @param academic_patterns Character vector of lower-case substrings (or
#'   regex patterns) indicating academic affiliation. When `NULL` (default)
#'   the built-in list of 40+ patterns is used. Supply your own vector to
#'   override completely; use `c(mysterycall_academic_patterns(), "my term")`
#'   to extend.
#' @param government_patterns Character vector of lower-case patterns for
#'   government/military settings. `NULL` uses the built-in list.
#' @param na_label Character scalar returned for `NA` or blank input.
#'   Default `"Unknown"`.
#'
#' @return Character vector the same length as `facility_name` with values
#'   `"Academic"`, `"Government"`, `"Private Practice"`, or `na_label`.
#'
#' @seealso [mysterycall_assign_region()], [mysterycall_classify_medical_school()],
#'   [mysterycall_classify_ruca()],
#'   [mysterycall_academic_patterns()], [mysterycall_government_patterns()]
#'   for related provider characterization helpers.
#' @family provider characteristics
#' @export
#'
#' @examples
#' names <- c(
#'   "University of Colorado Medical Center",
#'   "VA Medical Center Denver",
#'   "Denver ENT Associates LLC",
#'   NA
#' )
#' mysterycall_classify_practice_setting(names)
mysterycall_classify_practice_setting <- function(facility_name,
                                                   academic_patterns    = NULL,
                                                   government_patterns  = NULL,
                                                   na_label             = "Unknown") {

  if (!is.character(facility_name)) {
    stop("`facility_name` must be a character vector.", call. = FALSE)
  }
  if (!is.character(na_label) || length(na_label) != 1L) {
    stop("`na_label` must be a single character string.", call. = FALSE)
  }

  ap <- if (is.null(academic_patterns))   .mc_academic_patterns   else academic_patterns
  gp <- if (is.null(government_patterns)) .mc_government_patterns else government_patterns

  .classify_one <- function(nm) {
    if (is.na(nm) || !nzchar(trimws(nm))) return(na_label)
    nm_lower <- tolower(nm)
    # Government checked first: VA/military facilities are government even when
    # they share a name with a medical center or university.
    if (any(vapply(gp, function(p) grepl(p, nm_lower, perl = TRUE), logical(1L)))) return("Government")
    if (any(vapply(ap, function(p) grepl(p, nm_lower, perl = TRUE), logical(1L)))) return("Academic")
    "Private Practice"
  }

  vapply(facility_name, .classify_one, character(1L), USE.NAMES = FALSE)
}


#' Return the built-in academic keyword patterns
#'
#' Convenience accessor so callers can extend rather than replace the default
#' list: `academic_patterns = c(mysterycall_academic_patterns(), "my term")`.
#'
#' @return Character vector of lower-case regex patterns used to identify
#'   academic medical centers and teaching hospitals.
#' @family provider characteristics
#' @seealso [mysterycall_classify_practice_setting()]
#' @export
#'
#' @examples
#' # View all built-in academic patterns
#' mysterycall_academic_patterns()
#'
#' # Extend with a custom term
#' my_patterns <- c(mysterycall_academic_patterns(), "regional medical center")
#' mysterycall_classify_practice_setting("Regional Medical Center", academic_patterns = my_patterns)
mysterycall_academic_patterns <- function() .mc_academic_patterns


#' Return the built-in government/military keyword patterns
#'
#' Convenience accessor so callers can extend rather than replace the default
#' government pattern list used by [mysterycall_classify_practice_setting()].
#'
#' @return Character vector of lower-case regex patterns used to identify
#'   VA, military, and other government-affiliated facilities.
#' @family provider characteristics
#' @seealso [mysterycall_classify_practice_setting()]
#' @export
#'
#' @examples
#' # View all built-in government patterns
#' mysterycall_government_patterns()
#'
#' # Extend with a custom term
#' my_gov <- c(mysterycall_government_patterns(), "state health dept")
#' mysterycall_classify_practice_setting("State Health Dept Clinic",
#'                                        government_patterns = my_gov)
mysterycall_government_patterns <- function() .mc_government_patterns
