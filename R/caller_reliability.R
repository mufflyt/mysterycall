#' Compute inter-rater reliability between mystery callers
#'
#' Calculates Cohen's kappa, ICC, or percent agreement between two or more
#' callers -- or between a caller and a gold standard -- using only base R.
#'
#' @param data A data frame.
#' @param caller_col Character scalar: column identifying which caller made
#'   each rating.
#' @param outcome_col Character scalar: column containing the rating/outcome.
#' @param gold_col Character scalar or NULL (default). When provided, each row
#'   of \code{outcome_col} is compared with \code{gold_col} (two-rater
#'   agreement).
#' @param pair_col Character scalar or NULL (default). Each unique value
#'   identifies a subject/call that multiple callers rated. The data are
#'   reshaped wide (caller x subject matrix) and reliability is computed
#'   across all caller pairs.
#' @param type One of \code{"auto"}, \code{"kappa"}, \code{"icc"}, or
#'   \code{"percent_agreement"}. When \code{"auto"} (default): kappa for
#'   binary outcomes (values in \{0, 1, NA\}), icc for numeric continuous
#'   outcomes, percent_agreement for character/factor outcomes.
#' @param alpha Significance level for confidence intervals. Default 0.05.
#'
#' @return A named list with elements:
#' \describe{
#'   \item{type}{Character scalar: the reliability method used.}
#'   \item{statistic}{Numeric: kappa, ICC, or percent agreement.}
#'   \item{lower_ci}{Lower confidence bound.}
#'   \item{upper_ci}{Upper confidence bound.}
#'   \item{n_pairs}{Number of matched pairs used.}
#'   \item{interpretation}{Landis & Koch label for kappa ("poor", "fair",
#'     "moderate", "good", "excellent"); NA for other types.}
#' }
#'
#' @examples
#' df <- data.frame(
#'   caller  = c("A","A","B","B"),
#'   outcome = c(1, 0, 1, 0),
#'   gold    = c(1, 0, 1, 1)
#' )
#' mysterycall_caller_reliability(df, "caller", "outcome", gold_col = "gold")
#'
#' @seealso [mysterycall_check_generalist_presence()] for pre-call QC;
#'   [mysterycall_call_productivity()] for per-caller volume metrics;
#'   [mysterycall_compare_waves()] for cross-wave outcome comparisons.
#' @family caller-management
#' @export
mysterycall_caller_reliability <- function(
    data,
    caller_col,
    outcome_col,
    gold_col  = NULL,
    pair_col  = NULL,
    type      = c("auto", "kappa", "icc", "percent_agreement"),
    alpha     = 0.05
) {
  # ---- input validation -------------------------------------------------------
  stopifnot(is.data.frame(data))
  stopifnot(is.character(caller_col),  length(caller_col)  == 1)
  stopifnot(is.character(outcome_col), length(outcome_col) == 1)
  if (!caller_col  %in% names(data)) stop("caller_col '",  caller_col,  "' not found in data.", call. = FALSE)
  if (!outcome_col %in% names(data)) stop("outcome_col '", outcome_col, "' not found in data.", call. = FALSE)
  if (!is.null(gold_col)) {
    stopifnot(is.character(gold_col), length(gold_col) == 1)
    if (!gold_col %in% names(data)) stop("gold_col '", gold_col, "' not found in data.", call. = FALSE)
  }
  if (!is.null(pair_col)) {
    stopifnot(is.character(pair_col), length(pair_col) == 1)
    if (!pair_col %in% names(data)) stop("pair_col '", pair_col, "' not found in data.", call. = FALSE)
  }
  stopifnot(is.numeric(alpha), alpha > 0, alpha < 1)

  type <- match.arg(type)

  # ---- normalize caller names to title case -----------------------------------
  data[[caller_col]] <- tools::toTitleCase(tolower(trimws(as.character(data[[caller_col]]))))

  # ---- helper: auto-detect method ---------------------------------------------
  .detect_type <- function(x) {
    xv <- x[!is.na(x)]
    if (is.character(x) || is.factor(x)) return("percent_agreement")
    if (all(xv %in% c(0, 1)))            return("kappa")
    return("icc")
  }

  outcome_vec <- data[[outcome_col]]
  if (type == "auto") type <- .detect_type(outcome_vec)

  # ---- build rater1 / rater2 vectors ------------------------------------------
  if (!is.null(gold_col)) {
    # Gold standard comparison: rater1 = outcome_col, rater2 = gold_col
    keep <- !is.na(data[[outcome_col]]) & !is.na(data[[gold_col]])
    rater1 <- data[[outcome_col]][keep]
    rater2 <- data[[gold_col]][keep]

  } else if (!is.null(pair_col)) {
    # Reshape to wide; use first two callers if >2 for kappa / ICC pair logic
    callers <- unique(data[[caller_col]])
    if (length(callers) < 2) stop("Need at least 2 callers for reliability.", call. = FALSE)

    # Build wide matrix: rows = pairs, cols = callers
    wide <- lapply(callers, function(cl) {
      sub <- data[data[[caller_col]] == cl, c(pair_col, outcome_col)]
      names(sub) <- c("pair", cl)
      sub
    })
    merged <- wide[[1]]
    for (i in seq_along(wide)[-1]) {
      merged <- merge(merged, wide[[i]], by = "pair", all = TRUE)
    }
    # For two-rater stats: average across all pairs
    rater1 <- merged[[callers[1]]]
    rater2 <- merged[[callers[2]]]
    keep   <- !is.na(rater1) & !is.na(rater2)
    rater1 <- rater1[keep]
    rater2 <- rater2[keep]

  } else {
    # Pair consecutive rows within each caller -- not valid for >1 caller
    # fallback: split by caller and compare first two callers
    callers <- unique(data[[caller_col]])
    if (length(callers) < 2) stop("Need at least 2 callers or supply gold_col/pair_col.", call. = FALSE)
    d1 <- data[data[[caller_col]] == callers[1], ]
    d2 <- data[data[[caller_col]] == callers[2], ]
    n  <- min(nrow(d1), nrow(d2))
    rater1 <- d1[[outcome_col]][seq_len(n)]
    rater2 <- d2[[outcome_col]][seq_len(n)]
    keep   <- !is.na(rater1) & !is.na(rater2)
    rater1 <- rater1[keep]
    rater2 <- rater2[keep]
  }

  n_pairs <- length(rater1)
  if (n_pairs < 30L) {
    warning(sprintf(
      "Only %d complete pair(s) found. ICC and kappa are unreliable with fewer than 30 pairs; interpret results with caution.",
      n_pairs
    ), call. = FALSE)
  }
  if (n_pairs < 2) stop("Too few complete pairs (n = ", n_pairs, ") to compute reliability.", call. = FALSE)

  z_crit <- stats::qnorm(1 - alpha / 2)

  # ---- Cohen's kappa ----------------------------------------------------------
  .kappa_stats <- function(r1, r2, z_crit) {
    tab <- table(r1, r2)
    n   <- sum(tab)
    po  <- sum(diag(tab)) / n
    pe  <- sum(rowSums(tab) * colSums(tab)) / n^2
    if (abs(1 - pe) < .Machine$double.eps) {
      # perfect chance agreement -- kappa undefined
      return(list(kappa = NA_real_, lower = NA_real_, upper = NA_real_))
    }
    kappa <- (po - pe) / (1 - pe)
    se    <- sqrt((po * (1 - po)) / (n * (1 - pe)^2))
    list(
      kappa = kappa,
      lower = kappa - z_crit * se,
      upper = kappa + z_crit * se
    )
  }

  # ---- ICC (one-way random effects, Shrout & Fleiss 1979 ICC(1,1)) -----------
  .icc_stats <- function(r1, r2, z_crit) {
    # Stack so that subjects (not raters) are the grouping factor.
    # BMS = between-subject mean square; WMS = within-subject (residual).
    outcome <- c(r1, r2)
    subject <- factor(rep(seq_along(r1), 2L))
    fit     <- stats::aov(outcome ~ subject)
    ms      <- summary(fit)[[1]][["Mean Sq"]]
    # ms[1] = between-subject (BMS), ms[2] = within-subject residual (WMS)
    ms_b <- ms[1]
    ms_w <- ms[2]
    k    <- 2  # two raters
    icc  <- (ms_b - ms_w) / (ms_b + (k - 1) * ms_w)
    # F-distribution CI (Shrout & Fleiss 1979)
    n   <- length(r1)
    df1 <- n - 1
    df2 <- n * (k - 1)
    F_l <- (ms_b / ms_w) / stats::qf(1 - alpha / 2, df1, df2)
    F_u <- (ms_b / ms_w) * stats::qf(1 - alpha / 2, df2, df1)
    lower <- (F_l - 1) / (F_l + (k - 1))
    upper <- (F_u - 1) / (F_u + (k - 1))
    list(icc = icc, lower = lower, upper = upper)
  }

  # ---- percent agreement -------------------------------------------------------
  .pct_stats <- function(r1, r2, z_crit) {
    n  <- length(r1)
    po <- sum(r1 == r2) / n
    se <- sqrt(po * (1 - po) / n)
    list(
      pct   = po * 100,
      lower = (po - z_crit * se) * 100,
      upper = (po + z_crit * se) * 100
    )
  }

  # ---- Landis & Koch interpretation -------------------------------------------
  .interpret_kappa <- function(k) {
    if (is.na(k))  return(NA_character_)
    if (k < 0.20)  return("poor")
    if (k < 0.40)  return("fair")
    if (k < 0.60)  return("moderate")
    if (k < 0.80)  return("good")
    return("excellent")
  }

  # ---- compute ----------------------------------------------------------------
  if (type == "kappa") {
    res  <- .kappa_stats(rater1, rater2, z_crit)
    stat <- res$kappa
    lo   <- res$lower
    hi   <- res$upper
    interp <- .interpret_kappa(stat)

  } else if (type == "icc") {
    res  <- .icc_stats(rater1, rater2, z_crit)
    stat <- res$icc
    lo   <- res$lower
    hi   <- res$upper
    interp <- NA_character_

  } else {  # percent_agreement
    res  <- .pct_stats(as.character(rater1), as.character(rater2), z_crit)
    stat <- res$pct
    lo   <- res$lower
    hi   <- res$upper
    interp <- NA_character_
  }

  out <- list(
    type           = type,
    statistic      = stat,
    lower_ci       = lo,
    upper_ci       = hi,
    n_pairs        = n_pairs,
    interpretation = interp
  )
  class(out) <- "mysterycall_reliability"
  out
}

#' Print method for mysterycall_reliability objects
#'
#' @param x A `mysterycall_reliability` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   caller  = c("A", "A", "B", "B"),
#'   outcome = c(1L, 0L, 1L, 1L)
#' )
#' res <- mysterycall_caller_reliability(df, "caller", "outcome")
#' print(res)
#' }
#' @method print mysterycall_reliability
#' @family caller-management
#' @export
print.mysterycall_reliability <- function(x, ...) {
  cat("-- mysterycall_caller_reliability --\n")
  cat("Method       :", x$type, "\n")
  cat("Statistic    :", round(x$statistic, 4), "\n")
  cat("95% CI       : [", round(x$lower_ci, 4), ",", round(x$upper_ci, 4), "]\n")
  cat("N pairs      :", x$n_pairs, "\n")
  if (!is.na(x$interpretation)) {
    cat("Interpretation:", x$interpretation, "(Landis & Koch)\n")
  }
  invisible(x)
}
