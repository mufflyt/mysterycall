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
#' @param impute Logical. When `TRUE` (default), unmatched physicians receive a
#'   fallback age so the column has full coverage: the median `age_current` of
#'   the reference within the query's state, or the national median when the
#'   state is unknown or unseen. Imputed rows are always flagged (`age_imputed`,
#'   and `age_source` set to `"imputed_state_median"` /
#'   `"imputed_national_median"`) so they can be excluded or modelled
#'   separately. When `FALSE`, unmatched ages stay `NA`.
#'
#' @return A [tibble::tibble()] with one row per query, in input order,
#'   containing the echoed query columns and the matched fields:
#'   \describe{
#'     \item{first_name, last_name, state}{The query values (state upper-cased
#'       to its two-letter form).}
#'     \item{matched}{Logical; `TRUE` when a reference physician was found by
#'       name and state (never `TRUE` for an imputed row).}
#'     \item{age_current}{Estimated current-year age. Observed when `matched`,
#'       imputed when `age_imputed`, or `NA` when unmatched and `impute = FALSE`.}
#'     \item{age_imputed}{Logical; `TRUE` when `age_current` is a fallback
#'       estimate rather than a matched value.}
#'     \item{honorific, npi, city, age_at_scrape, scrape_year, age_source,
#'       n_obs}{The matched reference fields, or `NA` when unmatched. For imputed
#'       rows `age_source` records which fallback was used.}
#'   }
#'
#' @family data integrity
#' @seealso [healthgrades_ages] for the reference dataset and its caveats;
#'   [mysterycall_link_physicians()] for probabilistic name linkage when a
#'   state-blocked exact match is too strict.
#' @examples
#' # Unmatched "Nobody Xyzzy" gets an imputed CO age, flagged age_imputed = TRUE
#' mysterycall_lookup_age(
#'   first_name = c("Gioi", "Debra", "Nobody"),
#'   last_name  = c("Smith-Nguyen", "Acerenza", "Xyzzy"),
#'   state      = c("California", "MD", "CO")
#' )
#'
#' # Leave unmatched ages as NA instead
#' mysterycall_lookup_age("Nobody", "Xyzzy", "CO", impute = FALSE)
#' @export
mysterycall_lookup_age <- function(first_name, last_name, state,
                                   reference = NULL, impute = TRUE) {
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

  checkmate::assert_flag(impute)

  out <- tibble::tibble(
    first_name  = first_name,
    last_name   = last_name,
    state       = state_abbr,
    matched     = !is.na(idx),
    age_current = reference$age_current[idx],
    age_imputed = FALSE
  )
  for (col in extra) out[[col]] <- reference[[col]][idx]

  # Impute a fallback age for unmatched rows so the column is fully covered,
  # flagging every filled value (age_imputed) and recording the method used
  # (age_source) so imputed rows can be excluded or modelled separately.
  need <- is.na(out$age_current)
  if (impute && any(need)) {
    imp <- .mc_age_impute(state_abbr[need], reference)
    out$age_current[need] <- imp$age
    out$age_imputed[need]  <- !is.na(imp$age)
    if ("age_source" %in% names(out)) out$age_source[need] <- imp$source
  }
  out
}

#' Impute a fallback physician age from the reference age distribution
#'
#' Returns the reference median `age_current` within each supplied state,
#' falling back to the national median when the state is missing or absent from
#' the reference. Used by [mysterycall_lookup_age()] to give unmatched
#' physicians a flagged fallback age.
#'
#' @param state_abbr Character vector of two-letter state abbreviations (may be
#'   `NA`).
#' @param reference Reference data frame with `state` and `age_current`.
#' @return A list with `age` (numeric vector, same length as `state_abbr`) and
#'   `source` (character vector: `"imputed_state_median"` or
#'   `"imputed_national_median"`).
#' @family data integrity
#' @keywords internal
.mc_age_impute <- function(state_abbr, reference) {
  st_med   <- tapply(reference$age_current, reference$state,
                     stats::median, na.rm = TRUE)
  nat_med  <- stats::median(reference$age_current, na.rm = TRUE)
  by_state <- st_med[state_abbr]
  age      <- ifelse(is.na(by_state), nat_med, by_state)
  source   <- ifelse(is.na(by_state), "imputed_national_median",
                     "imputed_state_median")
  list(age = round(as.numeric(age)), source = source)
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
