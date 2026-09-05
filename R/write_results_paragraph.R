#' Generate a results paragraph for a mystery caller Poisson model
#'
#' Produces a ready-to-paste results sentence describing IRRs from a
#' multivariable Poisson regression, formatted for clinical manuscripts.
#'
#' @param model_result A `mysterycall_poisson_model` or `mysterycall_nb_model`
#'   object (with element `$irr_table`), or a data frame with columns `term`,
#'   `irr`, `ci_lower`, `ci_upper`, and `p_value`.
#' @param ref_group Character scalar: the reference group label (e.g.
#'   `"commercial insurance"`).
#' @param exposure_col Character scalar: name of the exposure variable whose
#'   terms are to be described (e.g. `"insurance"`).
#' @param outcome_label Character scalar: human-readable outcome label.
#'   Default `"appointment acceptance"`.
#' @param alpha Numeric: significance level. Default 0.05. (Currently reserved
#'   for future use.)
#' @param irr_digits Integer: decimal places for IRR. Default 2L.
#' @param ci_digits Integer: decimal places for CI bounds. Default 2L.
#' @param p_digits Integer: decimal places for p-value. Default 3L.
#'
#' @return A single character string containing all result sentences.
#'
#' @examples
#' irr_tbl <- data.frame(
#'   term     = c("(Intercept)", "insuranceMedicaid", "insuranceUninsured"),
#'   irr      = c(1.0, 0.72, 0.55),
#'   ci_lower = c(NA,  0.60, 0.40),
#'   ci_upper = c(NA,  0.86, 0.75),
#'   p_value  = c(NA,  0.0003, 0.0000001),
#'   stringsAsFactors = FALSE
#' )
#' mysterycall_write_results_paragraph(irr_tbl, "commercial insurance", "insurance")
#'
#' @seealso [mysterycall_poisson_model()] which produces the `model_result`
#'   input; [mysterycall_acceptance_rate()] for tabular summaries of the
#'   same outcome data.
#' @family reporting
#' @export
mysterycall_write_results_paragraph <- function(
    model_result,
    ref_group,
    exposure_col,
    outcome_label = "appointment acceptance",
    alpha         = 0.05,
    irr_digits    = 2L,
    ci_digits     = 2L,
    p_digits      = 3L
) {
  # ---- required columns in irr_table ------------------------------------------
  required_cols <- c("term", "irr", "ci_lower", "ci_upper", "p_value")

  # ---- validate model_result --------------------------------------------------
  is_nb <- inherits(model_result, "mysterycall_nb_model")
  if (inherits(model_result, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    if (is.null(model_result$irr_table)) {
      stop("model_result$irr_table is NULL.")
    }
    irr_table <- as.data.frame(model_result$irr_table)
  } else if (is.data.frame(model_result)) {
    is_nb <- FALSE
    irr_table <- model_result
  } else {
    stop(
      "model_result must be a 'mysterycall_poisson_model', 'mysterycall_nb_model', or a data frame ",
      "with columns: ", paste(required_cols, collapse = ", "), "."
    )
  }

  missing_cols <- setdiff(required_cols, names(irr_table))
  if (length(missing_cols) > 0) {
    stop("irr_table is missing required columns: ",
         paste(missing_cols, collapse = ", "), ".")
  }

  # ---- validate other inputs --------------------------------------------------
  stopifnot("`ref_group` must be a non-empty string" = is.character(ref_group) && length(ref_group) == 1 && nchar(ref_group) > 0)
  stopifnot("`exposure_col` must be a non-empty string" = is.character(exposure_col) && length(exposure_col) == 1 && nchar(exposure_col) > 0)
  stopifnot("`alpha` must be a number in (0, 1)" = is.numeric(alpha) && alpha > 0 && alpha < 1)

  irr_digits <- as.integer(irr_digits)
  ci_digits  <- as.integer(ci_digits)
  p_digits   <- as.integer(p_digits)

  # ---- extract rows matching exposure_col prefix ------------------------------
  matched <- irr_table[startsWith(as.character(irr_table$term), exposure_col), ]

  if (nrow(matched) == 0) {
    stop("No coefficient found for exposure_col = '", exposure_col, "'.", call. = FALSE)
  }

  # ---- format p-value ---------------------------------------------------------
  .fmt_p <- function(p) {
    if (is.na(p)) return("p = NA")
    if (p < 0.001) return("p < 0.001")
    paste0("p = ", formatC(p, digits = p_digits, format = "f"))
  }

  # ---- build sentences --------------------------------------------------------
  model_type <- if (is_nb) "negative binomial regression" else "Poisson regression"
  # Only claim significance when at least one exposure level actually clears
  # alpha; otherwise the intro would assert an association that the p-values
  # (printed in the very next sentences) contradict.
  any_sig <- any(as.numeric(matched$p_value) < alpha, na.rm = TRUE)
  assoc_phrase <- if (any_sig) {
    "was significantly associated with"
  } else {
    "was not significantly associated with"
  }
  intro <- paste0(
    "In multivariable ", model_type, ", ", exposure_col,
    " ", assoc_phrase, " ", outcome_label, " (see Table X)."
  )

  level_sentences <- character(nrow(matched))
  for (i in seq_len(nrow(matched))) {
    row   <- matched[i, ]
    level <- sub(paste0("^", exposure_col), "", as.character(row$term))
    irr   <- formatC(as.numeric(row$irr),      digits = irr_digits, format = "f")
    lo    <- formatC(as.numeric(row$ci_lower),  digits = ci_digits,  format = "f")
    hi    <- formatC(as.numeric(row$ci_upper),  digits = ci_digits,  format = "f")
    p_fmt <- .fmt_p(as.numeric(row$p_value))

    level_sentences[i] <- paste0(
      "Compared with ", ref_group,
      ", callers presenting as ", level,
      " had an IRR of ", irr,
      " (95% CI ", lo, " to ", hi, "; ", p_fmt, ")",
      " for ", outcome_label, "."
    )
  }

  paste(c(intro, level_sentences), collapse = " ")
}
