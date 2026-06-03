#' Specialty parsing and physician name extraction utilities
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @name specialty_utils
NULL

# -- ABOHNS certification-type patterns ----------------------------------------

.mc_cert_patterns <- list(
  "Otology/Neurotology"         = "neurotology",
  "Pediatric Otolaryngology"    = "pediatric",
  "Sleep Medicine"              = "sleep",
  "Facial Plastic Surgery"      = "facial plastic"
)

#' Map an ABOHNS certification_type string to a subspecialty label
#'
#' Parses the ABOHNS `certification_type` field (e.g. `"Otolaryngology -
#' Head & Neck Surgery + Neurotology + Sleep Medicine"`) and returns the
#' most-specific subspecialty label. Priority order: Neurotology >
#' Pediatric Otolaryngology > Sleep Medicine > Facial Plastic Surgery.
#' When none match, returns `default`.
#'
#' @section Authoritative subspecialty source:
#'   This function is the **only authorized way** to derive subspecialty labels
#'   in the mysterycall workflow. NPPES (`taxonomies_desc`) and DAC
#'   (Data at CMS) taxonomy codes reflect broad specialty groupings and must
#'   not be used to assign subspecialty. Pass the output of this function as
#'   `secondary_col` in [mysterycall_reconcile_specialty()] to correctly
#'   populate subspecialty via board certification evidence only.
#'
#' @param cert_type Character vector of ABOHNS `certification_type` strings,
#'   one element per provider. Values like `"Otolaryngology - Head & Neck
#'   Surgery + Neurotology"` are parsed for subspecialty patterns. Pass `NA`
#'   for providers without ABOHNS records; they will receive `default`.
#' @param default Character scalar returned when no subspecialty pattern is
#'   detected (including `NA` or blank input). Default `NA_character_`.
#'
#' @return Character vector the same length as `cert_type`. Values are one of
#'   `"Otology/Neurotology"`, `"Pediatric Otolaryngology"`,
#'   `"Sleep Medicine"`, `"Facial Plastic Surgery"`, or `default`.
#'
#' @family provider characteristics
#' @export
#'
#' @examples
#' cert <- c(
#'   "Otolaryngology - Head & Neck Surgery + Neurotology",
#'   "Otolaryngology + Pediatric Otolaryngology + Sleep Medicine",
#'   "Otolaryngology - Head & Neck Surgery",
#'   NA
#' )
#' mysterycall_parse_certification_subspecialty(cert)
mysterycall_parse_certification_subspecialty <- function(cert_type,
                                                          default = NA_character_) {
  if (!is.character(cert_type)) cert_type <- as.character(cert_type)

  .parse_one <- function(s) {
    if (is.na(s) || !nzchar(trimws(s))) return(default)
    sl <- tolower(s)
    for (label in names(.mc_cert_patterns)) {
      if (grepl(.mc_cert_patterns[[label]], sl, fixed = TRUE)) return(label)
    }
    default
  }

  vapply(cert_type, .parse_one, character(1L), USE.NAMES = FALSE)
}


#' Extract a formatted physician name from a raw string
#'
#' Strips credential suffixes (MD, DO, PhD, etc.), removes leading titles
#' (Dr., Prof.), and returns either `"Dr. LastName"`, the bare last name,
#' or a cleaned full name. Handles both `"First Last"` and `"Last, First"`
#' formats.
#'
#' @param x Character vector of raw physician name strings.
#' @param format Character scalar controlling the output format:
#'   \describe{
#'     \item{`"dr_last"`}{`"Dr. Smith"` (default).}
#'     \item{`"last"`}{`"Smith"`.}
#'     \item{`"full_clean"`}{Full name with credentials and titles removed.}
#'   }
#'
#' @return Character vector the same length as `x`. `NA` for blank/`NA` inputs.
#'
#' @family provider characteristics
#' @export
#'
#' @examples
#' nms <- c("John Smith MD", "Dr. Jane Doe, PhD", "JONES, Robert",
#'          "Mary Williams, MD, FACS", NA)
#' mysterycall_extract_physician_name(nms)
#' mysterycall_extract_physician_name(nms, format = "last")
mysterycall_extract_physician_name <- function(x,
                                                format = c("dr_last", "last", "full_clean")) {
  format <- match.arg(format)
  if (!is.character(x)) stop("`x` must be a character vector.", call. = FALSE)

  cred_re  <- paste0(
    "\\s*,?\\s*\\b(",
    paste(c("MD","DO","PhD","MPH","MBA","MS","MSc","DrPH","FACS","FACOG",
            "FAAO","FAAOS","FACP","PA","NP","RN","DNP","DDS","DMD"),
          collapse = "|"),
    ")\\b.*$"
  )
  title_re <- "^\\s*(Dr\\.?|Prof\\.?|Mr\\.?|Mrs\\.?|Ms\\.?)\\s+"

  .parse_one <- function(nm) {
    if (is.na(nm) || !nzchar(trimws(nm))) return(NA_character_)
    clean <- gsub(cred_re,  "", nm,    perl = TRUE, ignore.case = TRUE)
    clean <- gsub(title_re, "", clean, perl = TRUE, ignore.case = TRUE)
    clean <- trimws(clean)

    # Input was all credentials/titles with no name remaining
    if (!nzchar(clean)) return(NA_character_)

    # Handle "Last, First" format
    last <- if (grepl(",", clean, fixed = TRUE)) {
      trimws(strsplit(clean, ",")[[1L]][[1L]])
    } else {
      parts <- strsplit(clean, "\\s+")[[1L]]
      parts[[length(parts)]]
    }

    switch(format,
      dr_last    = paste("Dr.", last),
      last       = last,
      full_clean = clean
    )
  }

  vapply(x, .parse_one, character(1L), USE.NAMES = FALSE)
}
