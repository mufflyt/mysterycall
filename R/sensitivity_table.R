#' Side-by-side sensitivity table of exposure-term estimates across models
#'
#' @name mysterycall_sensitivity_table
NULL

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

#' Format a raw p-value for a sensitivity-table cell
#' @noRd
.fmt_st_pval <- function(p) {
  if (is.null(p) || length(p) == 0L || is.na(p)) return(NA_character_)
  if (p < 0.001) "< 0.001" else sprintf("%.3f", p)
}

#' Extract one exposure-term row from a fitted mysterycall model
#'
#' Returns a list with elements `cell` (formatted character string),
#' `n` (integer), `aic` (numeric), and `type` (label such as "OR", "IRR",
#' or "beta").
#'
#' @param model A `mysterycall_logistic_model`, `mysterycall_poisson_model`,
#'   `mysterycall_nb_model`, or `mysterycall_lmm` object.
#' @param exposure_term Character scalar. Term name to look up.
#' @param digits Integer. Decimal places for estimates and CIs.
#' @keywords internal
.extract_st_row <- function(model, exposure_term, digits) {

  fmt <- function(v) formatC(round(as.numeric(v), digits), format = "f", digits = digits)
  na_row <- function(type, n, aic) {
    list(cell = "\u2014", n = n, aic = aic, type = type)
  }

  if (inherits(model, "mysterycall_logistic_model")) {
    tbl  <- model$or_table
    idx  <- which(as.character(tbl$term) == exposure_term)
    n    <- model$n
    aic  <- model$aic
    if (!length(idx)) return(na_row("OR", n, aic))
    r    <- tbl[idx[[1L]], ]
    pf   <- tryCatch(as.character(r$p_value_fmt[[1L]]), error = function(e) NULL)
    if (is.null(pf) || is.na(pf) || !nzchar(pf))
      pf <- .fmt_st_pval(r$p_value[[1L]])
    list(
      cell = sprintf("%s (%s to %s), p=%s",
                     fmt(r$or[[1L]]), fmt(r$ci_lower[[1L]]),
                     fmt(r$ci_upper[[1L]]), pf),
      n    = n, aic = aic, type = "OR"
    )

  } else if (inherits(model, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    tbl  <- model$irr_table
    idx  <- which(as.character(tbl$term) == exposure_term)
    n    <- model$n
    aic  <- model$aic
    if (!length(idx)) return(na_row("IRR", n, aic))
    r    <- tbl[idx[[1L]], ]
    pf   <- tryCatch(as.character(r$p_value_fmt[[1L]]), error = function(e) NULL)
    if (is.null(pf) || is.na(pf) || !nzchar(pf))
      pf <- .fmt_st_pval(r$p_value[[1L]])
    list(
      cell = sprintf("%s (%s to %s), p=%s",
                     fmt(r$irr[[1L]]), fmt(r$ci_lower[[1L]]),
                     fmt(r$ci_upper[[1L]]), pf),
      n    = n, aic = aic, type = "IRR"
    )

  } else if (inherits(model, "mysterycall_lmm")) {
    tbl  <- model$coef_table
    idx  <- which(as.character(tbl$term) == exposure_term)
    n    <- model$n
    aic  <- model$aic
    if (!length(idx)) return(na_row("beta", n, aic))
    r    <- tbl[idx[[1L]], ]
    pf   <- tryCatch(as.character(r$p_value_fmt[[1L]]), error = function(e) NULL)
    if (is.null(pf) || is.na(pf) || !nzchar(pf))
      pf <- .fmt_st_pval(r$p_value[[1L]])
    list(
      cell = sprintf("%s (%s to %s), p=%s",
                     fmt(r$estimate[[1L]]), fmt(r$ci_lower[[1L]]),
                     fmt(r$ci_upper[[1L]]), pf),
      n    = n, aic = aic, type = "beta"
    )

  } else {
    stop(sprintf(
      "Unsupported model class: '%s'. Must be one of: mysterycall_logistic_model, ",
      "mysterycall_poisson_model, mysterycall_nb_model, mysterycall_lmm.",
      paste(class(model), collapse = ", ")
    ), call. = FALSE)
  }
}


# ---------------------------------------------------------------------------
# Main exported function
# ---------------------------------------------------------------------------

#' Side-by-side sensitivity table comparing the exposure term across models
#'
#' Produces a classic "3-column regression table" (Model 1 unadjusted /
#' Model 2 adjusted / Model 3 + interaction) in which each column shows the
#' **key exposure term's** odds ratio (OR), incidence rate ratio (IRR), or
#' linear coefficient (beta) together with its 95% confidence interval and
#' p-value. Optional footer rows report sample size and AIC for each model.
#'
#' This function is intentionally distinct from
#' [mysterycall_model_comparison_table()], which compares overall model fit
#' statistics (AIC, BIC, phi). Here the emphasis is on **how the exposure
#' effect estimate changes** as covariates are added or the analytic
#' specification varies -- the classic sensitivity/robustness check for a
#' primary manuscript table.
#'
#' @param models Named list of fitted model objects. Every element must be one
#'   of: `mysterycall_logistic_model`, `mysterycall_poisson_model`,
#'   `mysterycall_nb_model`, or `mysterycall_lmm`. Mixed model types are
#'   permitted (e.g. a logistic model alongside a Poisson model). At least one
#'   model is required.
#' @param exposure_term Character scalar. The exact term name to extract from
#'   each model's coefficient table (e.g. `"insuranceMedicaid"`,
#'   `"scenarioB"`). Must match the `term` column produced by the fitting
#'   function. When a model does not contain the term an em-dash (`"--"`)
#'   is placed in that column.
#' @param digits Integer. Number of decimal places for estimates and
#'   confidence interval bounds. Default `2L`.
#' @param include_n Logical. When `TRUE` (default) a "Sample size" row is
#'   appended at the bottom showing `N=<n>` for each model.
#' @param include_aic Logical. When `TRUE` (default) an "AIC" row is appended
#'   at the bottom showing the Akaike Information Criterion to one decimal
#'   place for each model. Note: AIC from models fitted with `REML = TRUE`
#'   (`mysterycall_lmm`) is not directly comparable to ML-fitted AIC.
#'
#' @return A `data.frame` with columns:
#' \describe{
#'   \item{`Characteristic`}{Row label: the exposure term (with metric type
#'     in parentheses), then optionally "Sample size" and "AIC".}
#'   \item{`<model name>`}{One column per element of `models`, named by the
#'     list element name. The exposure row shows `"1.23 (0.98-1.54), p=0.071"`.
#'     The footer rows show `"N=160"` and `"210.4"` respectively. An em-dash
#'     is used when a term is absent from a model.}
#' }
#' The data frame is suitable for passing directly to `knitr::kable()`,
#' `flextable::flextable()`, or `gt::gt()` for Word/HTML output.
#'
#' @section Cell format:
#' Each exposure-row cell follows the pattern:
#' \preformatted{<estimate> (<ci_lower>-<ci_upper>), p=<p_value>}
#' where `estimate` is:
#' \itemize{
#'   \item **OR** for `mysterycall_logistic_model` (exponentiated log-odds)
#'   \item **IRR** for `mysterycall_poisson_model` or `mysterycall_nb_model`
#'     (exponentiated log-rate)
#'   \item **beta** for `mysterycall_lmm` (coefficient in outcome units, e.g.
#'     days)
#' }
#' The metric label is appended to the `Characteristic` entry in parentheses
#' when all models share the same type; otherwise the bare term is used and
#' readers should consult footnotes.
#'
#' @section Typical workflow:
#' \enumerate{
#'   \item Fit a series of models of increasing complexity.
#'   \item Call `mysterycall_sensitivity_table()` with those models and the
#'     primary exposure term.
#'   \item Pass the result to `flextable::flextable()` or `knitr::kable()`
#'     and insert into the manuscript.
#' }
#'
#' @family manuscript
#' @seealso
#'   [mysterycall_model_comparison_table()] for AIC/BIC/phi comparison;
#'   [mysterycall_logistic_model()] for the logistic model;
#'   [mysterycall_poisson_model()] for the Poisson model;
#'   [mysterycall_nb_model()] for the negative binomial model;
#'   [mysterycall_lmm()] for the linear mixed model.
#' @export
#'
#' @examples
#' # ---- Build fake model objects with structure() -- no lme4 required --------
#'
#' # Model 1: unadjusted logistic (only insurance)
#' m1 <- structure(
#'   list(
#'     or_table = data.frame(
#'       term        = c("(Intercept)", "insuranceMedicaid"),
#'       or          = c(3.50, 0.62),
#'       ci_lower    = c(2.10, 0.40),
#'       ci_upper    = c(5.80, 0.97),
#'       p_value     = c(0.0001, 0.036),
#'       p_value_fmt = c("< 0.001", "0.036"),
#'       stringsAsFactors = FALSE
#'     ),
#'     n   = 160L,
#'     aic = 210.4
#'   ),
#'   class = "mysterycall_logistic_model"
#' )
#'
#' # Model 2: adjusted (insurance + practice setting)
#' m2 <- structure(
#'   list(
#'     or_table = data.frame(
#'       term        = c("(Intercept)", "insuranceMedicaid", "settingAcademic"),
#'       or          = c(3.20, 0.65, 1.18),
#'       ci_lower    = c(1.80, 0.42, 0.79),
#'       ci_upper    = c(5.70, 1.01, 1.77),
#'       p_value     = c(0.0003, 0.055, 0.417),
#'       p_value_fmt = c("< 0.001", "0.055", "0.417"),
#'       stringsAsFactors = FALSE
#'     ),
#'     n   = 160L,
#'     aic = 208.1
#'   ),
#'   class = "mysterycall_logistic_model"
#' )
#'
#' # Model 3: adjusted + insurance x setting interaction
#' m3 <- structure(
#'   list(
#'     or_table = data.frame(
#'       term        = c("(Intercept)", "insuranceMedicaid",
#'                       "settingAcademic",
#'                       "insuranceMedicaid:settingAcademic"),
#'       or          = c(3.10, 0.68, 1.21, 0.85),
#'       ci_lower    = c(1.70, 0.43, 0.80, 0.51),
#'       ci_upper    = c(5.60, 1.07, 1.84, 1.42),
#'       p_value     = c(0.0005, 0.094, 0.371, 0.530),
#'       p_value_fmt = c("< 0.001", "0.094", "0.371", "0.530"),
#'       stringsAsFactors = FALSE
#'     ),
#'     n   = 160L,
#'     aic = 209.7
#'   ),
#'   class = "mysterycall_logistic_model"
#' )
#'
#' tbl <- mysterycall_sensitivity_table(
#'   models        = list("Unadjusted" = m1,
#'                        "Adjusted"   = m2,
#'                        "+ Interaction" = m3),
#'   exposure_term = "insuranceMedicaid",
#'   digits        = 2L
#' )
#' print(tbl)
#'
#' # ---- Mixed model types: logistic + Poisson side by side -------------------
#' m_poisson <- structure(
#'   list(
#'     irr_table = data.frame(
#'       term        = c("(Intercept)", "insuranceMedicaid"),
#'       irr         = c(18.3, 1.41),
#'       ci_lower    = c(14.1, 1.08),
#'       ci_upper    = c(23.7, 1.84),
#'       p_value     = c(0.0001, 0.012),
#'       p_value_fmt = c("< 0.001", "0.012"),
#'       stringsAsFactors = FALSE
#'     ),
#'     n   = 145L,
#'     aic = 893.6
#'   ),
#'   class = "mysterycall_poisson_model"
#' )
#'
#' tbl2 <- mysterycall_sensitivity_table(
#'   models        = list("Offered appt (OR)" = m2,
#'                        "Wait days (IRR)"   = m_poisson),
#'   exposure_term = "insuranceMedicaid",
#'   digits        = 2L
#' )
#' print(tbl2)
mysterycall_sensitivity_table <- function(models,
                                           exposure_term,
                                           digits      = 2L,
                                           include_n   = TRUE,
                                           include_aic = TRUE) {

  # -- Input validation ----------------------------------------------------------
  if (!is.list(models) || is.null(names(models)) || length(models) < 1L)
    stop("`models` must be a named list with at least one element.", call. = FALSE)

  if (!is.character(exposure_term) || length(exposure_term) != 1L ||
      is.na(exposure_term) || !nzchar(trimws(exposure_term)))
    stop("`exposure_term` must be a non-empty character scalar.", call. = FALSE)

  digits <- as.integer(digits)[[1L]]
  if (is.na(digits) || digits < 0L)
    stop("`digits` must be a non-negative integer scalar.", call. = FALSE)

  if (!is.logical(include_n)   || length(include_n)   != 1L || is.na(include_n))
    stop("`include_n` must be a single non-missing logical value.", call. = FALSE)
  if (!is.logical(include_aic) || length(include_aic) != 1L || is.na(include_aic))
    stop("`include_aic` must be a single non-missing logical value.", call. = FALSE)

  valid_classes <- c("mysterycall_logistic_model",
                     "mysterycall_poisson_model",
                     "mysterycall_nb_model",
                     "mysterycall_lmm")

  bad <- vapply(names(models), function(nm) {
    !inherits(models[[nm]], valid_classes)
  }, logical(1L))
  if (any(bad)) {
    stop(sprintf(
      "Model(s) with unsupported class: %s. Each must be one of: %s.",
      paste(names(models)[bad], collapse = ", "),
      paste(valid_classes, collapse = ", ")
    ), call. = FALSE)
  }

  # -- Extract exposure-term row from every model --------------------------------
  extracted <- lapply(models, .extract_st_row,
                      exposure_term = exposure_term,
                      digits        = digits)

  model_nms <- names(models)
  cells     <- vapply(extracted, `[[`, character(1L), "cell")
  types     <- vapply(extracted, `[[`, character(1L), "type")

  # Determine Characteristic label for the exposure row
  unique_types <- unique(types)
  if (length(unique_types) == 1L) {
    row_label <- sprintf("%s (%s)", exposure_term, unique_types)
  } else {
    # Heterogeneous \u2014 append per-model type inside the model column names
    # (model names already carry context); keep the Characteristic bare
    row_label <- exposure_term
  }

  # -- Assemble rows -------------------------------------------------------------
  rows <- list(
    stats::setNames(c(row_label, cells), c("Characteristic", model_nms))
  )

  if (include_n) {
    ns <- vapply(extracted, function(e) {
      v <- e$n
      if (is.null(v) || length(v) == 0L || is.na(v)) return("\u2014")
      sprintf("N=%d", as.integer(v))
    }, character(1L))
    rows <- c(rows,
              list(stats::setNames(c("Sample size", ns),
                                   c("Characteristic", model_nms))))
  }

  if (include_aic) {
    aics <- vapply(extracted, function(e) {
      v <- e$aic
      if (is.null(v) || length(v) == 0L || is.na(v) || !is.finite(v))
        return("\u2014")
      sprintf("%.1f", v)
    }, character(1L))
    rows <- c(rows,
              list(stats::setNames(c("AIC", aics),
                                   c("Characteristic", model_nms))))
  }

  # -- Build data.frame ----------------------------------------------------------
  out <- as.data.frame(
    do.call(rbind, rows),
    stringsAsFactors = FALSE,
    check.names      = FALSE
  )
  rownames(out) <- NULL

  out
}
