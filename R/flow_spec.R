# flow_spec.R — a participant-flow diagram that refuses to draw wrong numbers.
#
# Every R package for this problem (flowchart, consort, ggconsort, dtrackr,
# vtree) generates a diagram FROM data, which keeps typed numbers out of the
# picture and then stops. None checks that the boxes close. A diagram whose
# spine reads 1,154 -> 1,106 with a 48 exclusion is arithmetically fine; one
# that reads 1,154 -> 1,100 with a 48 exclusion is a reporting error that no
# renderer will notice, because a renderer draws what it is handed.
#
# mysterycall_strobe_flow() has the same gap: it accepts n_total, n_included
# and n_logistic from the caller and draws them. This is the layer underneath
# it -- validate first, render second, and make the validation reusable.

#' Validate a participant-flow specification
#'
#' Checks that a STROBE/CONSORT participant flow actually closes: each step on
#' the spine, minus the exclusions leaving it, equals the next step, and the
#' children of every split sum to their parent. Returns a validated object for
#' [mysterycall_strobe_diagram()] to draw.
#'
#' The arithmetic is the point. A renderer draws what it is handed, so a flow
#' diagram can be internally plausible and still disagree with the study it
#' describes. Validating separately from drawing means the same check can run
#' in a test suite, where a stale figure is actually caught, rather than only
#' at render time on someone's laptop.
#'
#' @param spine Named numeric vector of the main-column boxes, top to bottom,
#'   in order. At least two entries. Names are the box labels.
#' @param exclusions Named list. Each name must match a `spine` entry, and is
#'   the step the exclusion arrow leaves FROM. Each element is a named numeric
#'   vector of one or more reasons; the names become the exclusion box lines.
#'   Steps with no exclusions may be omitted.
#' @param splits Named list. Each name must match a `spine` entry or another
#'   split's child. Each element is a named numeric vector whose values must
#'   sum to the named parent. Use this for a terminal published/not-published
#'   split, or a breakdown that stays inside its parent rather than leaving
#'   the study.
#' @param assert Logical. When `TRUE` (default), arithmetic that does not close
#'   is an error. `FALSE` still type-checks but permits a deliberately partial
#'   diagram; the returned object records `closed = FALSE`.
#'
#' @return An object of class `mysterycall_flow_spec`: a list with `spine`,
#'   `exclusions`, `splits` and `closed`.
#'
#' @examples
#' # The AAGL abstract-publication cohort (mufflyt/abstract_lifetime).
#' spec <- mysterycall_flow_spec(
#'   spine = c(
#'     "Abstracts parsed from congress supplements" = 1154,
#'     "Oral presentation cohort"                   = 1106,
#'     "Evaluated for publication status"           = 1051
#'   ),
#'   exclusions = list(
#'     "Abstracts parsed from congress supplements" = c("Video presentations" = 48),
#'     "Oral presentation cohort"                   = c("Adjudication unresolved" = 55)
#'   ),
#'   splits = list(
#'     "Evaluated for publication status" = c("Published" = 170, "Not published" = 881),
#'     "Not published" = c("No qualifying publication" = 839,
#'                         "Publication predates the congress" = 42)
#'   )
#' )
#' spec
#'
#' # A step that does not close is an error, and the message names the step.
#' try(mysterycall_flow_spec(
#'   spine = c("Screened" = 100, "Analysed" = 90),
#'   exclusions = list("Screened" = c("Ineligible" = 5))
#' ))
#'
#' @seealso [mysterycall_strobe_diagram()] to draw a validated spec,
#'   [mysterycall_strobe_flow()] for the mystery-caller-specific diagram.
#' @export
mysterycall_flow_spec <- function(spine,
                                  exclusions = list(),
                                  splits = list(),
                                  assert = TRUE) {

  .check_counts(spine, "spine")
  if (length(spine) < 2L)
    stop("`spine` needs at least two steps; got ", length(spine), ".", call. = FALSE)

  exclusions <- .check_group(exclusions, "exclusions")
  splits     <- .check_group(splits, "splits")

  known_excl <- names(exclusions)[!names(exclusions) %in% names(spine)]
  if (length(known_excl))
    stop("`exclusions` names a step that is not on the spine: ",
         paste(known_excl, collapse = ", "), call. = FALSE)

  # A split may hang off a spine step or off another split's child, which is
  # how a "not published" arm gets broken down without leaving the study.
  parents <- c(names(spine), unlist(lapply(splits, names), use.names = FALSE))
  unknown_split <- names(splits)[!names(splits) %in% parents]
  if (length(unknown_split))
    stop("`splits` names a parent that is neither a spine step nor another ",
         "split's child: ", paste(unknown_split, collapse = ", "), call. = FALSE)

  closed <- TRUE
  problems <- character(0)

  if (assert) {
    nm <- names(spine)
    for (i in seq_len(length(spine) - 1L)) {
      left <- unname(spine[[i]])
      out  <- if (nm[i] %in% names(exclusions)) sum(exclusions[[nm[i]]]) else 0
      if (!isTRUE(all.equal(left - out, unname(spine[[i + 1L]]))))
        problems <- c(problems, sprintf(
          "%s (%s) minus %s excluded is %s, but the next step %s is %s",
          nm[i], .fmt_count(left), .fmt_count(out), .fmt_count(left - out),
          nm[i + 1L], .fmt_count(spine[[i + 1L]])))
    }

    # unname() first: unlist() on a named list prefixes the child names
    # ("Evaluated.Published"), so the parent lookup misses and [[ throws.
    lookup <- c(spine, unlist(unname(splits)))
    for (p in names(splits)) {
      kids <- sum(splits[[p]])
      if (!p %in% names(lookup))
        stop("`splits` names the parent ", p, ", which has no count.", call. = FALSE)
      if (!isTRUE(all.equal(kids, unname(lookup[[p]]))))
        problems <- c(problems, sprintf(
          "the parts of %s sum to %s, but %s is %s",
          p, .fmt_count(kids), p, .fmt_count(lookup[[p]])))
    }

    if (length(problems)) {
      closed <- FALSE
      stop("this flow does not close:\n  - ",
           paste(problems, collapse = "\n  - "), call. = FALSE)
    }
  } else {
    closed <- NA
  }

  structure(list(spine = spine, exclusions = exclusions, splits = splits,
                 closed = closed),
            class = "mysterycall_flow_spec")
}

#' @param x A `mysterycall_flow_spec`.
#' @param ... Ignored.
#' @rdname mysterycall_flow_spec
#' @export
print.mysterycall_flow_spec <- function(x, ...) {
  cat("<mysterycall_flow_spec>",
      if (isTRUE(x$closed)) " arithmetic closes\n" else
        if (is.na(x$closed)) " not checked\n" else " DOES NOT CLOSE\n", sep = "")
  nm <- names(x$spine)
  for (i in seq_along(x$spine)) {
    cat(sprintf("  %s: n = %s\n", nm[i], .fmt_count(x$spine[[i]])))
    if (nm[i] %in% names(x$exclusions))
      for (e in seq_along(x$exclusions[[nm[i]]]))
        cat(sprintf("      -> excluded: %s, n = %s\n",
                    names(x$exclusions[[nm[i]]])[e],
                    .fmt_count(x$exclusions[[nm[i]]][[e]])))
  }
  for (p in names(x$splits))
    cat(sprintf("  %s splits into %s\n", p,
                paste(sprintf("%s (n = %s)", names(x$splits[[p]]),
                              vapply(x$splits[[p]], .fmt_count, character(1))),
                      collapse = " + ")))
  invisible(x)
}

.fmt_count <- function(n) format(as.numeric(n), big.mark = ",", trim = TRUE,
                                 scientific = FALSE)

.check_counts <- function(x, what) {
  if (!is.numeric(x) || is.null(names(x)) || any(!nzchar(names(x))))
    stop("`", what, "` must be a NAMED numeric vector.", call. = FALSE)
  if (anyNA(x))
    stop("`", what, "` contains NA. A missing count cannot be drawn as a box.",
         call. = FALSE)
  if (any(x < 0))
    stop("`", what, "` contains a negative count (",
         paste(names(x)[x < 0], collapse = ", "),
         "). A negative box means a subtraction ran on mismatched inputs.",
         call. = FALSE)
  if (any(x != trunc(x)))
    stop("`", what, "` contains a fractional count (",
         paste(names(x)[x != trunc(x)], collapse = ", "), ").", call. = FALSE)
  if (anyDuplicated(names(x)))
    stop("`", what, "` has duplicate names (",
         paste(unique(names(x)[duplicated(names(x))]), collapse = ", "),
         "); box labels must be unique.", call. = FALSE)
  invisible(TRUE)
}

.check_group <- function(g, what) {
  if (is.null(g) || !length(g)) return(list())
  if (!is.list(g) || is.null(names(g)) || any(!nzchar(names(g))))
    stop("`", what, "` must be a NAMED list.", call. = FALSE)
  for (n in names(g)) .check_counts(g[[n]], paste0(what, "$`", n, "`"))
  g
}
