#' Direction and change words wired to the sign of the data
#'
#' @description
#' Small helpers for manuscript and abstract prose that pick a direction word
#' from the **sign of a value**, so the words can never drift out of step with
#' the numbers they describe. Both functions are vectorized and return
#' `NA_character_` for `NA` input.
#'
#' `mysterycall_get_direction()` chooses a comparison word (default
#' `"higher"` / `"lower"` / `"no different"`); `mysterycall_get_change_verb()`
#' chooses a trend word (default `"increasing"` / `"decreasing"` / `"stable"`).
#' Every word is an argument, so each subspecialty or table can supply its own
#' vocabulary while the positive/negative/zero mapping stays fixed to the data.
#'
#' @param x Numeric vector. The signed quantity (e.g. a difference, slope, or
#'   percent change). Its sign selects the word.
#' @param tol Non-negative numeric scalar. Values with `abs(x) <= tol` are
#'   treated as no change and get the zero word. Default `0` (exact zero only).
#'
#' @return A character vector the same length as `x`.
#'
#' @examples
#' mysterycall_get_direction(c(2.4, -1.1, 0, NA))
#' # "higher" "lower" "no different" NA
#'
#' mysterycall_get_change_verb(c(3.2, -0.4, 0))
#' # "increasing" "decreasing" "stable"
#'
#' # Subspecialty-specific vocabulary, still tied to the data sign:
#' slope <- -0.8
#' sprintf("The MFM workforce is %s (%.1f per year).",
#'         mysterycall_get_change_verb(slope), slope)
#'
#' @name mysterycall_direction_words
NULL

#' @rdname mysterycall_direction_words
#' @param positive Word used when `x > tol`. Default `"higher"`.
#' @param negative Word used when `x < -tol`. Default `"lower"`.
#' @param zero Word used when `abs(x) <= tol`. Default `"no different"`.
#' @family reporting
#' @export
mysterycall_get_direction <- function(x,
                                      positive = "higher",
                                      negative = "lower",
                                      zero     = "no different",
                                      tol      = 0) {
  .direction_word(x, positive, negative, zero, tol)
}

#' @rdname mysterycall_direction_words
#' @param increasing Word used when `x > tol`. Default `"increasing"`.
#' @param decreasing Word used when `x < -tol`. Default `"decreasing"`.
#' @param stable Word used when `abs(x) <= tol`. Default `"stable"`.
#' @family reporting
#' @export
mysterycall_get_change_verb <- function(x,
                                        increasing = "increasing",
                                        decreasing = "decreasing",
                                        stable     = "stable",
                                        tol        = 0) {
  .direction_word(x, increasing, decreasing, stable, tol)
}

# Shared engine: map sign(x) -> word, NA-safe, with a zero tolerance band.
.direction_word <- function(x, pos, neg, zer, tol) {
  if (!is.numeric(x)) {
    x <- suppressWarnings(as.numeric(x))
  }
  if (!is.numeric(tol) || length(tol) != 1L || is.na(tol) || tol < 0) {
    stop("`tol` must be a single non-negative number.", call. = FALSE)
  }
  for (nm in c("pos", "neg", "zer")) {
    w <- get(nm)
    if (!is.character(w) || length(w) != 1L || is.na(w)) {
      stop("Direction words must each be a single non-NA character string.",
           call. = FALSE)
    }
  }
  out <- ifelse(x > tol, pos, ifelse(x < -tol, neg, zer))
  out[is.na(x)] <- NA_character_
  out
}
