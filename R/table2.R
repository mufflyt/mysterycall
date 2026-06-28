#' Build a two-panel manuscript Table 2
#'
#' Combines appointment acceptance rates (Panel A) with model-based incidence
#' rate ratios and optional absolute day differences (Panel B) into a single
#' structured object ready for publication or export.
#'
#' @param data A data frame containing raw study observations.
#' @param model_result A `mysterycall_poisson_model` or `mysterycall_nb_model`
#'   object.
#' @param group_col Character scalar. Column name defining the comparison groups
#'   (e.g. `"insurance"`). Must be in `names(data)`.
#' @param accepted_col Character scalar. Column name encoding whether the call
#'   resulted in an appointment offer. Default `"contact_office"`. Values
#'   recognised as accepted: `"Yes"`, `"yes"`, `TRUE`, `1`.
#' @param baseline_mean Numeric scalar or `NULL`. Reference-group mean wait days
#'   used to compute absolute day differences (passed to
#'   [mysterycall_irr_to_days()]). When `NULL`, the `Days` columns are omitted.
#' @param exposure_col Character scalar or `NULL`. Name of the exposure variable
#'   whose terms to extract from the model (e.g. `"insurance"`). Forwarded to
#'   [mysterycall_irr_to_days()].
#' @param ref_group Character scalar or `NULL`. Label of the reference group
#'   used in manuscript sentences. Forwarded to [mysterycall_irr_to_days()].
#' @param digits Integer. Decimal places for IRR and CI values. Default `2L`.
#' @param include_intercept Logical. Whether to include the intercept row in
#'   the model-estimates panel. Default `FALSE`.
#'
#' @return A list of class `mysterycall_table2` with elements:
#' \describe{
#'   \item{`acceptance`}{Data frame (Panel A). Columns: `Group`, `N`,
#'     `Accepted, n (%)`, `95% CI`.}
#'   \item{`estimates`}{Data frame (Panel B). Columns: `Term`, `IRR`, `IRR 95% CI`,
#'     `p-value`, and (when `baseline_mean` is supplied) `Days Diff`,
#'     `Days 95% CI`.}
#'   \item{`notes`}{Character vector of standard footnotes.}
#' }
#'
#' @family manuscript
#' @seealso [mysterycall_acceptance_rate()] for acceptance-rate computation;
#'   [mysterycall_format_results_table()] for IRR formatting;
#'   [mysterycall_irr_to_days()] for absolute day conversion.
#' @export
#'
#' @examplesIf interactive()
#' tbl2 <- mysterycall_table2(
#'   data         = study_data,
#'   model_result = fitted_model,
#'   group_col    = "insurance",
#'   baseline_mean = 21,
#'   exposure_col  = "insurance",
#'   ref_group     = "BCBS"
#' )
#' print(tbl2)
mysterycall_table2 <- function(data,
                                model_result,
                                group_col,
                                accepted_col      = "contact_office",
                                baseline_mean     = NULL,
                                exposure_col      = NULL,
                                ref_group         = NULL,
                                digits            = 2L,
                                include_intercept = FALSE) {

  if (!is.data.frame(data))
    stop(sprintf("`data` must be a data frame, not %s.", class(data)[1L]), call. = FALSE)
  if (!is.character(group_col) || length(group_col) != 1L)
    stop("`group_col` must be a single character string.", call. = FALSE)
  if (!group_col %in% names(data))
    stop(sprintf("Column '%s' not found in `data`.\nAvailable columns: %s",
                 group_col, paste(names(data), collapse = ", ")), call. = FALSE)
  if (!accepted_col %in% names(data))
    stop(sprintf("Column '%s' not found in `data`.\nAvailable columns: %s",
                 accepted_col, paste(names(data), collapse = ", ")), call. = FALSE)
  if (!inherits(model_result, c("mysterycall_poisson_model", "mysterycall_nb_model")))
    stop("`model_result` must be a `mysterycall_poisson_model` or `mysterycall_nb_model`.",
         call. = FALSE)
  if (!is.null(baseline_mean)) {
    if (!is.numeric(baseline_mean) || length(baseline_mean) != 1L || baseline_mean <= 0)
      stop("`baseline_mean` must be a single positive number.", call. = FALSE)
  }

  # -- Panel A: acceptance rates -----------------------------------------------
  acc_result <- mysterycall_acceptance_rate(
    data         = data,
    accepted_col = accepted_col,
    group_by     = group_col,
    conf_level   = 0.95
  )
  s <- acc_result$summary

  acceptance <- data.frame(
    Group = as.character(s[[group_col]]),
    N     = s$n_total,
    `Accepted, n (%)` = sprintf("%d (%.1f%%)", s$n_accepted, s$rate * 100),
    `95% CI` = sprintf("%.1f%%-%.1f%%", s$ci_lower * 100, s$ci_upper * 100),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  # -- Panel B: model estimates -------------------------------------------------
  irr_tbl <- mysterycall_format_results_table(
    model_result,
    digits            = digits,
    include_intercept = include_intercept
  )

  sig_rows <- attr(irr_tbl, "significant_rows")

  estimates <- data.frame(
    Term         = irr_tbl$Term,
    IRR          = irr_tbl$IRR,
    `IRR 95% CI` = irr_tbl[["95% CI"]],
    `p-value`    = irr_tbl[["p-value"]],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  attr(estimates, "significant_rows") <- sig_rows

  if (!is.null(baseline_mean)) {
    days_obj <- mysterycall_irr_to_days(
      model_result,
      baseline_mean = baseline_mean,
      exposure_col  = exposure_col,
      ref_group     = ref_group,
      digits        = 1L
    )
    dt <- days_obj$table

    raw_terms <- if (inherits(model_result, c("mysterycall_poisson_model",
                                               "mysterycall_nb_model"))) {
      model_result$irr_table$term
    } else {
      model_result$term
    }
    if (!include_intercept) {
      raw_terms <- raw_terms[raw_terms != "(Intercept)"]
    }

    days_diff_col <- character(nrow(estimates))
    days_ci_col   <- character(nrow(estimates))

    for (i in seq_len(nrow(estimates))) {
      m <- match(raw_terms[i], dt$term)
      if (!is.na(m)) {
        d  <- dt[m, ]
        sign_str <- if (d$days_diff >= 0) "+" else ""
        days_diff_col[i] <- sprintf("%s%.1f", sign_str, d$days_diff)
        lo  <- d$days_ci_lower
        hi  <- d$days_ci_upper
        days_ci_col[i]   <- sprintf("%.1f to %.1f", lo, hi)
      } else {
        days_diff_col[i] <- NA_character_
        days_ci_col[i]   <- NA_character_
      }
    }
    estimates[["Days Diff"]]   <- days_diff_col
    estimates[["Days 95% CI"]] <- days_ci_col
  }

  # -- Notes -------------------------------------------------------------------
  notes <- c(
    "IRR = incidence rate ratio; CI = confidence interval.",
    "Model estimates derived from multilevel regression with physician random intercepts.",
    if (!is.null(baseline_mean))
      sprintf("Days difference computed relative to reference-group mean of %.1f days.",
              baseline_mean)
  )

  structure(
    list(
      acceptance = acceptance,
      estimates  = estimates,
      notes      = notes
    ),
    class = "mysterycall_table2"
  )
}


#' Print method for mysterycall_table2
#'
#' @param x A `mysterycall_table2` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family manuscript
#' @export
print.mysterycall_table2 <- function(x, ...) {
  cat("Panel A: Appointment Acceptance\n")
  cat(strrep("-", 50L), "\n")
  print(x$acceptance, row.names = FALSE)
  cat("\nPanel B: Model Estimates\n")
  cat(strrep("-", 50L), "\n")
  print(x$estimates, row.names = FALSE)
  if (length(x$notes)) {
    cat("\nNotes:\n")
    for (n in x$notes) cat(" ", n, "\n")
  }
  invisible(x)
}
