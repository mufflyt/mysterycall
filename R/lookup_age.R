#' Look up physician age by name and state
#'
#' Attaches an estimated current-year age to physicians for whom you have a name
#' and a state but no NPI, by matching against the bundled [healthgrades_ages]
#' reference. Matching is case-, punctuation-, and whitespace-insensitive on
#' normalised `(last_name, first_name, state)` -- the same key the reference is
#' deduplicated on -- so each query resolves to at most one physician.
#'
#' The reference is keyed on state because names alone over-link (there are many
#' "Michael Miller"s); requiring a matching state removes most spurious hits.
#' State may be given as a two-letter USPS abbreviation (`"CA"`) or a full name
#' (`"California"`); full names are converted automatically.
#'
#' Ages are vendor-reported estimates projected to the reference year (2026 in
#' the shipped data); treat them as approximate. When a match's `n_obs` is large
#' but the underlying scrapes disagreed, the returned age is that of the most
#' recent dated scrape (see [healthgrades_ages]).
#'
#' @param first_name,last_name Character vectors of given and family names.
#'   Recycled against each other; must be the same length (or length 1).
#' @param state Character vector of practice states, as two-letter USPS
#'   abbreviations or full state names. Recycled to match the names. `NA` or
#'   empty states never match.
#' @param reference Optional data frame to match against, defaulting to the
#'   package's [healthgrades_ages]. Must contain `first_name`, `last_name`,
#'   `state`, and `age_current`; supply your own only for testing or to use an
#'   updated roster.
#'
#' @return A [tibble::tibble()] with one row per query, in input order,
#'   containing the echoed query columns and the matched fields:
#'   \describe{
#'     \item{first_name, last_name, state}{The query values (state upper-cased
#'       to its two-letter form).}
#'     \item{matched}{Logical; `TRUE` when a reference physician was found.}
#'     \item{age_current}{Estimated current-year age, or `NA` when unmatched.}
#'     \item{honorific, npi, city, age_at_scrape, scrape_year, age_source,
#'       n_obs}{The matched reference fields, or `NA` when unmatched.}
#'   }
#'
#' @family data integrity
#' @seealso [healthgrades_ages] for the reference dataset and its caveats;
#'   [mysterycall_link_physicians()] for probabilistic name linkage when a
#'   state-blocked exact match is too strict.
#' @examples
#' mysterycall_lookup_age(
#'   first_name = c("Gioi", "Debra", "Nobody"),
#'   last_name  = c("Smith-Nguyen", "Acerenza", "Xyzzy"),
#'   state      = c("California", "MD", "CO")
#' )
#' @export
mysterycall_lookup_age <- function(first_name, last_name, state,
                                   reference = NULL) {
  checkmate::assert_character(first_name, min.len = 1L)
  checkmate::assert_character(last_name)
  checkmate::assert(
    checkmate::check_character(state),
    checkmate::check_factor(state)
  )

  # Recycle scalars to a common length.
  n <- max(length(first_name), length(last_name), length(state))
  recycle <- function(x, nm) {
    if (length(x) == n) return(x)
    if (length(x) == 1L) return(rep(x, n))
    stop(sprintf("`%s` must be length 1 or %d, not %d.", nm, n, length(x)),
         call. = FALSE)
  }
  first_name <- recycle(first_name, "first_name")
  last_name  <- recycle(last_name,  "last_name")
  state      <- recycle(as.character(state), "state")

  if (is.null(reference)) reference <- .mc_healthgrades_ages()
  checkmate::assert_data_frame(reference, min.rows = 1L)
  checkmate::assert_subset(
    c("first_name", "last_name", "state", "age_current"), names(reference)
  )

  state_abbr <- .mc_state_to_abbr(state)

  # Build the normalised match key for queries and reference alike.
  qkey <- .mc_age_key(last_name, first_name, state_abbr)
  rkey <- .mc_age_key(reference$last_name, reference$first_name, reference$state)

  idx <- match(qkey, rkey)             # first (only) reference row per key

  extra <- c("honorific", "npi", "city", "age_at_scrape",
             "scrape_year", "age_source", "n_obs")
  extra <- intersect(extra, names(reference))

  out <- tibble::tibble(
    first_name  = first_name,
    last_name   = last_name,
    state       = state_abbr,
    matched     = !is.na(idx),
    age_current = reference$age_current[idx]
  )
  for (col in extra) out[[col]] <- reference[[col]][idx]
  out
}

#' Normalise a name/state key for age matching
#'
#' Upper-cases, strips periods and commas, and squishes whitespace, matching the
#' key used to deduplicate [healthgrades_ages]. Missing states yield `NA` so
#' blank-state queries never match.
#'
#' @param last,first,state Character vectors of equal length.
#' @return Character vector of `"LAST|FIRST|ST"` keys, or `NA` where the state
#'   is missing.
#' @family data integrity
#' @keywords internal
.mc_age_key <- function(last, first, state) {
  clean <- function(x) {
    x <- toupper(trimws(as.character(x)))
    x <- gsub("[.,]", "", x)
    x <- gsub("\\s+", " ", x)
    x[x == ""] <- NA_character_
    x
  }
  st <- clean(state)
  key <- paste(clean(last), clean(first), st, sep = "|")
  key[is.na(st)] <- NA_character_
  key
}

#' Coerce US state names to two-letter USPS abbreviations
#'
#' Leaves valid two-letter codes untouched (upper-cased) and maps full state
#' names via base R's `state.name`/`state.abb`. Unrecognised values pass through
#' upper-cased so an exact-code match can still succeed.
#'
#' @param state Character vector of states.
#' @return Character vector of upper-cased abbreviations.
#' @family data integrity
#' @keywords internal
.mc_state_to_abbr <- function(state) {
  s  <- toupper(trimws(as.character(state)))
  nm <- match(s, toupper(state.name))
  out <- ifelse(!is.na(nm), state.abb[nm], s)
  out[is.na(out) | out == ""] <- NA_character_
  out
}

#' Load the bundled healthgrades_ages reference
#'
#' @return The [healthgrades_ages] data frame.
#' @family data integrity
#' @keywords internal
.mc_healthgrades_ages <- function() {
  e <- new.env()
  utils::data("healthgrades_ages", package = "mysterycall", envir = e)
  get("healthgrades_ages", envir = e)
}
