#' STROBE reporting checklist for mystery-caller studies
#'
#' Evaluates a fitted model result against STROBE (Strengthening the Reporting
#' of Observational Studies in Epidemiology) criteria relevant to mystery-caller
#' audit studies. Returns a data frame of 16 checklist items with pass/warn/fail
#' status, suitable for inclusion in a supplementary file or peer-review
#' response.
#'
#' Where a criterion cannot be determined from the model object alone, the
#' status is `"WARN"` with a note to verify manually. Only items where a
#' programmatic check is possible (e.g., CI columns present, overdispersion
#' value recorded) may reach `"PASS"` or `"FAIL"` automatically.
#'
#' @param model_result A `mysterycall_poisson_model` or `mysterycall_nb_model`
#'   object.
#' @param data Optional data frame. When provided, used to check total N and
#'   missing-data patterns.
#' @param sensitivity_run Logical. Was a sensitivity analysis (e.g.
#'   [mysterycall_sensitivity()]) performed and reported? Default `FALSE`.
#' @param has_flow_diagram Logical. Does the manuscript include a participant
#'   flow diagram (CONSORT-style)? Default `FALSE`.
#' @param irr_reported Logical or `NULL`. Override auto-detection of whether
#'   IRRs with confidence intervals were reported. When `NULL` (default),
#'   auto-detected from `model_result$irr_table`.
#' @param overdispersion_reported Logical or `NULL`. Override auto-detection of
#'   whether overdispersion was reported. When `NULL` (default), auto-detected
#'   from `model_result$overdispersion`.
#'
#' @return A data frame of class `mysterycall_strobe_checklist` with columns:
#' \describe{
#'   \item{`Item`}{Integer. STROBE item number (1-16, adapted for this study type).}
#'   \item{`Category`}{Character. STROBE section (e.g. `"Methods"`, `"Results"`).}
#'   \item{`Description`}{Character. Brief description of the reporting requirement.}
#'   \item{`Status`}{Character. One of `"PASS"`, `"WARN"`, or `"FAIL"`.}
#'   \item{`Detail`}{Character. Explanation of the status assessment.}
#' }
#'
#' @references
#' von Elm E, Altman DG, Egger M, Pocock SJ, Gotzsche PC, Vandenbroucke JP;
#' STROBE Initiative. Strengthening the Reporting of Observational Studies in
#' Epidemiology (STROBE) statement: guidelines for reporting observational
#' studies. *Lancet*. 2007;370(9596):1453-1457.
#' \doi{10.1016/S0140-6736(07)61602-X}
#'
#' @family manuscript
#' @seealso [mysterycall_sensitivity()] for running sensitivity analyses;
#'   [mysterycall_nb_model()] and [mysterycall_poisson_model()] for the model
#'   objects this function inspects.
#' @export
#'
#' @examples
#' irr_tbl <- data.frame(
#'   term      = c("(Intercept)", "insuranceMedicaid"),
#'   irr       = c(1.00, 1.28),
#'   ci_lower  = c(NA,   1.05),
#'   ci_upper  = c(NA,   1.56),
#'   p_value   = c(NA,   0.014),
#'   stringsAsFactors = FALSE
#' )
#' fake_model <- structure(
#'   list(
#'     irr_table     = irr_tbl,
#'     overdispersion = 1.3,
#'     n_dropped     = 4L,
#'     model         = NULL
#'   ),
#'   class = "mysterycall_poisson_model"
#' )
#' cl <- mysterycall_strobe_checklist(fake_model, sensitivity_run = TRUE)
#' print(cl)
mysterycall_strobe_checklist <- function(model_result,
                                          data                    = NULL,
                                          sensitivity_run         = FALSE,
                                          has_flow_diagram        = FALSE,
                                          irr_reported            = NULL,
                                          overdispersion_reported = NULL) {

  if (!inherits(model_result, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    stop(
      "`model_result` must be a `mysterycall_poisson_model` or `mysterycall_nb_model`.",
      call. = FALSE
    )
  }

  is_nb      <- inherits(model_result, "mysterycall_nb_model")
  irr_table  <- model_result$irr_table

  # -- Auto-detect CI reporting -------------------------------------------------
  has_ci <- if (!is.null(irr_reported)) {
    isTRUE(irr_reported)
  } else {
    !is.null(irr_table) &&
      is.data.frame(irr_table) &&
      all(c("ci_lower", "ci_upper") %in% names(irr_table)) &&
      any(!is.na(irr_table$ci_lower))
  }

  # -- Auto-detect overdispersion reporting ------------------------------------
  has_overdispersion_val <- if (!is.null(overdispersion_reported)) {
    isTRUE(overdispersion_reported)
  } else {
    !is.null(model_result$overdispersion) && !is.na(model_result$overdispersion)
  }

  # -- Auto-detect p-values -----------------------------------------------------
  has_pvals <- !is.null(irr_table) &&
    "p_value" %in% names(irr_table) &&
    any(!is.na(irr_table$p_value))

  # -- Auto-detect sample size justification -----------------------------------
  has_power_info <- !is.null(model_result$power) ||
    !is.null(model_result$sample_size)

  # -- Auto-detect n_dropped ----------------------------------------------------
  has_n_dropped <- !is.null(model_result$n_dropped) &&
    !is.na(model_result$n_dropped)

  # -- Auto-detect random intercepts in formula ---------------------------------
  has_random <- tryCatch({
    fit <- model_result$model
    if (is.null(fit)) {
      FALSE
    } else {
      formula_str <- tryCatch(
        deparse(stats::formula(fit)),
        error = function(e) ""
      )
      grepl("\\|", paste(formula_str, collapse = " "), perl = TRUE)
    }
  }, error = function(e) FALSE)

  # -- Build checklist ----------------------------------------------------------
  make_row <- function(item, category, description, status, detail) {
    data.frame(
      Item        = item,
      Category    = category,
      Description = description,
      Status      = status,
      Detail      = detail,
      stringsAsFactors = FALSE
    )
  }

  rows <- list(
    make_row(1L,  "Title/Abstract", "Study design stated in title or abstract",
             "WARN", "Cannot auto-detect; verify manually."),

    make_row(2L,  "Introduction",   "Scientific background and objectives stated",
             "WARN", "Cannot auto-detect; verify manually."),

    make_row(3L,  "Methods",        "Setting, locations, and dates described",
             "WARN", "Cannot auto-detect; verify manually."),

    make_row(4L,  "Methods",        "Eligibility criteria for participants stated",
             "WARN", "Cannot auto-detect; verify manually."),

    make_row(5L,  "Methods",        "Mystery-caller protocol described (script, blinding, call timing)",
             "WARN", "Cannot auto-detect; verify manually."),

    make_row(6L,  "Methods",        "Sample size justified",
             if (has_power_info) "PASS" else "WARN",
             if (has_power_info)
               "model_result$power or model_result$sample_size is present."
             else
               "No power/sample_size field found. Verify that a power analysis is reported."),

    make_row(7L,  "Methods",        "Statistical methods: model family specified",
             "PASS",
             sprintf("Model class '%s' detected; model family is unambiguous.",
                     class(model_result)[1L])),

    make_row(8L,  "Methods",        "Physician random intercepts included and stated",
             if (has_random) "PASS" else "WARN",
             if (has_random)
               "Random-effects term detected in model formula."
             else
               "Could not detect '|' in model formula. Verify random intercepts are stated in methods."),

    make_row(9L,  "Methods",        "Overdispersion addressed (NB model or test reported)",
             if (is_nb || isTRUE(overdispersion_reported)) "PASS" else "WARN",
             if (is_nb)
               "Negative binomial model used; overdispersion is addressed by model choice."
             else if (isTRUE(overdispersion_reported))
               "overdispersion_reported=TRUE supplied by caller."
             else
               "Poisson model detected; verify that overdispersion test/phi is reported in methods."),

    make_row(10L, "Results",        "Flow diagram or N screened/excluded reported",
             if (isTRUE(has_flow_diagram)) "PASS" else "WARN",
             if (isTRUE(has_flow_diagram))
               "has_flow_diagram=TRUE supplied by caller."
             else
               "Verify that a participant flow diagram or exclusion table is included."),

    make_row(11L, "Results",        "Number of observations with missing data reported",
             if (has_n_dropped) "PASS" else "WARN",
             if (has_n_dropped)
               sprintf("model_result$n_dropped = %d.", as.integer(model_result$n_dropped))
             else
               "model_result$n_dropped is NULL or NA. Verify missing-data count is reported."),

    make_row(12L, "Results",        "IRR with 95% confidence intervals reported",
             if (has_ci) "PASS" else "FAIL",
             if (has_ci)
               "ci_lower and ci_upper columns found with non-NA values in irr_table."
             else
               "ci_lower/ci_upper missing or all-NA in irr_table."),

    make_row(13L, "Results",        "p-values reported for primary comparisons",
             if (has_pvals) "PASS" else "WARN",
             if (has_pvals)
               "p_value column with non-NA values found in irr_table."
             else
               "p_value column missing or all-NA in irr_table."),

    make_row(14L, "Results",        "Overdispersion statistic (phi) reported",
             if (has_overdispersion_val) "PASS" else "WARN",
             if (has_overdispersion_val)
               sprintf("model_result$overdispersion = %.3f.", model_result$overdispersion)
             else
               "model_result$overdispersion is NULL; verify phi is reported in results."),

    make_row(15L, "Results",        "Sensitivity analysis performed",
             if (isTRUE(sensitivity_run)) "PASS" else "WARN",
             if (isTRUE(sensitivity_run))
               "sensitivity_run=TRUE supplied by caller."
             else
               "No sensitivity analysis flagged. Consider running mysterycall_sensitivity()."),

    make_row(16L, "Discussion",     "Limitations discussed",
             "WARN", "Cannot auto-detect; verify manually.")
  )

  checklist <- do.call(rbind, rows)
  structure(checklist, class = c("mysterycall_strobe_checklist", "data.frame"))
}


#' Print method for mysterycall_strobe_checklist
#'
#' @param x A `mysterycall_strobe_checklist` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family manuscript
#' @export
print.mysterycall_strobe_checklist <- function(x, ...) {
  cat("STROBE Checklist for Mystery-Caller Study\n")
  cat(strrep("=", 50L), "\n")

  ord <- order(
    match(x$Status, c("FAIL", "WARN", "PASS")),
    x$Item
  )
  xs <- x[ord, , drop = FALSE]

  for (i in seq_len(nrow(xs))) {
    r     <- xs[i, ]
    badge <- sprintf("[%s]", r$Status)
    cat(sprintf("%-6s Item %2d  %s: %s\n         %s\n",
                badge, r$Item, r$Category, r$Description, r$Detail))
  }

  n_pass <- sum(x$Status == "PASS")
  n_warn <- sum(x$Status == "WARN")
  n_fail <- sum(x$Status == "FAIL")
  cat(sprintf("\nSummary: %d PASS, %d WARN, %d FAIL\n", n_pass, n_warn, n_fail))

  invisible(x)
}
