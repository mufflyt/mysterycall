#' Generate a results paragraph for a logistic mystery caller model
#'
#' @name mysterycall_results_paragraph
NULL


#' Generate a results paragraph from a logistic model or odds-ratio table
#'
#' Produces ready-to-paste results sentences describing odds ratios (OR) from a
#' logistic regression, formatted for clinical manuscripts. Accepts a
#' `mysterycall_logistic_model` object or a plain data frame with OR columns.
#' For IRR-based (Poisson / negative-binomial) results use
#' [mysterycall_write_results_paragraph()] instead.
#'
#' @param model_result A `mysterycall_logistic_model` object returned by
#'   [mysterycall_logistic_model()], **or** a data frame with at minimum the
#'   columns `term`, `or`, `ci_lower`, `ci_upper`, and `p_value`.
#' @param ref_group Character scalar: the reference group label used in the
#'   sentence (e.g. `"commercial insurance"`).
#' @param exposure_col Character scalar: the name of the exposure variable
#'   whose levels are to be narrated (e.g. `"insurance"`). Terms whose name
#'   starts with this string are selected; the leading prefix is stripped to
#'   recover the level label.
#' @param outcome_label Character scalar: human-readable outcome description
#'   placed after "likely to be offered". Default `"appointment acceptance"`.
#' @param alpha Numeric scalar in (0, 1): significance threshold kept for
#'   downstream use; does not currently filter sentences. Default `0.05`.
#' @param or_digits Integer scalar: decimal places for the OR value. Default
#'   `2L`.
#' @param ci_digits Integer scalar: decimal places for CI bounds. Default `2L`.
#' @param p_digits Integer scalar: decimal places for p-values. Default `3L`.
#' @param subject Character scalar: the noun for the units being narrated.
#'   Default `"callers"`. Set to another noun (e.g. `"patients"`) for studies
#'   whose exposure is not caller-based.
#'
#' @return A single character string. One sentence is produced per
#'   non-intercept term matching `exposure_col`. Sentences are separated by a
#'   single space. Sentence form:
#'   \itemize{
#'     \item OR < 1: `"<Level> callers were <X>% less likely to be offered
#'       <outcome_label> (OR <or>, 95% CI <lo>-<hi>, p=<p>)."`
#'     \item OR > 1: `"<Level> callers were <X>% more likely to be offered
#'       <outcome_label> (OR <or>, 95% CI <lo>-<hi>, p=<p>)."`
#'     \item OR = 1: `"<Level> callers had similar odds of being offered
#'       <outcome_label> compared with <ref_group> (OR 1.00, 95% CI
#'       <lo>-<hi>, p=<p>)."`
#'   }
#'   When `p < 0.001` the p-value is rendered as `"p < 0.001"`.
#'
#' @family reporting
#' @seealso [mysterycall_write_results_paragraph()],
#'   [mysterycall_logistic_model()]
#' @export
#'
#' @examples
#' or_tbl <- data.frame(
#'   term     = c("(Intercept)", "insuranceMedicaid", "insuranceUninsured"),
#'   or       = c(2.10, 0.62, 0.41),
#'   ci_lower = c(1.20, 0.41, 0.22),
#'   ci_upper = c(3.68, 0.94, 0.76),
#'   p_value  = c(0.008, 0.024, 0.0004),
#'   stringsAsFactors = FALSE
#' )
#' mysterycall_results_paragraph(or_tbl, "commercial insurance", "insurance")
mysterycall_results_paragraph <- function(model_result,
                                          ref_group,
                                          exposure_col,
                                          outcome_label = "appointment acceptance",
                                          alpha         = 0.05,
                                          or_digits     = 2L,
                                          ci_digits     = 2L,
                                          p_digits      = 3L,
                                          subject       = "callers") {

  required_cols <- c("term", "or", "ci_lower", "ci_upper", "p_value")

  if (inherits(model_result, "mysterycall_logistic_model")) {
    if (is.null(model_result$or_table)) {
      stop("`model_result$or_table` is NULL.", call. = FALSE)
    }
    or_table <- as.data.frame(model_result$or_table)
  } else if (is.data.frame(model_result)) {
    or_table <- model_result
  } else {
    stop(
      paste0(
        "`model_result` must be a `mysterycall_logistic_model` object or a ",
        "data frame with columns: ", paste(required_cols, collapse = ", "), "."
      ),
      call. = FALSE
    )
  }

  missing_cols <- setdiff(required_cols, names(or_table))
  if (length(missing_cols) > 0L) {
    stop(
      "OR table is missing required column(s): ",
      paste(missing_cols, collapse = ", "), ".",
      call. = FALSE
    )
  }

  stopifnot("`ref_group` must be a non-empty string" = is.character(ref_group) && length(ref_group) == 1L && nchar(ref_group) > 0L)
  stopifnot("`exposure_col` must be a non-empty string" = is.character(exposure_col) && length(exposure_col) == 1L && nchar(exposure_col) > 0L)
  stopifnot("`outcome_label` must be a single string" = is.character(outcome_label) && length(outcome_label) == 1L)
  stopifnot("`subject` must be a single non-NA string" = is.character(subject) && length(subject) == 1L && !is.na(subject))
  stopifnot("`alpha` must be a number in (0, 1)" = is.numeric(alpha) && length(alpha) == 1L && alpha > 0 && alpha < 1)

  or_digits <- as.integer(or_digits)
  ci_digits <- as.integer(ci_digits)
  p_digits  <- as.integer(p_digits)

  matched <- or_table[startsWith(as.character(or_table$term), exposure_col) &
                        as.character(or_table$term) != "(Intercept)", , drop = FALSE]

  if (nrow(matched) == 0L) {
    stop(
      "No coefficient found matching exposure_col = '", exposure_col, "'.",
      call. = FALSE
    )
  }

  .fmt_p <- function(p) {
    if (is.na(p)) return("p = NA")
    if (p < 0.001) return("p < 0.001")
    paste0("p=", formatC(p, digits = p_digits, format = "f"))
  }

  sentences <- character(nrow(matched))

  for (i in seq_len(nrow(matched))) {
    row   <- matched[i, ]
    level <- sub(paste0("^", exposure_col), "", as.character(row$term))
    or    <- as.numeric(row$or)
    lo    <- as.numeric(row$ci_lower)
    hi    <- as.numeric(row$ci_upper)
    pv    <- as.numeric(row$p_value)

    or_fmt <- formatC(or, digits = or_digits, format = "f")
    lo_fmt <- formatC(lo, digits = ci_digits, format = "f")
    hi_fmt <- formatC(hi, digits = ci_digits, format = "f")
    p_fmt  <- .fmt_p(pv)

    pct <- round(abs(1 - or) * 100)

    if (abs(or - 1) < 10^(-or_digits)) {
      direction <- paste0(
        level, " ", subject, " had similar odds of being offered ", outcome_label,
        " compared with ", ref_group
      )
    } else if (or < 1) {
      direction <- paste0(
        level, " ", subject, " were ", pct, "% less likely to be offered ", outcome_label
      )
    } else {
      direction <- paste0(
        level, " ", subject, " were ", pct, "% more likely to be offered ", outcome_label
      )
    }

    sentences[i] <- paste0(
      direction,
      " (OR ", or_fmt, ", 95% CI ", lo_fmt, " to ", hi_fmt, ", ", p_fmt, ")."
    )
  }

  paste(sentences, collapse = " ")
}
