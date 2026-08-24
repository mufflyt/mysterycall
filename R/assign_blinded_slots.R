#' Assign blinded record slots that don't encode a matched pair's treatment arm
#'
#' Assigns each record in a two-arm matched-pairs design (e.g. a REDCap import) a slot number
#' from `1:length(pair)` such that the slot's parity carries no information about which arm a
#' record belongs to, and the two records making up a matched pair never land on consecutive
#' slots.
#'
#' This exists because the naive approach --- sorting records by `(pair, group)` and taking
#' `row_number()` --- silently defeats blinding in any two-arm matched-pairs mystery-caller
#' study. If the arm labels sort consistently (e.g. "Non-PE" before "PE" alphabetically), every
#' pair lands control-then-treatment in the sorted order, which makes slot parity a perfect
#' predictor of the arm and puts the two members of a pair next to each other in whatever
#' dropdown or call sheet the record ids populate. A masked/hidden field on the exposure column
#' does not fix this, because the leak is the record id itself, not a visible field. This
#' shipped undetected in one mystery-caller study until every per-state count turned out even.
#'
#' @param pair Vector (any type; coerced to character for grouping), one value per record,
#'   identifying which matched pair a record belongs to. Every pair must appear exactly twice.
#' @param group Vector the same length as `pair` giving each record's treatment arm. Must have
#'   exactly 2 distinct values, and each arm's total count must be even (required for exact
#'   parity balance).
#' @param seed Integer seed for the search over candidate permutations, set via
#'   [withr::local_seed()] so it does not disturb the caller's own random state. The result is
#'   reproducible for a given `pair`, `group`, and `seed`, but --- unlike a sort on a visible
#'   column --- cannot be re-derived without also knowing `seed`, so callers must persist the
#'   returned slot assignment (the crosswalk) if it needs to be recovered later.
#' @param max_tries Integer. Maximum number of random candidate permutations to try before
#'   giving up. A candidate is accepted the first time no matched pair lands on consecutive
#'   slots; parity balance is enforced by construction on every candidate, not by retrying.
#'   Default `1000L`.
#'
#' @return An integer vector the same length as `pair`, a permutation of `seq_along(pair)`:
#'   `result[i]` is the slot assigned to the `i`-th input record.
#'
#' @section Guarantees:
#' \describe{
#'   \item{Exact parity balance}{Each arm occupies exactly half the odd slots and half the
#'     even slots, so slot parity carries zero information about the arm -- not merely little.}
#'   \item{No pair adjacency}{The two records belonging to any one pair never occupy
#'     consecutive slots in the returned ordering.}
#' }
#' Neither guarantee is probabilistic: both hold on the specific candidate permutation that is
#' returned, checked before it is returned. Parity balance is exact by construction (each arm's
#' shuffled members are split evenly across the two parity classes before slots are assigned);
#' pair-adjacency is checked and the candidate discarded (up to `max_tries` times) if violated.
#'
#' @family study design
#' @seealso [mysterycall_count_business_days()] for the companion primary-outcome contract.
#' @export
#'
#' @examples
#' pair  <- rep(1:4, each = 2)
#' group <- rep(c("treatment", "control"), 4)
#' mysterycall_assign_blinded_slots(pair, group, seed = 1)
mysterycall_assign_blinded_slots <- function(pair, group, seed = 20260824L, max_tries = 1000L) {
  n <- length(pair)
  if (length(group) != n) {
    stop("`pair` and `group` must be the same length.", call. = FALSE)
  }
  if (n %% 2L != 0L) {
    stop("Need an even number of records to balance parity; got ", n, ".", call. = FALSE)
  }
  arms <- sort(unique(as.character(group)))
  if (length(arms) != 2L) {
    stop("Expected exactly 2 arms, found ", length(arms), ": ",
         paste(arms, collapse = ", "), ".", call. = FALSE)
  }
  sizes <- vapply(arms, function(a) sum(group == a), integer(1))
  if (any(sizes %% 2L != 0L)) {
    stop("Each arm must have an even size for exact parity balance; got ",
         paste(sprintf("%s=%d", arms, sizes), collapse = ", "), ".", call. = FALSE)
  }

  odd  <- seq.int(1L, n, by = 2L)
  even <- seq.int(2L, n, by = 2L)
  withr::local_seed(seed)

  for (try in seq_len(max_tries)) {
    # Half of each arm to odd slots, half to even, then shuffle the members within each
    # parity class so the arms are not blocked into low and high slots either.
    halves <- lapply(arms, function(a) {
      idx <- sample(which(group == a))
      split(idx, rep(c("odd", "even"), each = length(idx) / 2L))
    })
    to_odd  <- sample(unlist(lapply(halves, `[[`, "odd"),  use.names = FALSE))
    to_even <- sample(unlist(lapply(halves, `[[`, "even"), use.names = FALSE))

    slot <- integer(n)
    slot[to_odd]  <- odd
    slot[to_even] <- even

    by_slot <- as.character(pair)[order(slot)]
    if (!any(by_slot[-1L] == by_slot[-n])) return(slot)
  }
  stop("Could not place ", n, " records without a matched pair landing on consecutive slots ",
       "in ", max_tries, " attempts.", call. = FALSE)
}
