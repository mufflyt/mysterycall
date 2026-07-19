#' Normalize an organization / practice name for matching
#'
#' Practice and organization names arrive spelled a dozen ways -- mixed case,
#' curly apostrophes, `&` vs `and`, trailing `LLC`/`PC`/`PA`, stray punctuation
#' -- which defeats exact joins when you try to match a caller cohort against an
#' external roster (CMS, NPPES, an ownership reference, a prior wave). This
#' collapses those variants to a single canonical form so equal organizations
#' compare equal: it upper-cases, replaces `&` with `AND`, strips punctuation to
#' single spaces, drops common legal-entity suffixes, and squishes whitespace.
#'
#' It is deliberately conservative -- it does not stem words or fuzzy-match, so
#' two genuinely different practices stay different. Use it to build a join key,
#' then match on that key (optionally with your own alias/regex table on top).
#'
#' @param x A character vector (or coerced to one) of organization names. `NA`
#'   becomes `""`.
#' @param drop_suffixes Character vector of whole-word tokens to remove (legal
#'   entity types and credential suffixes). Matched case-insensitively as whole
#'   words after upper-casing. Defaults to the common US set. Pass `character(0)`
#'   to keep them.
#' @param expand_ampersand If `TRUE` (default) replace `&` with ` AND `.
#'
#' @return A character vector the length of `x` of normalized names.
#'
#' @examples
#' mysterycall_normalize_org_name(c(
#'   "Women's Health Specialists, LLC",
#'   "Womens Health Specialists PC",
#'   "Rocky Mountain OB & GYN, P.A."
#' ))
#' # -> "WOMENS HEALTH SPECIALISTS", "WOMENS HEALTH SPECIALISTS",
#' #    "ROCKY MOUNTAIN OB AND GYN"
#' @seealso [mysterycall_normalize_address_df()], [mysterycall_parse_physician_name()]
#' @export
mysterycall_normalize_org_name <- function(
    x,
    drop_suffixes = c("THE", "LLC", "PLLC", "PC", "PA", "LP", "LLP", "INC",
                      "CORP", "CORPORATION", "CO", "LTD", "MD", "DO"),
    expand_ampersand = TRUE) {

  checkmate::assert_character(drop_suffixes, any.missing = FALSE)
  checkmate::assert_flag(expand_ampersand)

  x <- as.character(x)
  x[is.na(x)] <- ""

  # delete apostrophes/quotes entirely so "Women's" and "Womens" collapse alike,
  # and delete periods so abbreviated suffixes like "P.A." become "PA" and get
  # dropped below (rather than splitting into stray single letters)
  x <- gsub("[‘’'`]", "", x)
  x <- gsub(".", "", x, fixed = TRUE)
  x <- toupper(x)
  if (expand_ampersand) x <- gsub("&", " AND ", x, fixed = TRUE)
  # everything else that is not a letter or digit becomes a single space
  x <- gsub("[^A-Z0-9]+", " ", x)

  if (length(drop_suffixes)) {
    pat <- paste0("\\b(", paste(toupper(drop_suffixes), collapse = "|"), ")\\b")
    x <- gsub(pat, " ", x)
  }

  # squish: trim and collapse internal runs of whitespace
  x <- gsub("\\s+", " ", x)
  trimws(x)
}
