#' Compare a study outcome across waves of a mystery caller study
#'
#' Calculates per-wave (and optionally per-group) summary statistics and
#' pairwise tests against a reference wave, using only base R.
#'
#' @param data A data frame.
#' @param wave_col Character scalar: column identifying the study wave.
#' @param outcome_col Character scalar: column containing the outcome to
#'   compare.
#' @param group_col Character scalar or NULL (default). When provided, results
#'   are stratified by group x wave.
#' @param type One of `"auto"` (default), `"proportion"`, or
#'   `"continuous"`. `"auto"` detects based on whether all
#'   non-missing outcome values are in \{0, 1\}.
#' @param ref_wave Scalar or NULL. The reference wave against which other
#'   waves are compared. When NULL, the first wave (sorted
#'   alphabetically/numerically) is used.
#'
#' @return A data frame. For proportion outcomes: columns `wave`,
#'   (`group`,) `n`, `n_accepted`, `rate`, `lower_ci`, `upper_ci`,
#'   `p_vs_ref`. For continuous outcomes: columns `wave`, (`group`,)
#'   `n`, `mean`, `median`, `sd`, `iqr`, `p_vs_ref`. The `group`
#'   column is only present when `group_col` is non-`NULL`. The
#'   attribute `ref_wave` is set on the returned data frame.
#'
#' @examples
#' df <- data.frame(
#'   wave    = c("pre","pre","post","post"),
#'   outcome = c(1, 0, 1, 1)
#' )
#' mysterycall_compare_waves(df, "wave", "outcome")
#'
#' @seealso [mysterycall_wait_time_summary()], [mysterycall_acceptance_rate()]
#'   for detailed single-wave outcome analysis; [mysterycall_bootstrap_ci()]
#'   for non-parametric confidence intervals.
#' @family inference
#' @export
mysterycall_compare_waves <- function(
    data,
    wave_col,
    outcome_col,
    group_col = NULL,
    type      = c("auto", "proportion", "continuous"),
    ref_wave  = NULL
) {
  # ---- input validation -------------------------------------------------------
  stopifnot(is.data.frame(data))
  stopifnot(is.character(wave_col),    length(wave_col)    == 1)
  stopifnot(is.character(outcome_col), length(outcome_col) == 1)
  if (!wave_col    %in% names(data)) stop("wave_col '",    wave_col,    "' not found in data.", call. = FALSE)
  if (!outcome_col %in% names(data)) stop("outcome_col '", outcome_col, "' not found in data.", call. = FALSE)
  if (!is.null(group_col)) {
    stopifnot(is.character(group_col), length(group_col) == 1)
    if (!group_col %in% names(data)) stop("group_col '", group_col, "' not found in data.", call. = FALSE)
  }

  type <- match.arg(type)

  waves <- sort(unique(data[[wave_col]]))
  if (length(waves) < 2) stop("At least 2 unique waves are required.", call. = FALSE)

  # ---- auto-detect type -------------------------------------------------------
  if (type == "auto") {
    xv <- data[[outcome_col]][!is.na(data[[outcome_col]])]
    type <- if (all(xv %in% c(0, 1))) "proportion" else "continuous"
  }

  # ---- reference wave ---------------------------------------------------------
  if (is.null(ref_wave)) {
    ref_wave <- waves[1]
  } else {
    if (!ref_wave %in% waves) {
      stop("ref_wave '", ref_wave, "' not found among wave values.", call. = FALSE)
    }
  }

  # ---- Wilson CI for a proportion ---------------------------------------------
  .wilson_ci <- function(x, n, alpha = 0.05) {
    if (n == 0) return(c(lower = NA_real_, upper = NA_real_))
    z    <- stats::qnorm(1 - alpha / 2)
    p    <- x / n
    denom <- 1 + z^2 / n
    center <- (p + z^2 / (2 * n)) / denom
    margin <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / denom
    c(lower = center - margin, upper = center + margin)
  }

  # ---- compute for a single wave x group subset -------------------------------
  .proportion_row <- function(sub, wave_val, group_val = NULL) {
    y    <- as.numeric(sub[[outcome_col]])
    n    <- sum(!is.na(y))
    nacc <- sum(y, na.rm = TRUE)
    rate <- if (n > 0) nacc / n else NA_real_
    ci   <- .wilson_ci(nacc, n)
    row  <- data.frame(
      wave      = wave_val,
      n         = n,
      n_accepted = nacc,
      rate      = rate,
      lower_ci  = ci["lower"],
      upper_ci  = ci["upper"],
      p_vs_ref  = NA_real_,
      stringsAsFactors = FALSE
    )
    if (!is.null(group_val)) row <- cbind(data.frame(group = group_val, stringsAsFactors = FALSE), row)
    row
  }

  .continuous_row <- function(sub, wave_val, group_val = NULL) {
    y   <- as.numeric(sub[[outcome_col]])
    y   <- y[!is.na(y)]
    n   <- length(y)
    row <- data.frame(
      wave     = wave_val,
      n        = n,
      mean     = if (n > 0) mean(y)   else NA_real_,
      median   = if (n > 0) stats::median(y) else NA_real_,
      sd       = if (n > 0) stats::sd(y)     else NA_real_,
      iqr      = if (n > 0) stats::IQR(y)    else NA_real_,
      p_vs_ref = NA_real_,
      stringsAsFactors = FALSE
    )
    if (!is.null(group_val)) row <- cbind(data.frame(group = group_val, stringsAsFactors = FALSE), row)
    row
  }

  # ---- build results ----------------------------------------------------------
  groups <- if (!is.null(group_col)) sort(unique(data[[group_col]])) else NA

  result_rows <- list()

  for (grp in groups) {
    if (is.na(grp) && is.null(group_col)) {
      data_g <- data
      grp_label <- NULL
    } else {
      data_g <- data[data[[group_col]] == grp, ]
      grp_label <- grp
    }

    # Reference subset
    ref_sub <- data_g[data_g[[wave_col]] == ref_wave, ]
    ref_y   <- as.numeric(ref_sub[[outcome_col]])
    ref_y   <- ref_y[!is.na(ref_y)]

    for (wv in waves) {
      sub <- data_g[data_g[[wave_col]] == wv, ]

      if (type == "proportion") {
        row <- .proportion_row(sub, wv, grp_label)
      } else {
        row <- .continuous_row(sub, wv, grp_label)
      }

      # p-value vs reference wave (NA for the ref wave itself)
      if (wv != ref_wave && length(ref_y) > 0) {
        wv_y <- as.numeric(sub[[outcome_col]])
        wv_y <- wv_y[!is.na(wv_y)]

        if (type == "proportion") {
          n_ref  <- length(ref_y)
          n_wv   <- length(wv_y)
          x_ref  <- sum(ref_y)
          x_wv   <- sum(wv_y)
          if (n_ref >= 1 && n_wv >= 1) {
            pt <- tryCatch(
              suppressWarnings(
                stats::prop.test(c(x_wv, x_ref), c(n_wv, n_ref), correct = FALSE)
              ),
              error = function(e) list(p.value = NA_real_)
            )
            row$p_vs_ref <- pt$p.value
          }
        } else {
          if (length(wv_y) >= 1 && length(ref_y) >= 1) {
            wt <- tryCatch(
              stats::wilcox.test(wv_y, ref_y)$p.value,
              error   = function(e) NA_real_,
              warning = function(w) suppressWarnings(stats::wilcox.test(wv_y, ref_y)$p.value)
            )
            row$p_vs_ref <- wt
          }
        }
      }

      result_rows[[length(result_rows) + 1]] <- row
    }
  }

  result <- do.call(rbind, result_rows)
  rownames(result) <- NULL
  attr(result, "ref_wave") <- ref_wave
  result
}
