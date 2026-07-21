#' USPS Address Normalization Utilities
#'
#' Functions for normalizing US postal addresses to USPS format. Handles
#' directional prefixes/suffixes, street suffixes, unit designators, state
#' abbreviations, and ZIP codes for consistent address matching across datasets.
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name address_normalizer
NULL

# Internal lookup tables -------------------------------------------------------

.dir_map <- c(
  "NORTH" = "N", "SOUTH" = "S", "EAST" = "E", "WEST" = "W",
  "NORTHEAST" = "NE", "NORTHWEST" = "NW", "SOUTHEAST" = "SE", "SOUTHWEST" = "SW"
)

.dir_alias <- c(
  "N\\." = "N", "S\\." = "S", "E\\." = "E", "W\\." = "W",
  "NE\\." = "NE", "NW\\." = "NW", "SE\\." = "SE", "SW\\." = "SW"
)

.suffix_map <- c(
  "STREET" = "ST", "ST" = "ST",
  "AVENUE" = "AVE", "AVE" = "AVE",
  "ROAD" = "RD", "RD" = "RD",
  "HIGHWAY" = "HWY", "HWY" = "HWY", "ROUTE" = "RTE", "RTE" = "RTE",
  "PARKWAY" = "PKWY", "PKWY" = "PKWY",
  "BOULEVARD" = "BLVD", "BLVD" = "BLVD",
  "DRIVE" = "DR", "DR" = "DR",
  "LANE" = "LN", "LN" = "LN",
  "COURT" = "CT", "CT" = "CT",
  "TERRACE" = "TER", "TER" = "TER",
  "PLACE" = "PL", "PL" = "PL",
  "WAY" = "WAY",
  "CIRCLE" = "CIR", "CIR" = "CIR",
  "LOOP" = "LOOP",
  "EXPRESSWAY" = "EXPY", "EXPY" = "EXPY",
  "FREEWAY" = "FWY", "FWY" = "FWY",
  "TURNPIKE" = "TPKE", "TPKE" = "TPKE",
  "TRAIL" = "TRL", "TRL" = "TRL",
  "CROSSING" = "XING", "XING" = "XING"
)

.unit_map <- c(
  "SUITE" = "STE", "STE" = "STE",
  "APARTMENT" = "APT", "APT" = "APT",
  "UNIT" = "UNIT",
  "FLOOR" = "FL", "FL" = "FL",
  "ROOM" = "RM", "RM" = "RM",
  "BUILDING" = "BLDG", "BLDG" = "BLDG"
)

.state_map <- c(
  "ALABAMA" = "AL", "ALASKA" = "AK", "ARIZONA" = "AZ", "ARKANSAS" = "AR",
  "CALIFORNIA" = "CA", "COLORADO" = "CO", "CONNECTICUT" = "CT", "DELAWARE" = "DE",
  "DISTRICT OF COLUMBIA" = "DC", "FLORIDA" = "FL", "GEORGIA" = "GA", "HAWAII" = "HI",
  "IDAHO" = "ID", "ILLINOIS" = "IL", "INDIANA" = "IN", "IOWA" = "IA", "KANSAS" = "KS",
  "KENTUCKY" = "KY", "LOUISIANA" = "LA", "MAINE" = "ME", "MARYLAND" = "MD",
  "MASSACHUSETTS" = "MA", "MICHIGAN" = "MI", "MINNESOTA" = "MN", "MISSISSIPPI" = "MS",
  "MISSOURI" = "MO", "MONTANA" = "MT", "NEBRASKA" = "NE", "NEVADA" = "NV",
  "NEW HAMPSHIRE" = "NH", "NEW JERSEY" = "NJ", "NEW MEXICO" = "NM", "NEW YORK" = "NY",
  "NORTH CAROLINA" = "NC", "NORTH DAKOTA" = "ND", "OHIO" = "OH", "OKLAHOMA" = "OK",
  "OREGON" = "OR", "PENNSYLVANIA" = "PA", "RHODE ISLAND" = "RI", "SOUTH CAROLINA" = "SC",
  "SOUTH DAKOTA" = "SD", "TENNESSEE" = "TN", "TEXAS" = "TX", "UTAH" = "UT",
  "VERMONT" = "VT", "VIRGINIA" = "VA", "WASHINGTON" = "WA", "WEST VIRGINIA" = "WV",
  "WISCONSIN" = "WI", "WYOMING" = "WY",
  "PUERTO RICO" = "PR", "VIRGIN ISLANDS" = "VI", "GUAM" = "GU",
  "AMERICAN SAMOA" = "AS", "NORTHERN MARIANA ISLANDS" = "MP"
)

# Exported functions -----------------------------------------------------------

#' Normalize ASCII Characters and Whitespace
#'
#' Converts non-ASCII characters to spaces and collapses multiple whitespace
#' characters into single spaces. This is the first step in address
#' normalization to ensure consistent character encoding.
#'
#' @param x Character vector of strings to normalize.
#'
#' @return Character vector with non-ASCII characters replaced by spaces and
#'   all whitespace collapsed to single spaces.
#'
#' @examples
#' mysterycall:::mysterycall_ascii_norm("123 Main St Suite 100")
#' mysterycall:::mysterycall_ascii_norm("456   Oak    Avenue")
#'
#' @importFrom stringr str_replace_all str_squish
#' @family address-normalization
#' @keywords internal
mysterycall_ascii_norm <- function(x) {
  x |>
    stringr::str_replace_all("[^\\x20-\\x7E]", " ") |>
    stringr::str_squish()
}

#' Deprecated version of mysterycall_ascii_norm
#' @param ... Arguments passed to mysterycall_ascii_norm
#' @return See mysterycall_ascii_norm
#' @keywords internal
#' @name ascii_norm
ascii_norm <- function(...) { .Deprecated("mysterycall_ascii_norm"); mysterycall_ascii_norm(...) }

#' Convert to Canonical Uppercase
#'
#' Normalizes ASCII characters and converts the result to uppercase  --  the
#' standard format for USPS address comparison.
#'
#' @param x Character vector of strings to convert.
#'
#' @return Character vector in uppercase with normalized ASCII and whitespace.
#'
#' @examples
#' mysterycall:::mysterycall_caps("123 main street")
#' mysterycall:::mysterycall_caps("456 oak ave #100")
#'
#' @family address-normalization
#' @keywords internal
mysterycall_caps <- function(x) toupper(mysterycall_ascii_norm(x))

#' Deprecated version of mysterycall_caps
#' @param ... Arguments passed to mysterycall_caps
#' @return See mysterycall_caps
#' @keywords internal
#' @name caps
caps <- function(...) { .Deprecated("mysterycall_caps"); mysterycall_caps(...) }

#' Map Token Replacements Using Word Boundaries
#'
#' Performs word-level replacements using a named character vector as a lookup
#' map. Replacements are made at word boundaries to avoid partial matches.
#'
#' @param x Character vector of strings to process.
#' @param map Named character vector where names are patterns to match and
#'   values are replacement strings.
#'
#' @return Character vector with all matching tokens replaced.
#'
#' @examplesIf FALSE
#' dir_map <- c("NORTH" = "N", "SOUTH" = "S")
#' map_token("123 NORTH MAIN STREET", dir_map)
#'
#' @importFrom stringr str_replace_all
#' @family address-normalization
#' @keywords internal
map_token <- function(x, map) {
  stringr::str_replace_all(x, setNames(map, names(map)))
}

#' Detect PO Box Addresses
#'
#' Checks if an address string represents a Post Office Box. Detects common
#' variations including "PO BOX", "P O BOX", and "POST OFFICE BOX".
#'
#' @param x Character vector of address strings to check.
#'
#' @return Logical vector indicating whether each address is a PO Box.
#'
#' @examples
#' mysterycall:::mysterycall_is_po_box("PO Box 12345")
#' mysterycall:::mysterycall_is_po_box("123 Main Street")
#'
#' @importFrom stringr str_detect
#' @family address-normalization
#' @keywords internal
mysterycall_is_po_box <- function(x) {
  y <- toupper(mysterycall_ascii_norm(x))
  stringr::str_detect(y, "\\bP\\s*O\\s*BOX\\b|\\bPO\\s*BOX\\b|\\bPOST\\s*OFFICE\\s*BOX\\b")
}

#' Deprecated version of mysterycall_is_po_box
#' @param ... Arguments passed to mysterycall_is_po_box
#' @return See mysterycall_is_po_box
#' @keywords internal
#' @name is_po_box
is_po_box <- function(...) { .Deprecated("mysterycall_is_po_box"); mysterycall_is_po_box(...) }

#' Detect Addresses with Street Numbers
#'
#' Checks if an address string begins with a numeric street number.
#'
#' @param x Character vector of address strings to check.
#'
#' @return Logical vector indicating whether each address starts with a number.
#'
#' @examples
#' mysterycall:::mysterycall_has_street_number("123 Main Street")
#' mysterycall:::mysterycall_has_street_number("University Medical Center")
#'
#' @importFrom stringr str_detect
#' @family address-normalization
#' @keywords internal
mysterycall_has_street_number <- function(x) {
  y <- mysterycall_ascii_norm(x)
  stringr::str_detect(y, "^\\s*\\d+\\b")
}

#' Deprecated version of mysterycall_has_street_number
#' @param ... Arguments passed to mysterycall_has_street_number
#' @return See mysterycall_has_street_number
#' @keywords internal
#' @name has_street_number
has_street_number <- function(...) { .Deprecated("mysterycall_has_street_number"); mysterycall_has_street_number(...) }

#' Normalize State Names to USPS Codes
#'
#' Converts full state names to their two-letter USPS codes. If the input is
#' already a valid two-letter code, it is returned unchanged.
#'
#' @param state Character vector of state names or abbreviations.
#'
#' @return Character vector of two-letter USPS state codes.
#'
#' @examples
#' mysterycall:::mysterycall_normalize_state("California")
#' mysterycall:::mysterycall_normalize_state("NY")
#'
#' @importFrom stringr str_detect
#' @importFrom dplyr if_else
#' @family address-normalization
#' @keywords internal
mysterycall_normalize_state <- function(state) {
  s <- mysterycall_caps(state)
  dplyr::if_else(stringr::str_detect(s, "^[A-Z]{2}$"), s, map_token(s, .state_map))
}

#' Deprecated version of mysterycall_normalize_state
#' @param ... Arguments passed to mysterycall_normalize_state
#' @return See mysterycall_normalize_state
#' @keywords internal
#' @name normalize_state
normalize_state <- function(...) { .Deprecated("mysterycall_normalize_state"); mysterycall_normalize_state(...) }

#' Normalize Directional Prefixes and Suffixes
#'
#' Converts full directional words (NORTH, SOUTH, EAST, WEST) and compound
#' directions (NORTHEAST, etc.) to USPS abbreviations (N, S, E, W, NE, etc.).
#'
#' @param addr Character vector of address strings to normalize.
#'
#' @return Character vector with directionals converted to USPS abbreviations.
#'
#' @examples
#' mysterycall:::mysterycall_normalize_directionals("123 North Main Street")
#' mysterycall:::mysterycall_normalize_directionals("456 Southeast Oak Avenue")
#'
#' @importFrom stringr str_replace_all
#' @family address-normalization
#' @keywords internal
mysterycall_normalize_directionals <- function(addr) {
  a <- mysterycall_caps(addr)
  a <- stringr::str_replace_all(a, .dir_alias)
  for (k in names(.dir_map)) {
    a <- stringr::str_replace_all(a, paste0("\\b", k, "\\b"), .dir_map[[k]])
  }
  a
}

#' Deprecated version of mysterycall_normalize_directionals
#' @param ... Arguments passed to mysterycall_normalize_directionals
#' @return See mysterycall_normalize_directionals
#' @keywords internal
#' @name normalize_directionals
normalize_directionals <- function(...) { .Deprecated("mysterycall_normalize_directionals"); mysterycall_normalize_directionals(...) }

#' Normalize Street Suffixes
#'
#' Converts full street suffix names (STREET, AVENUE, ROAD, etc.) to their
#' USPS abbreviations (ST, AVE, RD, etc.).
#'
#' @param addr Character vector of address strings to normalize.
#'
#' @return Character vector with street suffixes converted to USPS abbreviations.
#'
#' @examples
#' mysterycall:::mysterycall_normalize_suffix("123 Main Street")
#' mysterycall:::mysterycall_normalize_suffix("456 Oak Boulevard Suite 100")
#'
#' @importFrom stringr str_replace_all
#' @family address-normalization
#' @keywords internal
mysterycall_normalize_suffix <- function(addr) {
  a <- mysterycall_caps(addr)
  for (k in names(.suffix_map)) {
    a <- stringr::str_replace_all(a, paste0("\\b", k, "\\b"), .suffix_map[[k]])
  }
  a
}

#' Deprecated version of mysterycall_normalize_suffix
#' @param ... Arguments passed to mysterycall_normalize_suffix
#' @return See mysterycall_normalize_suffix
#' @keywords internal
#' @name normalize_suffix
normalize_suffix <- function(...) { .Deprecated("mysterycall_normalize_suffix"); mysterycall_normalize_suffix(...) }

#' Normalize Unit Designators
#'
#' Standardizes unit designators (SUITE, APT, UNIT, FLOOR, ROOM) to USPS
#' abbreviations. Handles both inline units in address line 1 and separate
#' units in address line 2.
#'
#' @param addr1 Character scalar for the primary address line.
#' @param addr2 Character scalar for the secondary address line (optional).
#'   Default is `NA_character_`.
#'
#' @return A named list with two character elements:
#'   \describe{
#'     \item{`addr1`}{Character. Primary address with unit designators
#'       standardized to USPS abbreviations (STE, APT, UNIT, FL, RM).}
#'     \item{`addr2`}{Character or `NA_character_`. Normalized secondary
#'       address line; `NA_character_` when `addr2` was `NA_character_`.}
#'   }
#'
#' @examples
#' mysterycall:::mysterycall_normalize_units("123 Main St Suite 100", NA_character_)
#' mysterycall:::mysterycall_normalize_units("456 Oak Avenue", "Apartment 4B")
#'
#' @importFrom stringr str_replace_all
#' @family address-normalization
#' @keywords internal
mysterycall_normalize_units <- function(addr1, addr2 = NA_character_) {
  a1 <- mysterycall_caps(addr1)
  a2 <- if (is.na(addr2)) NA_character_ else mysterycall_caps(addr2)
  a1 <- stringr::str_replace_all(a1, "\\bSUITE\\s*#?\\s*(\\w+)\\b", "STE \\1")
  a1 <- stringr::str_replace_all(a1, "\\bAPT\\.?\\s*#?\\s*(\\w+)\\b", "APT \\1")
  a1 <- stringr::str_replace_all(a1, "\\bUNIT\\s*#?\\s*(\\w+)\\b", "UNIT \\1")
  a1 <- stringr::str_replace_all(a1, "\\bFLOOR\\s*(\\w+)\\b", "FL \\1")
  a1 <- stringr::str_replace_all(a1, "\\bROOM\\s*(\\w+)\\b", "RM \\1")
  a1 <- stringr::str_replace_all(a1, "\\s+#\\s*(\\w+)\\b", " #\\1")
  if (!is.na(a2)) {
    a2 <- map_token(a2, .unit_map)
    a2 <- stringr::str_replace_all(a2, "\\s+#\\s*(\\w+)\\b", " #\\1")
  }
  list(addr1 = a1, addr2 = a2)
}

#' Deprecated version of mysterycall_normalize_units
#' @param ... Arguments passed to mysterycall_normalize_units
#' @return See mysterycall_normalize_units
#' @keywords internal
#' @name normalize_units
normalize_units <- function(...) { .Deprecated("mysterycall_normalize_units"); mysterycall_normalize_units(...) }

#' Extract 5-Digit ZIP Code
#'
#' Extracts the first 5 digits from a ZIP code string, handling ZIP+4 formats
#' and various input types.
#'
#' @param zip Character or numeric vector of ZIP code strings.
#'
#' @return Character vector of 5-digit ZIP codes, or `NA_character_` for
#'   inputs that contain no 5-digit sequence. Length-0 input returns
#'   `character(0)`.
#'
#' @examples
#' mysterycall:::mysterycall_normalize_zip5("80111-1234")
#' mysterycall:::mysterycall_normalize_zip5(90210)
#'
#' @importFrom stringr str_extract
#' @family address-normalization
#' @seealso [mysterycall_clean_zip()] and [mysterycall_extract_zip5()] for the
#'   general-purpose ZIP cleaners outside the address-normalization pipeline.
#' @keywords internal
mysterycall_normalize_zip5 <- function(zip) {
  if (is.null(zip)) return(NA_character_)
  if (length(zip) == 0L) return(character(0))
  # A numeric ZIP with a leading zero (e.g. 7001 for "07001") has only four
  # digits, so a bare "\\d{5}" extraction returns NA and blanks the ZIP for all
  # of CT/MA/ME/NH/NJ/RI/VT/PR/VI. Left-pad numerics to 5 digits first.
  if (is.numeric(zip)) {
    raw <- ifelse(is.na(zip), NA_character_, sprintf("%05.0f", zip))
  } else {
    raw <- as.character(zip)
  }
  z <- stringr::str_extract(raw, "\\d{5}")
  ifelse(is.na(z), NA_character_, z)
}

#' Deprecated version of mysterycall_normalize_zip5
#' @param ... Arguments passed to mysterycall_normalize_zip5
#' @return See mysterycall_normalize_zip5
#' @keywords internal
#' @name normalize_zip5
normalize_zip5 <- function(...) { .Deprecated("mysterycall_normalize_zip5"); mysterycall_normalize_zip5(...) }

#' Remove Unit Designators from Address
#'
#' Strips suite, apartment, unit, floor, room, and hash-prefixed unit numbers
#' from an address string. Useful for creating a base street address for
#' matching.
#'
#' @param addr Character vector of address strings.
#'
#' @return Character vector with unit designators removed and whitespace cleaned.
#'
#' @examples
#' mysterycall:::mysterycall_strip_suite("123 Main St Suite 100")
#' mysterycall:::mysterycall_strip_suite("456 Oak Ave APT 4B #200")
#'
#' @importFrom stringr str_replace_all str_squish
#' @family address-normalization
#' @keywords internal
mysterycall_strip_suite <- function(addr) {
  a <- mysterycall_caps(addr)
  a <- stringr::str_replace_all(a, "\\b(STE|SUITE|APT|UNIT|FL|RM|#)\\s*\\w+\\b", "")
  stringr::str_squish(a)
}

#' Deprecated version of mysterycall_strip_suite
#' @param ... Arguments passed to mysterycall_strip_suite
#' @return See mysterycall_strip_suite
#' @keywords internal
#' @name strip_suite
strip_suite <- function(...) { .Deprecated("mysterycall_strip_suite"); mysterycall_strip_suite(...) }

#' Normalize All Address Fields in a Data Frame
#'
#' Applies comprehensive USPS normalization to all address fields in a data
#' frame: ASCII normalization, directional standardization, suffix
#' standardization, unit normalization, state code conversion, and ZIP
#' extraction.
#'
#' @param df Data frame containing address columns.
#' @param addr1_col Character name of the primary address column.
#'   Default: `"practice_address1"`.
#' @param addr2_col Character name of the secondary address column.
#'   Default: `"practice_address2"`.
#' @param city_col Character name of the city column.
#'   Default: `"practice_city"`.
#' @param state_col Character name of the state column.
#'   Default: `"practice_state"`.
#' @param zip_col Character name of the ZIP code column.
#'   Default: `"practice_zip"`.
#'
#' @return The input data frame with the original address columns normalized
#'   in-place plus five new derived columns:
#'   \describe{
#'     \item{`address1_norm`}{Character. Fully normalized primary address
#'       (ASCII, directionals, suffixes, and units standardized).}
#'     \item{`address2_norm`}{Character or `NA_character_`. Normalized
#'       secondary address.}
#'     \item{`address1_no_unit`}{Character. Primary address with all unit
#'       designators stripped.}
#'     \item{`is_po_box`}{Logical. `TRUE` if the address matches a PO Box
#'       pattern.}
#'     \item{`has_num`}{Logical. `TRUE` if the address begins with a street
#'       number.}
#'   }
#'
#' @examples
#' df <- data.frame(
#'   practice_address1 = c("123 North Main Street Suite 100", "456 Oak Avenue"),
#'   practice_address2 = c(NA, "Apartment 4B"),
#'   practice_city     = c("Denver", "Los Angeles"),
#'   practice_state    = c("Colorado", "CA"),
#'   practice_zip      = c("80111-1234", "90210"),
#'   stringsAsFactors  = FALSE
#' )
#' mysterycall:::mysterycall_normalize_address_df(df)
#'
#' @importFrom dplyr mutate across all_of
#' @family address-normalization
#' @export
mysterycall_normalize_address_df <- function(df,
                                 addr1_col = "practice_address1",
                                 addr2_col = "practice_address2",
                                 city_col  = "practice_city",
                                 state_col = "practice_state",
                                 zip_col   = "practice_zip") {
  req  <- c(addr1_col, city_col, state_col, zip_col)
  miss <- setdiff(req, names(df))
  if (length(miss)) stop(paste("Missing columns:", paste(miss, collapse = ", ")))

  addr2_present <- addr2_col %in% names(df)

  df <- dplyr::mutate(
    df,
    !!addr1_col := mysterycall_ascii_norm(.data[[addr1_col]]),
    !!city_col  := mysterycall_caps(.data[[city_col]]),
    !!state_col := mysterycall_normalize_state(.data[[state_col]]),
    !!zip_col   := mysterycall_normalize_zip5(.data[[zip_col]])
  )
  if (addr2_present) {
    df <- dplyr::mutate(df, !!addr2_col := mysterycall_ascii_norm(.data[[addr2_col]]))
  }

  df <- dplyr::mutate(df,
    addr1_dir = mysterycall_normalize_directionals(.data[[addr1_col]]),
    addr1_suf = mysterycall_normalize_suffix(addr1_dir)
  )
  df <- dplyr::rowwise(df)
  df <- dplyr::mutate(df,
    tmp_units = list(mysterycall_normalize_units(
      addr1_suf,
      if (addr2_present) .data[[addr2_col]] else NA_character_
    ))
  )
  df <- dplyr::ungroup(df)
  if (!requireNamespace("tidyr", quietly = TRUE)) {
    stop("Package 'tidyr' is required for mysterycall_normalize_address_df()", call. = FALSE)
  }
  df <- tidyr::unnest_wider(df, tmp_units, names_sep = "_")
  df <- dplyr::mutate(df,
    address1_norm    = tmp_units_addr1,
    address2_norm    = tmp_units_addr2,
    address1_no_unit = mysterycall_strip_suite(address1_norm),
    is_po_box        = mysterycall_is_po_box(.data[[addr1_col]]),
    has_num          = mysterycall_has_street_number(.data[[addr1_col]])
  )
  dplyr::select(df, -addr1_dir, -addr1_suf, -tmp_units_addr1, -tmp_units_addr2)
}
