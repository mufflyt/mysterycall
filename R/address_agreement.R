#' Street-address keys and agreement verdicts
#'
#' These functions turn a free-text US street address into the parts that are
#' safe to compare -- a normalized string, a leading street number, and the
#' non-suffix street tokens -- then compare two addresses without treating a
#' missing address as evidence. Unit designators are removed before tokenization
#' because physicians and facilities often record the same street address with
#' different suite, floor, room, or department detail.
#'
#' `mysterycall_street_address_key()` is scalar because a key is the input to
#' one comparison. `mysterycall_street_address_agreement()` returns the shared
#' three-verdict vocabulary (`corroborates`, `conflicts`, `uninformative`) plus
#' a named reason; `mysterycall_street_addresses_agree()` is the logical
#' positive-evidence wrapper for callers that only need "does this corroborate
#' the same street address?".
#'
#' @param address Character scalar street address. `NA` and blank input return
#'   an empty key rather than erroring.
#' @return `mysterycall_street_address_key()` returns a named list with
#'   `normalized`, `street_number`, `street_tokens`, `is_po_box`, and
#'   `has_num`. `street_tokens` excludes roadway suffix tokens (ST, AVE, RD,
#'   and the other USPS suffix abbreviations) so `"123 Main St"` cannot match
#'   `"123 Oak St"` merely because both are streets.
#' @examples
#' key <- mysterycall_street_address_key("123 North Main Street Suite 400")
#' key$street_number
#' key$street_tokens
#' @export
mysterycall_street_address_key <- function(address) {
  checkmate::assert_string(address, na.ok = TRUE)
  empty <- list(
    normalized = NA_character_,
    street_number = NA_character_,
    street_tokens = character(0),
    is_po_box = NA,
    has_num = FALSE
  )
  if (is.na(address) || !nzchar(trimws(address))) return(empty)

  is_po <- mysterycall_is_po_box(address)
  x <- mysterycall_normalize_directionals(address)
  x <- mysterycall_normalize_suffix(x)
  # DEPT/DEPARTMENT are common in hospital street addresses but are not part
  # of mysterycall_strip_suite()'s USPS unit-designator contract.
  x <- stringr::str_replace_all(
    x,
    "\\b(DEPT|DEPARTMENT)\\.?\\s*#?\\s*[A-Z0-9]+\\b",
    ""
  )
  x <- mysterycall_strip_suite(x)
  x <- stringr::str_replace_all(x, "[^A-Z0-9]+", " ")
  x <- stringr::str_squish(x)

  tokens <- strsplit(x, " ", fixed = TRUE)[[1L]]
  tokens <- tokens[nzchar(tokens)]
  suffix_tokens <- unique(unname(.suffix_map))
  street_number <- NA_character_
  street_tokens <- character(0)
  if (length(tokens) && isFALSE(is_po)) {
    if (grepl("^[0-9]+$", tokens[[1L]])) {
      street_number <- tokens[[1L]]
      street_tokens <- tokens[-1L]
    } else {
      street_tokens <- tokens
    }
    street_tokens <- unique(street_tokens[!street_tokens %in% suffix_tokens])
  }

  list(
    normalized = x,
    street_number = street_number,
    street_tokens = street_tokens,
    is_po_box = is_po,
    has_num = !is.na(street_number)
  )
}

.as_street_address_key <- function(x, label) {
  if (is.list(x) && all(c("normalized", "street_number", "street_tokens",
                          "is_po_box", "has_num") %in% names(x))) {
    return(x)
  }
  if (!is.character(x) || length(x) != 1L) {
    stop(label, " must be a character scalar or a key from mysterycall_street_address_key()",
         call. = FALSE)
  }
  mysterycall_street_address_key(x)
}

#' Compare two street addresses
#'
#' `mysterycall_street_address_agreement()` compares two character scalars or
#' two keys from [mysterycall_street_address_key()]. A missing, blank, PO-box,
#' or numberless address is `uninformative`; it neither corroborates nor
#' vetoes a match. Different leading street numbers conflict. Equal numbers
#' corroborate only when the normalized strings are identical or at least one
#' non-suffix street token is shared.
#'
#' @param a,b Character scalar street addresses, or keys produced by
#'   [mysterycall_street_address_key()].
#' @return `mysterycall_street_address_agreement()` returns a one-row data
#'   frame with `verdict` and `reason`.
#'   `mysterycall_street_addresses_agree()` returns `TRUE` only when the
#'   verdict is `corroborates`.
#' @examples
#' mysterycall_street_address_agreement(
#'   "123 Main Street Suite 200",
#'   "123 N Main St"
#' )
#' mysterycall_street_addresses_agree("123 Main St", "123 Oak St")
#' @export
mysterycall_street_address_agreement <- function(a, b) {
  ka <- .as_street_address_key(a, "a")
  kb <- .as_street_address_key(b, "b")

  out <- function(verdict, reason) {
    data.frame(verdict = verdict, reason = reason, stringsAsFactors = FALSE)
  }

  blank_a <- is.na(ka$normalized) || !nzchar(ka$normalized)
  blank_b <- is.na(kb$normalized) || !nzchar(kb$normalized)
  if (blank_a || blank_b) return(out("uninformative", "missing_address"))
  if (isTRUE(ka$is_po_box) || isTRUE(kb$is_po_box)) {
    return(out("uninformative", "po_box_not_street_address"))
  }
  if (is.na(ka$street_number) || is.na(kb$street_number)) {
    return(out("uninformative", "missing_street_number"))
  }
  if (!identical(ka$street_number, kb$street_number)) {
    return(out("conflicts", "street_number_conflict"))
  }
  if (identical(ka$normalized, kb$normalized)) {
    return(out("corroborates", "exact_normalized"))
  }
  if (length(intersect(ka$street_tokens, kb$street_tokens)) >= 1L) {
    return(out("corroborates", "street_number_and_token"))
  }
  out("conflicts", "no_shared_street_token")
}

#' @rdname mysterycall_street_address_agreement
#' @export
mysterycall_street_addresses_agree <- function(a, b) {
  identical(mysterycall_street_address_agreement(a, b)$verdict, "corroborates")
}
