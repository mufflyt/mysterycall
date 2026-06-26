#' Map US states to medical society districts and Census regions
#'
#' @name mysterycall_assign_region
NULL

# -- Internal lookup tables (built from regions.R and add_ent_demographics.R) --

# Source of truth: acog_districts dataset.
# Key corrections from prior version:
#   Delaware moved III -> IV; Wisconsin moved V -> VI;
#   Missouri moved VI -> VII; Texas moved VII -> XI (its own district).
.mc_acog_map <- c(
  "Connecticut" = "District I",   "Maine" = "District I",
  "Massachusetts" = "District I", "New Hampshire" = "District I",
  "Rhode Island" = "District I",  "Vermont" = "District I",
  "New York" = "District II",
  "New Jersey" = "District III",  "Pennsylvania" = "District III",
  "Delaware" = "District IV",     "District of Columbia" = "District IV",
  "Georgia" = "District IV",      "Maryland" = "District IV",
  "North Carolina" = "District IV","Puerto Rico" = "District IV",
  "South Carolina" = "District IV","Virginia" = "District IV",
  "West Virginia" = "District IV",
  "Indiana" = "District V",       "Kentucky" = "District V",
  "Michigan" = "District V",      "Ohio" = "District V",
  "Illinois" = "District VI",     "Iowa" = "District VI",
  "Minnesota" = "District VI",    "Nebraska" = "District VI",
  "North Dakota" = "District VI", "South Dakota" = "District VI",
  "Wisconsin" = "District VI",
  "Alabama" = "District VII",     "Arkansas" = "District VII",
  "Kansas" = "District VII",      "Louisiana" = "District VII",
  "Mississippi" = "District VII", "Missouri" = "District VII",
  "Oklahoma" = "District VII",    "Tennessee" = "District VII",
  "Alaska" = "District VIII",     "Arizona" = "District VIII",
  "Colorado" = "District VIII",   "Hawaii" = "District VIII",
  "Idaho" = "District VIII",      "Montana" = "District VIII",
  "Nevada" = "District VIII",     "New Mexico" = "District VIII",
  "Oregon" = "District VIII",     "Utah" = "District VIII",
  "Washington" = "District VIII", "Wyoming" = "District VIII",
  "California" = "District IX",
  "Texas" = "District XI",
  "Florida" = "District XII"
)

.mc_aao_hns_map <- c(
  # District 1  --  New England
  "Connecticut" = "District 1", "Maine" = "District 1",
  "Massachusetts" = "District 1", "New Hampshire" = "District 1",
  "Rhode Island" = "District 1", "Vermont" = "District 1",
  # District 2  --  Middle Atlantic
  "New Jersey" = "District 2", "New York" = "District 2",
  "Pennsylvania" = "District 2",
  # District 3  --  Mid-Atlantic/Southeast
  "Delaware" = "District 3",  "District of Columbia" = "District 3",
  "Maryland" = "District 3",  "North Carolina" = "District 3",
  "Virginia" = "District 3",  "West Virginia" = "District 3",
  # District 4  --  Southeast
  "Alabama" = "District 4",   "Florida" = "District 4",
  "Georgia" = "District 4",   "Kentucky" = "District 4",
  "Louisiana" = "District 4", "Mississippi" = "District 4",
  "South Carolina" = "District 4", "Tennessee" = "District 4",
  "Puerto Rico" = "District 4", "U.S. Virgin Islands" = "District 4",
  # District 5  --  Midwest
  "Illinois" = "District 5",  "Indiana" = "District 5",
  "Iowa" = "District 5",      "Michigan" = "District 5",
  "Minnesota" = "District 5", "Ohio" = "District 5",
  "Wisconsin" = "District 5",
  # District 6  --  Central
  "Arkansas" = "District 6",  "Kansas" = "District 6",
  "Missouri" = "District 6",  "Nebraska" = "District 6",
  "North Dakota" = "District 6", "Oklahoma" = "District 6",
  "South Dakota" = "District 6", "Texas" = "District 6",
  # District 7  --  Mountain/Southwest
  "Arizona" = "District 7",   "Colorado" = "District 7",
  "Montana" = "District 7",   "New Mexico" = "District 7",
  "Nevada" = "District 7",    "Utah" = "District 7",
  "Wyoming" = "District 7",
  # District 8  --  Pacific
  "Alaska" = "District 8",    "California" = "District 8",
  "Hawaii" = "District 8",    "Idaho" = "District 8",
  "Oregon" = "District 8",    "Washington" = "District 8",
  "Guam" = "District 8"
)

.mc_census_map <- c(
  # Northeast  --  New England
  "Connecticut" = "Northeast", "Maine" = "Northeast",
  "Massachusetts" = "Northeast", "New Hampshire" = "Northeast",
  "Rhode Island" = "Northeast", "Vermont" = "Northeast",
  # Northeast  --  Middle Atlantic
  "New Jersey" = "Northeast", "New York" = "Northeast",
  "Pennsylvania" = "Northeast",
  # Midwest  --  East North Central
  "Illinois" = "Midwest", "Indiana" = "Midwest",
  "Michigan" = "Midwest", "Ohio" = "Midwest",
  "Wisconsin" = "Midwest",
  # Midwest  --  West North Central
  "Iowa" = "Midwest",     "Kansas" = "Midwest",
  "Minnesota" = "Midwest","Missouri" = "Midwest",
  "Nebraska" = "Midwest", "North Dakota" = "Midwest",
  "South Dakota" = "Midwest",
  # South  --  South Atlantic
  "Delaware" = "South",  "District of Columbia" = "South",
  "Florida" = "South",   "Georgia" = "South",
  "Maryland" = "South",  "North Carolina" = "South",
  "South Carolina" = "South", "Virginia" = "South",
  "West Virginia" = "South",
  # South  --  East South Central
  "Alabama" = "South",     "Kentucky" = "South",
  "Mississippi" = "South", "Tennessee" = "South",
  # South  --  West South Central
  "Arkansas" = "South",  "Louisiana" = "South",
  "Oklahoma" = "South",  "Texas" = "South",
  # West  --  Mountain
  "Arizona" = "West",    "Colorado" = "West",
  "Idaho" = "West",      "Montana" = "West",
  "Nevada" = "West",     "New Mexico" = "West",
  "Utah" = "West",       "Wyoming" = "West",
  # West  --  Pacific
  "Alaska" = "West",     "California" = "West",
  "Hawaii" = "West",     "Oregon" = "West",
  "Washington" = "West"
)

# Two-letter state-code to full-name map for accepting abbreviations
.mc_state_abbr <- c(
  AK = "Alaska", AL = "Alabama", AR = "Arkansas", AZ = "Arizona",
  CA = "California", CO = "Colorado", CT = "Connecticut",
  DC = "District of Columbia", DE = "Delaware", FL = "Florida",
  GA = "Georgia", GU = "Guam", HI = "Hawaii", IA = "Iowa",
  ID = "Idaho", IL = "Illinois", IN = "Indiana", KS = "Kansas",
  KY = "Kentucky", LA = "Louisiana", MA = "Massachusetts",
  MD = "Maryland", ME = "Maine", MI = "Michigan", MN = "Minnesota",
  MO = "Missouri", MS = "Mississippi", MT = "Montana",
  NC = "North Carolina", ND = "North Dakota", NE = "Nebraska",
  NH = "New Hampshire", NJ = "New Jersey", NM = "New Mexico",
  NV = "Nevada", NY = "New York", OH = "Ohio", OK = "Oklahoma",
  OR = "Oregon", PA = "Pennsylvania", PR = "Puerto Rico",
  RI = "Rhode Island", SC = "South Carolina", SD = "South Dakota",
  TN = "Tennessee", TX = "Texas", UT = "Utah", VA = "Virginia",
  VI = "U.S. Virgin Islands", VT = "Vermont", WA = "Washington",
  WI = "Wisconsin", WV = "West Virginia", WY = "Wyoming"
)


#' Map US states to ACOG, AAO-HNS, or Census regions
#'
#' Accepts state names (full or two-letter abbreviations, case-insensitive)
#' and returns the corresponding medical society district or Census region.
#' Three classification systems are supported:
#'
#' * **`"acog"`**  --  ACOG Districts I-XII (obstetrics/gynecology)
#' * **`"aao_hns"`**  --  AAO-HNS Districts 1-8 (otolaryngology)
#' * **`"census"`**  --  US Census Bureau regions: Northeast, Midwest, South, West
#'
#' @param state Character vector of US state names or two-letter abbreviations.
#'   Mixed formats are accepted (e.g. `c("CO", "Texas", "new york")`).
#' @param system Character scalar specifying the classification system.
#'   One of `"acog"` (default), `"aao_hns"`, or `"census"`.
#' @param na_label Character scalar returned for unrecognized or `NA` inputs.
#'   Default `"Unknown"`.
#'
#' @return Character vector the same length as `state`.
#'
#' @seealso [mysterycall_classify_practice_setting()],
#'   [mysterycall_classify_medical_school()], [mysterycall_classify_ruca()]
#'   for other provider demographic classifications.
#' @family provider characteristics
#' @export
#'
#' @examples
#' states <- c("CO", "Texas", "New York", "california", NA)
#'
#' mysterycall_assign_region(states, system = "acog")
#' mysterycall_assign_region(states, system = "aao_hns")
#' mysterycall_assign_region(states, system = "census")
mysterycall_assign_region <- function(state,
                                       system   = c("acog", "aao_hns", "census"),
                                       na_label = "Unknown") {

  system <- match.arg(system)
  if (is.factor(state)) {
    state <- as.character(state)
  } else if (!is.character(state)) {
    stop("`state` must be a character vector or factor.", call. = FALSE)
  }
  if (!is.character(na_label) || length(na_label) != 1L) {
    stop("`na_label` must be a single character string.", call. = FALSE)
  }

  lookup <- switch(system,
    acog    = .mc_acog_map,
    aao_hns = .mc_aao_hns_map,
    census  = .mc_census_map
  )

  # Normalize each element: expand 2-letter codes; title-case full names
  .normalize <- function(s) {
    if (is.na(s)) return(NA_character_)
    s <- trimws(s)
    if (nchar(s) == 2L) {
      key <- toupper(s)
      return(if (key %in% names(.mc_state_abbr)) .mc_state_abbr[[key]] else s)
    }
    # Title-case the full name for consistent key matching
    .title_case(s)
  }

  normalized <- vapply(state, .normalize, character(1L), USE.NAMES = FALSE)
  result     <- lookup[normalized]
  result[is.na(result)] <- na_label
  unname(result)
}

#' Convert a string to title case while preserving small words
#'
#' Internal helper to normalize state names for lookup matching.
#'
#' @param s Character scalar.
#'
#' @return Character scalar in title case.
#' @family utilities
#' @keywords internal
.title_case <- function(s) {
  # Prepositions/conjunctions kept lowercase so "District of Columbia" matches
  # the lookup table key exactly.
  small_words <- c("of", "the", "and", "in", "at", "by", "for", "to", "or")
  words <- strsplit(s, " ", fixed = TRUE)[[1L]]
  out <- vapply(seq_along(words), function(i) {
    w <- words[[i]]
    if (!nzchar(w)) return(w)
    if (i > 1L && tolower(w) %in% small_words) return(tolower(w))
    paste0(toupper(substr(w, 1L, 1L)), tolower(substr(w, 2L, nchar(w))))
  }, character(1L))
  paste(out, collapse = " ")
}
