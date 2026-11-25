# Generic institutional words are evidence-poor in dense health-care markets:
# nearly every candidate contains HOSPITAL, MEDICAL, CENTER, HEALTH, SYSTEM,
# CLINIC, or an academic department term. They remain in the normalized key
# (removing them would make distinct systems collapse), but token scoring
# downweights them rather than counting them like a distinctive proper noun.

#' Generic organization tokens used in weighted matching
#'
#' These words are common in hospital and practice names and therefore carry
#' less identity evidence than distinctive proper nouns. The vector is exported
#' so callers can inspect the default, extend it for a local vocabulary, or
#' pass a replacement vector to the org-token helpers.
#'
#' @format A character vector of upper-case normalized tokens.
#' @export
MYSTERYCALL_GENERIC_ORG_TOKENS <- c(
  "HOSPITAL", "MEDICAL", "CENTER", "UNIVERSITY", "HEALTH",
  "SYSTEM", "NEW", "YORK", "CITY", "DEPARTMENT", "OBSTETRICS",
  "GYNECOLOGY", "PROGRAM", "CLINIC", "HEALTHCARE", "MEDICINE",
  "SCHOOL", "COLLEGE", "INSTITUTE"
)

# Org matching removes function words as well as legal entities. This is not
# the contract of mysterycall_normalize_org_name(), whose exported default is a
# join-key normalizer; it is a tokenization contract for evidence comparison.
.mysterycall_org_normalize_for_tokens <- function(x) {
  mysterycall_normalize_org_name(
    x,
    drop_suffixes = c("THE", "OF", "AT", "AND", "FOR", "IN", "A", "AN",
                      "LLC", "PLLC", "PC", "PA", "LP", "LLP", "INC", "CORP",
                      "CORPORATION", "CO", "LTD", "MD", "DO"),
    expand_ampersand = FALSE
  )
}

.mysterycall_pair_index <- function(a, b, label) {
  la <- length(a); lb <- length(b)
  if (la == lb) return(list(a = seq_len(la), b = seq_len(lb), n = la))
  if (la == 1L) return(list(a = rep(1L, lb), b = seq_len(lb), n = lb))
  if (lb == 1L) return(list(a = seq_len(la), b = rep(1L, la), n = la))
  stop(label, " inputs must be the same length, or one must be length 1 for broadcasting",
       call. = FALSE)
}

#' Tokenize organization names for evidence comparison
#'
#' Normalizes names with [mysterycall_normalize_org_name()], drops function
#' words and legal-entity suffixes, and returns unique upper-case tokens.
#' Generic institutional words are retained; they are downweighted by
#' [mysterycall_weighted_token_similarity()] rather than deleted, because
#' deleting them can make distinct health systems collapse to the same key.
#'
#' @param x Character vector of organization names.
#' @return A list of unique character-token vectors, one per input element.
#' @examples
#' mysterycall_org_tokens("University of Colorado Hospital, LLC")
#' @export
mysterycall_org_tokens <- function(x) {
  x <- .mysterycall_org_normalize_for_tokens(x)
  lapply(strsplit(x, " ", fixed = TRUE), function(tokens) {
    unique(tokens[nzchar(tokens)])
  })
}

#' Count non-generic organization tokens
#'
#' @param x Character vector of organization names.
#' @param generic_tokens Character vector of tokens to treat as generic.
#' @return Integer vector of counts of unique non-generic tokens.
#' @examples
#' mysterycall_count_meaningful_org_tokens("University Medical Center")
#' mysterycall_count_meaningful_org_tokens("Rose Medical Center")
#' @export
mysterycall_count_meaningful_org_tokens <- function(
    x,
    generic_tokens = MYSTERYCALL_GENERIC_ORG_TOKENS) {
  checkmate::assert_character(generic_tokens, any.missing = FALSE)
  generic_tokens <- toupper(generic_tokens)
  vapply(mysterycall_org_tokens(x), function(tokens) {
    sum(!tokens %in% generic_tokens)
  }, integer(1L), USE.NAMES = FALSE)
}

#' Weighted token similarity for organization names
#'
#' Computes weighted overlap divided by the size of the unweighted token union:
#' distinctive shared tokens count `1`, generic institutional tokens count
#' `generic_weight`. The denominator is deliberately unweighted so adding more
#' generic words cannot make two sparse names look similar. Missing or blank
#' names score `0`; absence is not positive evidence.
#'
#' @param a,b Character vectors of organization names. Equal lengths or scalar
#'   broadcasting are accepted; other length mismatches error.
#' @param generic_tokens Character vector of tokens to downweight.
#' @param generic_weight Numeric scalar in `[0, 1]` for generic shared tokens.
#' @return Numeric vector of similarities in `[0, 1]`.
#' @examples
#' mysterycall_weighted_token_similarity(
#'   "Rose Medical Center",
#'   "Rose Medical Center Denver"
#' )
#' @export
mysterycall_weighted_token_similarity <- function(
    a, b,
    generic_tokens = MYSTERYCALL_GENERIC_ORG_TOKENS,
    generic_weight = 0.25) {
  checkmate::assert_character(generic_tokens, any.missing = FALSE)
  checkmate::assert_number(generic_weight, lower = 0, upper = 1)
  idx <- .mysterycall_pair_index(a, b, "mysterycall_weighted_token_similarity")
  generic_tokens <- toupper(generic_tokens)
  ta <- mysterycall_org_tokens(a[idx$a])
  tb <- mysterycall_org_tokens(b[idx$b])
  vapply(seq_len(idx$n), function(i) {
    x <- ta[[i]]; y <- tb[[i]]
    if (!length(x) || !length(y)) return(0)
    shared <- intersect(x, y)
    if (!length(shared)) return(0)
    weighted_overlap <- sum(ifelse(shared %in% generic_tokens, generic_weight, 1))
    weighted_overlap / length(union(x, y))
  }, numeric(1L), USE.NAMES = FALSE)
}

#' Exact or meaningful-substring organization agreement
#'
#' Positive evidence only: returns `TRUE` when normalized names are exactly
#' equal, or when one is a substring of the other and both sides contribute at
#' least `min_meaningful_tokens` non-generic tokens. Generic-only substring
#' agreement (for example, two names sharing only UNIVERSITY MEDICAL CENTER)
#' is not enough. A blank or missing name returns `FALSE` rather than erroring.
#'
#' @param a,b Character vectors of organization names. Equal lengths or scalar
#'   broadcasting are accepted; other length mismatches error.
#' @param min_meaningful_tokens Integer scalar minimum count of unique
#'   non-generic tokens required on both sides of a substring match.
#' @param generic_tokens Character vector of tokens to treat as generic.
#' @return Logical vector.
#' @examples
#' mysterycall_org_names_agree(
#'   "Rose Medical Center Denver",
#'   "Rose Medical Center Denver Hospital"
#' )
#' mysterycall_org_names_agree(
#'   "University Medical Center",
#'   "University Medical Center Hospital"
#' )
#' @export
mysterycall_org_names_agree <- function(
    a, b,
    min_meaningful_tokens = 2L,
    generic_tokens = MYSTERYCALL_GENERIC_ORG_TOKENS) {
  checkmate::assert_count(min_meaningful_tokens, positive = TRUE)
  checkmate::assert_character(generic_tokens, any.missing = FALSE)
  idx <- .mysterycall_pair_index(a, b, "mysterycall_org_names_agree")
  na <- .mysterycall_org_normalize_for_tokens(a[idx$a])
  nb <- .mysterycall_org_normalize_for_tokens(b[idx$b])
  ta <- mysterycall_org_tokens(a[idx$a])
  tb <- mysterycall_org_tokens(b[idx$b])
  generic_tokens <- toupper(generic_tokens)

  vapply(seq_len(idx$n), function(i) {
    x <- na[[i]]; y <- nb[[i]]
    if (!nzchar(x) || !nzchar(y)) return(FALSE)
    if (identical(x, y)) return(TRUE)
    substring_hit <- (nchar(x) >= 3L && nchar(y) >= 3L) &&
      (grepl(x, y, fixed = TRUE) || grepl(y, x, fixed = TRUE))
    if (!substring_hit) return(FALSE)
    meaningful_x <- sum(!ta[[i]] %in% generic_tokens)
    meaningful_y <- sum(!tb[[i]] %in% generic_tokens)
    min(meaningful_x, meaningful_y) >= min_meaningful_tokens
  }, logical(1L), USE.NAMES = FALSE)
}
