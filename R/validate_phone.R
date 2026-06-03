#' Validate North-American phone numbers
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name phone_validation
NULL

# Mutable environment for session-level caching; <<- into a locked namespace
# binding fails when the package is installed, so we store state here instead.
.nanp_cache_env <- new.env(parent = emptyenv())
.nanp_cache_env$lookup <- NULL
.nanp_cache_env$path   <- NULL

#' Load NANP Area Code Lookup Table
#'
#' Loads and caches the mapping between US area codes and states.
#'
#' @param nanp_path Optional path to custom NANP CSV.
#'
#' @return Data frame with `area_code` and `state` columns.
#' @family validation
#' @keywords internal
.load_nanp_lookup <- function(nanp_path = NULL) {
  path <- if (!is.null(nanp_path)) {
    nanp_path
  } else {
    system.file("extdata", "nanp_area_codes_us.csv", package = "mysterycall")
  }
  # Return cached table only when it was loaded from the same path.
  if (!is.null(.nanp_cache_env$lookup) &&
      identical(.nanp_cache_env$path, path)) {
    return(invisible(.nanp_cache_env$lookup))
  }
  if (!nzchar(path) || !file.exists(path)) {
    stop(
      "NANP area-code lookup not found. Supply `nanp_path` or reinstall the package.",
      call. = FALSE
    )
  }
  tbl <- utils::read.csv(path, stringsAsFactors = FALSE)
  tbl$area_code <- sprintf("%03d", as.integer(tbl$area_code))
  .nanp_cache_env$lookup <- tbl
  .nanp_cache_env$path   <- path
  invisible(tbl)
}

#' Validate North-American (NANP) phone number strings
#'
#' Strips non-digit characters, applies North American Numbering Plan (NANP)
#' syntactic rules, looks up each area code's home state, and optionally
#' checks whether that state matches the physician's practice state.
#'
#' Syntactic validity rules applied:
#' \itemize{
#'   \item Exactly 10 digits after stripping non-digits (an optional leading
#'         `"1"` country code is dropped first).
#'   \item NPA first digit (N) is 2-9.
#'   \item NXX first digit (N) is 2-9.
#'   \item NXX is not an N11 code (e.g. 911, 411, 211).
#' }
#'
#' Area-code-to-state mapping is loaded from the bundled
#' `inst/extdata/nanp_area_codes_us.csv` file.  Pass `nanp_path` to override
#' with a custom CSV that has columns `area_code` (integer) and `state`
#' (2-letter US postal abbreviation).
#'
#' @param phone_str Character vector of phone strings (NAs allowed).
#'   Accepts common formats: `"(NPA) NXX-XXXX"`, `"NPA-NXX-XXXX"`,
#'   bare 10 digits, or `"1NPANXXXXXX"`.
#' @param practice_state Character vector of 2-letter US state postal codes,
#'   the same length as `phone_str` or length 1 (recycled).  Pass `NULL` to
#'   skip the state-matching check (all `phone_area_code_matches_state` entries
#'   will be `NA`).
#' @param nanp_path Optional path to a custom NANP lookup CSV.  When `NULL`
#'   (default) the bundled `inst/extdata/nanp_area_codes_us.csv` is used.
#'
#' @return A data frame with one row per element of `phone_str` and columns:
#'   \describe{
#'     \item{`phone_e164_valid`}{Logical. `TRUE` if the number passes all NANP
#'       syntactic rules.}
#'     \item{`phone_npa`}{Character. The 3-digit North American Numbering Plan
#'       area code, or `NA_character_` when the number is syntactically
#'       invalid.}
#'     \item{`phone_state_from_npa`}{Character. The 2-letter US postal
#'       abbreviation for the area code's registered state, or `NA_character_`
#'       when the area code is absent from the bundled lookup table.}
#'     \item{`phone_area_code_matches_state`}{Logical. `TRUE` when
#'       `phone_state_from_npa` exactly matches `practice_state`; `FALSE` when
#'       they differ; `NA` when `practice_state` is `NULL`.}
#'     \item{`phone_validity_flag`}{Character. One of `"valid"`,
#'       `"missing"`, `"invalid_format"`, `"unknown_area_code"`, or
#'       `"area_code_state_mismatch"`.}
#'   }
#'
#' @section Data format:
#'   ```r
#'   mysterycall_validate_phone(
#'     c("(303) 555-1212", "555-1212", NA, "800-555-0199"),
#'     practice_state = "CO"
#'   )
#'   ```
#'
#' @seealso [mysterycall_parse_physician_name()] to structure name strings;
#'   [mysterycall_validate_parsed_names()] for name-level quality checks;
#'   [mysterycall_safe_left_join()] to attach validated phone data to a roster.
#' @family data quality
#' @export
#'
#' @examples
#' mysterycall_validate_phone(
#'   c("(303) 555-1212", "555-1212", NA),
#'   practice_state = "CO"
#' )
#'
#' # Without state matching
#' mysterycall_validate_phone(c("2125551234", "0005551234"), practice_state = NULL)
mysterycall_validate_phone <- function(phone_str,
                                       practice_state = NULL,
                                       nanp_path      = NULL) {
  if (!is.character(phone_str)) {
    stop("`phone_str` must be a character vector.", call. = FALSE)
  }
  n <- length(phone_str)

  if (!is.null(practice_state)) {
    if (!is.character(practice_state)) {
      stop("`practice_state` must be a character vector or NULL.", call. = FALSE)
    }
    if (length(practice_state) == 1L && n > 1L) {
      practice_state <- rep(practice_state, n)
    }
    if (length(practice_state) != n) {
      stop("`practice_state` must be the same length as `phone_str`, or length 1.",
           call. = FALSE)
    }
  }

  lookup <- .load_nanp_lookup(nanp_path)

  # Strip to digits; drop optional leading country code "1"
  digits <- gsub("[^0-9]", "", phone_str)
  digits <- ifelse(
    !is.na(digits) & nchar(digits) == 11L & substr(digits, 1L, 1L) == "1",
    substr(digits, 2L, 11L),
    digits
  )

  ten_digit <- !is.na(digits) & nchar(digits) == 10L
  npa       <- ifelse(ten_digit, substr(digits, 1L, 3L), NA_character_)
  nxx       <- ifelse(ten_digit, substr(digits, 4L, 6L), NA_character_)

  # NANP syntactic rules
  npa_valid <- !is.na(npa) & substr(npa, 1L, 1L) %in% as.character(2:9)
  nxx_valid <- !is.na(nxx) &
    substr(nxx, 1L, 1L) %in% as.character(2:9) &
    !(substr(nxx, 2L, 2L) == "1" & substr(nxx, 3L, 3L) == "1")
  syntax_valid <- ten_digit & npa_valid & nxx_valid

  # Area-code to state lookup - named vector preserves input order exactly
  # and handles NA/duplicate NPA without any dependence on merge() row ordering.
  lookup_vec           <- stats::setNames(lookup$state, lookup$area_code)
  phone_state_from_npa <- lookup_vec[npa]          # NA npa -> NA state (correct)
  names(phone_state_from_npa) <- NULL

  # State-match flag
  state_match <- if (is.null(practice_state)) {
    rep(NA, n)
  } else {
    !is.na(phone_state_from_npa) & !is.na(practice_state) &
      phone_state_from_npa == practice_state
  }

  # Validity flag: unknown area codes and state mismatches are not valid
  missing_phone <- is.na(phone_str) | !nzchar(trimws(phone_str))
  validity_flag <- ifelse(
    missing_phone,                            "missing",
    ifelse(!syntax_valid,                     "invalid_format",
    ifelse(is.na(phone_state_from_npa),       "unknown_area_code",
    ifelse(!is.na(state_match) & !state_match, "area_code_state_mismatch",
                                              "valid")))
  )

  # phone_e164_valid is TRUE only for fully valid numbers: correct syntax,
  # known area code, and area code matches practice_state (when provided).
  phone_e164_valid <- validity_flag == "valid"

  data.frame(
    phone_e164_valid              = phone_e164_valid,
    phone_npa                     = npa,
    phone_state_from_npa          = phone_state_from_npa,
    phone_area_code_matches_state = state_match,
    phone_validity_flag           = validity_flag,
    stringsAsFactors              = FALSE,
    row.names                     = NULL
  )
}
