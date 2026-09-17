#' Build a three-column regression table for manuscript submission
#'
#' Creates the "three-column regression table" that reviewers almost always
#' request: Model 1 (unadjusted) | Model 2 (adjusted) | Model 3 (+
#' interaction). Supports any combination of
#' \code{mysterycall_logistic_model}, \code{mysterycall_poisson_model},
#' \code{mysterycall_nb_model}, and \code{mysterycall_lmm} objects in a
#' single table. Mixed model types trigger a warning and label each column
#' header with its model type.
#'
#' @param models Named list of fitted model objects. Each element must be one
#'   of `mysterycall_logistic_model`, `mysterycall_poisson_model`,
#'   `mysterycall_nb_model`, or `mysterycall_lmm`. Must contain at least two
#'   models. Names become column headers in the output table.
#' @param include_intercept Logical. When \code{FALSE} (default) the
#'   \code{(Intercept)} row is dropped from output.
#' @param digits Integer. Decimal places for point estimates and confidence
#'   interval bounds. Default \code{2L}.
#' @param estimate_col_label Character or `NULL`. A label describing the
#'   estimate type shown in each model column (printed as a subtitle). When
#'   `NULL` (default) it is auto-detected from the model class:
#'   `"OR (95% CI)"` for logistic, `"IRR (95% CI)"` for
#'   Poisson/NB, and `"Beta (95% CI)"` for LMM. When model types
#'   differ the label falls back to `"Estimate (95% CI)"`.
#' @param include_n Logical. When \code{TRUE} (default) a footer row labelled
#'   \code{"N"} is appended showing the complete-case sample size for each
#'   model.
#' @param include_aic Logical. When \code{TRUE} (default) a footer row
#'   labelled \code{"AIC"} is appended. AIC is not meaningful for LMMs
#'   fitted with \code{REML = TRUE}; those cells are labelled
#'   \code{"(REML)"}.
#' @param ref_symbol Character. Symbol placed in reference-category cells.
#'   Default \code{"Ref."}.
#' @param cell_layout Character. How the p-value sits relative to the estimate
#'   within a cell. \code{"stacked"} (default) puts the p-value on a second line
#'   (\code{"1.45 (1.02-2.05)\\np=0.038"}) -- correct for \pkg{gt}/HTML and the
#'   console print method. \code{"inline"} keeps the whole cell on one line
#'   (\code{"1.45 (1.02-2.05), p=0.038"}) so the table renders correctly in a
#'   Markdown/pandoc **pipe table**, which cannot contain a multi-line cell (an
#'   embedded newline otherwise spills every p-value onto its own row).
#'
#' @details
#' **Cell format.** Each non-reference cell contains the point estimate and
#' 95\% CI followed by the formatted p-value; with \code{cell_layout = "stacked"}
#' the p-value is on a second line, e.g. \code{"1.45 (1.02-2.05)\\np=0.038"}, and
#' with \code{"inline"} it follows on the same line. Reference-category cells
#' show \code{ref_symbol}. Terms absent from a particular model show an
#' empty string.
#'
#' **Row ordering.** Rows follow the union of all unique terms across models.
#' For categorical predictors, the reference-category row is inserted
#' immediately before the first coefficient level found in the model output,
#' using the \code{factor_refs} metadata stored in each model object.
#'
#' **Mixed model types.** When models of different classes are combined a
#' warning is issued and each column name gains a type tag such as
#' \code{"[Logistic]"} or \code{"[Poisson]"}. Numbers in each column remain
#' on their native scale (OR, IRR, or Beta).
#'
#' @return A \code{data.frame} with class
#'   \code{c("mysterycall_multi_model_table", "data.frame")}. Column
#'   \code{"Term"} contains variable/level labels; subsequent columns are
#'   named after \code{names(models)}. The attribute \code{"estimate_label"}
#'   stores the auto-detected or user-supplied \code{estimate_col_label};
#'   \code{"mixed_types"} stores a logical indicating whether multiple model
#'   classes are present.
#'
#' @family manuscript
#' @seealso [mysterycall_model_table()], [mysterycall_model_comparison_table()]
#' @importFrom stats AIC
#' @export
#'
#' @examples
#' # Build fake model objects with structure() -- no package fitting required.
#'
#' m_unadj <- structure(
#'   list(
#'     or_table = data.frame(
#'       term        = c("insuranceMedicaid", "scenarioNo appointment"),
#'       or          = c(1.45, 0.82),
#'       ci_lower    = c(1.02, 0.61),
#'       ci_upper    = c(2.05, 1.10),
#'       p_value_fmt = c("0.038", "0.189"),
#'       stringsAsFactors = FALSE
#'     ),
#'     factor_refs = list(insurance = "BCBS", scenario = "Appointment"),
#'     n   = 200L,
#'     aic = 312.4
#'   ),
#'   class = "mysterycall_logistic_model"
#' )
#'
#' m_adj <- structure(
#'   list(
#'     or_table = data.frame(
#'       term        = c("insuranceMedicaid", "scenarioNo appointment",
#'                       "regionSouth"),
#'       or          = c(1.38, 0.79, 1.21),
#'       ci_lower    = c(0.97, 0.58, 0.88),
#'       ci_upper    = c(1.96, 1.07, 1.66),
#'       p_value_fmt = c("0.072", "0.124", "0.238"),
#'       stringsAsFactors = FALSE
#'     ),
#'     factor_refs = list(insurance = "BCBS", scenario = "Appointment",
#'                        region    = "North"),
#'     n   = 200L,
#'     aic = 308.1
#'   ),
#'   class = "mysterycall_logistic_model"
#' )
#'
#' m_inter <- structure(
#'   list(
#'     or_table = data.frame(
#'       term        = c("insuranceMedicaid", "scenarioNo appointment",
#'                       "regionSouth",
#'                       "insuranceMedicaid:scenarioNo appointment"),
#'       or          = c(1.41, 0.81, 1.19, 0.67),
#'       ci_lower    = c(0.99, 0.59, 0.86, 0.41),
#'       ci_upper    = c(2.01, 1.09, 1.65, 1.09),
#'       p_value_fmt = c("0.059", "0.163", "0.272", "0.107"),
#'       stringsAsFactors = FALSE
#'     ),
#'     factor_refs = list(insurance = "BCBS", scenario = "Appointment",
#'                        region    = "North"),
#'     n   = 200L,
#'     aic = 306.8
#'   ),
#'   class = "mysterycall_logistic_model"
#' )
#'
#' tbl <- mysterycall_multi_model_table(
#'   models = list(
#'     "Unadjusted"   = m_unadj,
#'     "Adjusted"     = m_adj,
#'     "+ Interaction" = m_inter
#'   )
#' )
#' print(tbl)
mysterycall_multi_model_table <- function(
    models,
    include_intercept  = FALSE,
    digits             = 2L,
    estimate_col_label = NULL,
    include_n          = TRUE,
    include_aic        = TRUE,
    ref_symbol         = "Ref.",
    cell_layout        = c("stacked", "inline")
) {

  cell_layout <- match.arg(cell_layout)

  # --------------------------------------------------------------------------
  # Input validation
  # --------------------------------------------------------------------------
  if (!is.list(models)) {
    stop("`models` must be a named list of fitted model objects.", call. = FALSE)
  }
  if (is.null(names(models)) || any(!nzchar(trimws(names(models))))) {
    stop("Every element of `models` must have a non-empty name.", call. = FALSE)
  }
  if (length(models) < 2L) {
    stop("`models` must contain at least 2 model objects.", call. = FALSE)
  }
  if (!is.numeric(digits) || length(digits) != 1L || digits < 0L) {
    stop("`digits` must be a non-negative integer scalar.", call. = FALSE)
  }
  if (!is.null(estimate_col_label) &&
      (!is.character(estimate_col_label) || length(estimate_col_label) != 1L)) {
    stop(
      "`estimate_col_label` must be a single character string or NULL.",
      call. = FALSE
    )
  }
  if (!is.character(ref_symbol) || length(ref_symbol) != 1L) {
    stop("`ref_symbol` must be a single character string.", call. = FALSE)
  }

  # --------------------------------------------------------------------------
  # Identify model types
  # --------------------------------------------------------------------------
  .supported <- c(
    "mysterycall_logistic_model",
    "mysterycall_poisson_model",
    "mysterycall_nb_model",
    "mysterycall_lmm"
  )

  model_types <- vapply(seq_along(models), function(i) {
    m   <- models[[i]]
    cls <- class(m)
    hit <- intersect(cls, .supported)
    if (!length(hit)) {
      stop(sprintf(
        "Model '%s' has unsupported class '%s'. Supported classes: %s.",
        names(models)[[i]],
        paste(cls, collapse = "/"),
        paste(.supported, collapse = ", ")
      ), call. = FALSE)
    }
    hit[[1L]]
  }, character(1L))

  # --------------------------------------------------------------------------
  # Mixed-type warning and column-name type tags
  # --------------------------------------------------------------------------
  unique_types <- unique(model_types)
  mixed        <- length(unique_types) > 1L

  if (mixed) {
    warning(
      "Models of different types detected: ",
      paste(unique_types, collapse = ", "),
      ". Each column uses its native scale (OR / IRR / Beta). ",
      "Column names gain a type tag for clarity.",
      call. = FALSE
    )
  }

  .type_tag <- function(mt) {
    switch(mt,
      mysterycall_logistic_model = "[Logistic]",
      mysterycall_poisson_model  = "[Poisson]",
      mysterycall_nb_model       = "[NB]",
      mysterycall_lmm            = "[LMM]"
    )
  }

  col_names <- if (mixed) {
    paste0(names(models), " ", vapply(model_types, .type_tag, character(1L)))
  } else {
    names(models)
  }

  # --------------------------------------------------------------------------
  # Auto-detect estimate_col_label
  # --------------------------------------------------------------------------
  if (is.null(estimate_col_label)) {
    estimate_col_label <- if (!mixed) {
      switch(unique_types[[1L]],
        mysterycall_logistic_model = "OR (95% CI)",
        mysterycall_poisson_model  = "IRR (95% CI)",
        mysterycall_nb_model       = "IRR (95% CI)",
        mysterycall_lmm            = "Beta (95% CI)"
      )
    } else {
      "Estimate (95% CI)"
    }
  }

  # --------------------------------------------------------------------------
  # Extract tidy (term, est, ci_lower, ci_upper, p_fmt) from each model
  # --------------------------------------------------------------------------
  .extract <- function(m, mtype) {
    switch(mtype,

      mysterycall_logistic_model = {
        t <- m$or_table
        data.frame(
          term     = t$term,
          est      = t$or,
          ci_lower = t$ci_lower,
          ci_upper = t$ci_upper,
          p_fmt    = t$p_value_fmt,
          stringsAsFactors = FALSE
        )
      },

      mysterycall_poisson_model = ,
      mysterycall_nb_model = {
        t     <- m$irr_table
        p_fmt <- if ("p_value_fmt" %in% names(t)) {
          t$p_value_fmt
        } else {
          ifelse(
            t$p_value < 0.001,
            "< 0.001",
            sprintf("%.3f", t$p_value)
          )
        }
        data.frame(
          term     = t$term,
          est      = t$irr,
          ci_lower = t$ci_lower,
          ci_upper = t$ci_upper,
          p_fmt    = p_fmt,
          stringsAsFactors = FALSE
        )
      },

      mysterycall_lmm = {
        t <- m$coef_table
        data.frame(
          term     = t$term,
          est      = t$estimate,
          ci_lower = t$ci_lower,
          ci_upper = t$ci_upper,
          p_fmt    = t$p_value_fmt,
          stringsAsFactors = FALSE
        )
      }
    )
  }

  tbls <- Map(.extract, models, model_types)

  # --------------------------------------------------------------------------
  # Collect factor_refs across models; first-occurrence wins per variable
  # --------------------------------------------------------------------------
  .get_refs <- function(m) {
    refs <- m$factor_refs
    if (is.null(refs) || !length(refs)) list() else refs
  }

  refs_list <- lapply(models, .get_refs)

  all_factor_refs <- list()
  for (r in refs_list) {
    for (vn in names(r)) {
      if (is.null(all_factor_refs[[vn]])) {
        all_factor_refs[[vn]] <- r[[vn]]
      }
    }
  }

  # Per-model reference terms as character, e.g. "insuranceBCBS"
  ref_terms_per_model <- lapply(refs_list, function(r) {
    if (!length(r)) return(character(0L))
    vapply(names(r), function(vn) paste0(vn, r[[vn]]), character(1L),
           USE.NAMES = FALSE)
  })

  # --------------------------------------------------------------------------
  # Union of coefficient terms across all models
  # --------------------------------------------------------------------------
  coef_terms <- unique(unlist(lapply(tbls, `[[`, "term")))

  if (!include_intercept) {
    coef_terms <- coef_terms[coef_terms != "(Intercept)"]
  }

  # Insert reference-category rows at the correct positions
  all_terms <- .mmt_insert_ref_terms(coef_terms, all_factor_refs,
                                     include_intercept = include_intercept)

  # --------------------------------------------------------------------------
  # Format helpers
  # --------------------------------------------------------------------------
  .fmt <- function(v) {
    formatC(round(v, digits), format = "f", digits = digits)
  }

  .fmt_cell <- function(est, lo, hi, p) {
    body <- sprintf("%s (%s to %s)", .fmt(est), .fmt(lo), .fmt(hi))
    sep <- if (cell_layout == "inline") ", p=" else "\np="
    paste0(body, sep, p)
  }

  # --------------------------------------------------------------------------
  # Build per-model character columns
  # --------------------------------------------------------------------------
  model_cols <- lapply(seq_along(models), function(i) {
    tbl_i       <- tbls[[i]]
    ref_terms_i <- ref_terms_per_model[[i]]
    vapply(all_terms, function(trm) {
      if (trm %in% ref_terms_i) {
        return(ref_symbol)
      }
      idx <- which(tbl_i$term == trm)
      if (!length(idx)) return("")
      row <- tbl_i[idx[[1L]], ]
      .fmt_cell(row$est, row$ci_lower, row$ci_upper, row$p_fmt)
    }, character(1L), USE.NAMES = FALSE)
  })

  # --------------------------------------------------------------------------
  # Assemble output data.frame
  # --------------------------------------------------------------------------
  out <- data.frame(
    Term = all_terms,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  for (i in seq_along(models)) {
    out[[col_names[[i]]]] <- model_cols[[i]]
  }

  # --------------------------------------------------------------------------
  # Footer row: N
  # --------------------------------------------------------------------------
  if (include_n) {
    r <- nrow(out) + 1L
    out[r, "Term"] <- "N"
    for (i in seq_along(models)) {
      m <- models[[i]]
      out[r, col_names[[i]]] <- if (!is.null(m$n)) as.character(m$n) else ""
    }
  }

  # --------------------------------------------------------------------------
  # Footer row: AIC
  # --------------------------------------------------------------------------
  if (include_aic) {
    r <- nrow(out) + 1L
    out[r, "Term"] <- "AIC"
    for (i in seq_along(models)) {
      m  <- models[[i]]
      mt <- model_types[[i]]

      # AIC is not meaningful for REML-fitted LMMs
      if (identical(mt, "mysterycall_lmm") && isTRUE(m$REML)) {
        out[r, col_names[[i]]] <- "(REML)"
        next
      }

      aic_val <- if (!is.null(m$aic)) {
        m$aic
      } else {
        tryCatch(
          stats::AIC(m$model),
          error = function(e) NA_real_
        )
      }

      out[r, col_names[[i]]] <- if (!is.na(aic_val)) {
        formatC(round(aic_val, 1L), format = "f", digits = 1L)
      } else {
        ""
      }
    }
  }

  # --------------------------------------------------------------------------
  # Attach metadata and return
  # --------------------------------------------------------------------------
  attr(out, "estimate_label") <- estimate_col_label
  attr(out, "mixed_types")    <- mixed
  class(out) <- c("mysterycall_multi_model_table", "data.frame")
  out
}


# ---------------------------------------------------------------------------
# Internal helper: insert reference-category rows at the correct position
# ---------------------------------------------------------------------------

#' @keywords internal
.mmt_insert_ref_terms <- function(coef_terms, factor_refs,
                                  include_intercept = FALSE) {
  if (!length(factor_refs)) return(coef_terms)

  result <- coef_terms

  for (vn in names(factor_refs)) {
    ref_val  <- factor_refs[[vn]]
    ref_term <- paste0(vn, ref_val)

    if (!include_intercept && identical(ref_term, "(Intercept)")) next
    if (ref_term %in% result) next   # already present; skip

    # Find the first coefficient term that starts with this variable name
    matches <- which(startsWith(result, vn))
    if (!length(matches)) next       # variable absent from all model outputs

    ins_pos <- matches[[1L]]
    result  <- c(
      result[seq_len(ins_pos - 1L)],
      ref_term,
      result[seq(ins_pos, length(result))]
    )
  }
  result
}


# ---------------------------------------------------------------------------
# Print method
# ---------------------------------------------------------------------------

#' Print a mysterycall_multi_model_table
#'
#' Displays the multi-model regression table in the console. The embedded
#' newline between the estimate and p-value in each cell is replaced with
#' \code{" | "} for compact, readable console output.
#'
#' @param x A \code{mysterycall_multi_model_table} object.
#' @param ... Ignored; present for S3 consistency.
#' @return \code{invisible(x)}.
#' @family manuscript
#' @export
print.mysterycall_multi_model_table <- function(x, ...) {
  lbl   <- attr(x, "estimate_label")
  mixed <- isTRUE(attr(x, "mixed_types"))

  cat(sprintf("Multi-model regression table  [%s]\n", lbl))
  if (mixed) {
    cat("Note: columns use their native scales (OR / IRR / Beta).\n")
  }
  cat(strrep("-", 60L), "\n")

  # Replace embedded newlines with " | " for console readability
  disp <- as.data.frame(
    lapply(x, function(col) gsub("\n", " | ", col, fixed = TRUE)),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  print.data.frame(disp, row.names = FALSE, right = FALSE)
  cat(strrep("-", 60L), "\n")
  invisible(x)
}
