#' Adjust P-Values for Multiple Comparisons
#'
#' Wraps \code{stats::p.adjust()} with convenience features: accepts either a
#' numeric vector of p-values or a data.frame with a named p-value column,
#' adds significance stars, and returns a tidy data.frame.
#'
#' @param x A numeric vector of p-values, or a data.frame containing a
#'   p-value column identified by \code{p_col}.
#' @param method Character. Correction method passed to
#'   \code{stats::p.adjust()}. One of \code{"bonferroni"}, \code{"fdr"},
#'   \code{"holm"}, \code{"BH"}, or \code{"BY"}. \code{"fdr"} is an alias
#'   for \code{"BH"}.
#' @param alpha Numeric in (0, 1). Significance threshold for the
#'   \code{significant} column. Default 0.05.
#' @param p_col Character scalar or NULL. When \code{x} is a data.frame,
#'   the name of the column holding raw p-values.
#' @param label_col Character scalar or NULL. When \code{x} is a data.frame,
#'   the name of a column to use as \code{comparison} labels.
#'
#' @return A data.frame with columns:
#'   \describe{
#'     \item{comparison}{Label for each comparison (from \code{label_col},
#'       row names, or sequential integers).}
#'     \item{p_raw}{Original (unadjusted) p-value.}
#'     \item{p_adjusted}{Adjusted p-value.}
#'     \item{significant}{Logical; TRUE when \code{p_adjusted < alpha}.}
#'     \item{stars}{Significance stars: \code{"***"} (p<0.001),
#'       \code{"**"} (p<0.01), \code{"*"} (p<0.05), \code{"ns"} otherwise.}
#'   }
#'
#' @examples
#' pvals <- c(0.001, 0.03, 0.2, 0.5, 0.04)
#' mysterycall_multiple_comparison_adjust(pvals, method = "bonferroni")
#'
#' df <- data.frame(
#'   comparison = c("A vs B", "A vs C", "B vs C"),
#'   p          = c(0.01, 0.04, 0.3)
#' )
#' mysterycall_multiple_comparison_adjust(df, p_col = "p", label_col = "comparison")
#'
#' @seealso [mysterycall_bootstrap_ci()] for bootstrap-based interval
#'   estimation; [mysterycall_poisson_model()] whose coefficients typically
#'   feed this function; [stats::p.adjust()] for the underlying adjustment.
#' @family inference
#' @export
mysterycall_multiple_comparison_adjust <- function(
    x,
    method    = c("bonferroni", "fdr", "holm", "BH", "BY"),
    alpha     = 0.05,
    p_col     = NULL,
    label_col = NULL
) {
  method <- match.arg(method)

  # ---- input validation ------------------------------------------------
  if (!is.numeric(alpha) || length(alpha) != 1L || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be a single numeric value in (0, 1).", call. = FALSE)
  }

  # ---- extract p-values and labels ------------------------------------
  if (is.data.frame(x)) {
    if (is.null(p_col)) {
      stop(
        "When `x` is a data.frame, `p_col` must be specified.",
        call. = FALSE
      )
    }
    if (!p_col %in% names(x)) {
      stop(sprintf("Column '%s' not found in `x`.\nAvailable columns: %s",
                   p_col, paste(names(x), collapse = ", ")), call. = FALSE)
    }
    pvals <- x[[p_col]]
    if (!is.null(label_col)) {
      if (!label_col %in% names(x)) {
        stop(sprintf("Column '%s' not found in `x`.\nAvailable columns: %s",
                     label_col, paste(names(x), collapse = ", ")), call. = FALSE)
      }
      labels <- as.character(x[[label_col]])
    } else {
      rn <- rownames(x)
      labels <- if (!is.null(rn) && !all(rn == as.character(seq_len(nrow(x))))) {
        rn
      } else {
        as.character(seq_len(nrow(x)))
      }
    }
  } else if (is.numeric(x)) {
    pvals  <- x
    labels <- as.character(seq_along(x))
  } else {
    stop("`x` must be a numeric vector or a data.frame.", call. = FALSE)
  }

  # ---- validate p-values ----------------------------------------------
  if (any(is.na(pvals))) {
    warning("NA p-values detected; they will be passed through as NA.",
            call. = FALSE)
  }
  bad <- !is.na(pvals) & (pvals < 0 | pvals > 1)
  if (any(bad)) {
    stop(
      "All p-values must be in [0, 1]. Found values outside this range.",
      call. = FALSE
    )
  }

  # ---- map "fdr" alias ------------------------------------------------
  adj_method <- if (method == "fdr") "BH" else method

  # ---- adjust ---------------------------------------------------------
  p_adj <- stats::p.adjust(pvals, method = adj_method)

  # ---- significance stars ---------------------------------------------
  stars <- vapply(p_adj, function(p) {
    if (is.na(p))   return(NA_character_)
    if (p < 0.001)  return("***")
    if (p < 0.01)   return("**")
    if (p < 0.05)   return("*")
    "ns"
  }, FUN.VALUE = character(1L))

  data.frame(
    comparison  = labels,
    p_raw       = pvals,
    p_adjusted  = p_adj,
    significant = !is.na(p_adj) & p_adj < alpha,
    stars       = stars,
    stringsAsFactors = FALSE
  )
}
