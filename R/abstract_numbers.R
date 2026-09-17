#' Distil key abstract numbers from fitted model objects
#'
#' @name mysterycall_abstract_numbers
NULL


# -- Internal helpers ----------------------------------------------------------

#' Format a p-value for use inside an abstract sentence
#' @noRd
.fmt_abstract_pval <- function(p, digits) {
  if (is.na(p)) return("")
  mysterycall_format_p(p, digits = digits, name = "p")
}

#' Format a p-value for a named slot (numbers_list / or_p etc.)
#' @noRd
.fmt_slot_pval <- function(p, digits) {
  mysterycall_format_p(p, digits = digits)
}

#' Format estimate + CI as "est (lo-hi)"
#' @noRd
.fmt_est_ci <- function(est, lo, hi, digits) {
  fmt <- paste0("%.", digits, "f")
  sprintf(paste0(fmt, " (", fmt, " to ", fmt, ")"), est, lo, hi)
}

#' Build the full abstract sentence from extracted model numbers
#' @noRd
.build_abstract_sentence <- function(n_total,
                                     comparison_label,
                                     ref_label,
                                     outcome_label,
                                     or, or_lo, or_hi, or_praw,
                                     irr, irr_lo, irr_hi, irr_praw,
                                     beta, beta_lo, beta_hi, beta_praw,
                                     lmm_log,
                                     absolute_gap,
                                     acceptance_rate,
                                     digits_or,
                                     digits_p) {

  has_or   <- !is.na(or)
  has_irr  <- !is.na(irr)
  has_beta <- !is.na(beta)

  model_clauses <- character(0L)

  # -- OR clause ----------------------------------------------------------------
  if (has_or) {
    pct <- round(abs(1 - or) * 100)
    dir <- if (or < 1) "less" else "more"
    model_clauses <- c(model_clauses, sprintf(
      paste0(
        "%s callers were %d%% %s likely to be offered %s ",
        "than %s callers ",
        "(OR %.*f, 95%% CI %.*f-%.*f, %s)"
      ),
      comparison_label, pct, dir, outcome_label, ref_label,
      digits_or, or, digits_or, or_lo, digits_or, or_hi,
      .fmt_abstract_pval(or_praw, digits_p)
    ))
  }

  # -- IRR clause ---------------------------------------------------------------
  if (has_irr) {
    pct <- round(abs(1 - irr) * 100)
    dir <- if (irr < 1) "shorter" else "longer"
    if (!has_or) {
      # IRR is the primary clause
      model_clauses <- c(model_clauses, sprintf(
        paste0(
          "%s callers had %d%% %s wait times than %s callers ",
          "(IRR %.*f, 95%% CI %.*f-%.*f, %s)"
        ),
        comparison_label, pct, dir, ref_label,
        digits_or, irr, digits_or, irr_lo, digits_or, irr_hi,
        .fmt_abstract_pval(irr_praw, digits_p)
      ))
    } else {
      # IRR is secondary, joined with semicolon
      model_clauses <- c(model_clauses, sprintf(
        "wait times were %d%% %s (IRR %.*f, 95%% CI %.*f-%.*f, %s)",
        pct, dir,
        digits_or, irr, digits_or, irr_lo, digits_or, irr_hi,
        .fmt_abstract_pval(irr_praw, digits_p)
      ))
    }
  }

  # -- LMM beta clause ----------------------------------------------------------
  if (has_beta) {
    units    <- if (isTRUE(lmm_log)) "log-days" else "days"
    beta_abs <- abs(beta)
    dir      <- if (beta > 0) "more" else "fewer"
    if (!has_or && !has_irr) {
      # Beta is the primary clause
      model_clauses <- c(model_clauses, sprintf(
        paste0(
          "%s callers had %.*f %s wait %s than %s callers ",
          "(95%% CI %.*f to %.*f, %s)"
        ),
        comparison_label, digits_or, beta_abs, dir, units, ref_label,
        digits_or, beta_lo, digits_or, beta_hi,
        .fmt_abstract_pval(beta_praw, digits_p)
      ))
    } else {
      model_clauses <- c(model_clauses, sprintf(
        "wait time differed by %+.*f %s (95%% CI %.*f to %.*f, %s)",
        digits_or, beta, units,
        digits_or, beta_lo, digits_or, beta_hi,
        .fmt_abstract_pval(beta_praw, digits_p)
      ))
    }
  }

  if (!length(model_clauses)) return(character(0L))

  # -- Join model clauses -------------------------------------------------------
  combined <- paste(model_clauses, collapse = "; ")

  # -- Absolute gap suffix ------------------------------------------------------
  if (!is.na(absolute_gap) && !is.null(acceptance_rate)) {
    gap_pct  <- round(abs(absolute_gap) * 100)
    ref_pct  <- round(acceptance_rate[["ref"]]        * 100)
    comp_pct <- round(acceptance_rate[["comparison"]] * 100)
    combined <- paste0(combined, sprintf(
      ", with an absolute %s gap of %d percentage points (%d%% vs. %d%%)",
      outcome_label, gap_pct, ref_pct, comp_pct
    ))
  }

  paste0(sprintf("Among %d total calls, ", n_total), combined, ".")
}


# -- Main exported function ----------------------------------------------------

#' Distil key abstract numbers from fitted model objects
#'
#' Extracts and formats the 5-6 numbers that go into a manuscript abstract from
#' the fitted model objects produced by [mysterycall_logistic_model()],
#' [mysterycall_poisson_model()], [mysterycall_nb_model()], and
#' [mysterycall_lmm()]. This eliminates manual copy-paste transcription errors
#' when writing abstracts.
#'
#' @param logistic_fit A `mysterycall_logistic_model` object returned by
#'   [mysterycall_logistic_model()], or `NULL`. Provides N, OR, CI, and
#'   p-value for the primary binary outcome (appointment offered).
#' @param poisson_fit A `mysterycall_poisson_model` or `mysterycall_nb_model`
#'   object, or `NULL`. Provides N, IRR, CI, and p-value for wait time.
#' @param lmm_fit A `mysterycall_lmm` object returned by [mysterycall_lmm()],
#'   or `NULL`. Provides N, beta coefficient, CI, and p-value for continuous
#'   wait time. When the LMM was log-transformed (`$log_transformed == TRUE`),
#'   the beta is on the log-days scale and the unit label reflects that.
#' @param exposure_term Character scalar. The exact term name to extract from
#'   each model coefficient table (e.g. `"insuranceMedicaid"`). Must match the
#'   `term` column of `or_table`, `irr_table`, or `coef_table` exactly.
#' @param ref_label Character scalar. Human-readable reference group label used
#'   in the abstract sentence (e.g. `"commercial insurance"`).
#'   Default `"the reference group"`.
#' @param comparison_label Character scalar or `NULL`. Human-readable label for
#'   the comparison group (e.g. `"Medicaid"`). When `NULL` (default), it is
#'   derived from `exposure_term` by stripping the leading run of lowercase
#'   letters (e.g. `"insuranceMedicaid"` becomes `"Medicaid"`).
#' @param outcome_label Character scalar. Human-readable outcome description
#'   used in the abstract sentence. Default `"appointment acceptance"`.
#' @param digits_or Integer. Decimal places for OR, IRR, and beta coefficients.
#'   Default `2L`.
#' @param digits_p Integer. Decimal places for p-values. Default `3L`.
#' @param acceptance_rate Named numeric vector of length 2, or `NULL`.
#'   Should be of the form `c(ref = 0.82, comparison = 0.61)` and provide
#'   the raw acceptance rates for the reference and comparison groups. Used to
#'   compute the absolute percentage-point gap. When `NULL` (default), the
#'   gap is omitted from the sentence.
#'
#' @return A list of class `mysterycall_abstract_numbers` with elements:
#' \describe{
#'   \item{`n_total`}{`integer`. Total calls from the first non-`NULL` fit
#'     (`logistic_fit`, then `poisson_fit`, then `lmm_fit`).}
#'   \item{`or`}{`numeric`. Odds ratio, or `NA_real_` when `logistic_fit`
#'     is `NULL` or `exposure_term` is not found.}
#'   \item{`or_ci`}{`character`. Formatted as `"0.62 (0.41-0.94)"`, or `NA`.}
#'   \item{`or_p`}{`character`. Formatted p-value (e.g. `"0.024"` or
#'     `"< 0.001"`), or `NA`.}
#'   \item{`irr`}{`numeric`. Incidence rate ratio, or `NA_real_`.}
#'   \item{`irr_ci`}{`character` or `NA`.}
#'   \item{`irr_p`}{`character` or `NA`.}
#'   \item{`beta`}{`numeric`. LMM fixed-effect coefficient (days or log-days),
#'     or `NA_real_`.}
#'   \item{`beta_ci`}{`character` or `NA`.}
#'   \item{`beta_p`}{`character` or `NA`.}
#'   \item{`absolute_gap`}{`numeric`. `ref_rate - comparison_rate` in
#'     proportion units, or `NA_real_` when `acceptance_rate` is `NULL`.}
#'   \item{`abstract_sentence`}{`character`. Full abstract-ready sentence
#'     combining all available statistics.}
#'   \item{`numbers_list`}{Named `character` vector of all formatted numbers
#'     suitable for copy-paste into a manuscript.}
#' }
#'
#' @section Abstract sentence structure:
#' The sentence is assembled from available components in this order:
#' \enumerate{
#'   \item Lead: `"Among [N] total calls, "`.
#'   \item OR clause (if `logistic_fit` is non-`NULL`): primary clause.
#'   \item IRR clause (if `poisson_fit` is non-`NULL`): primary clause when
#'     no OR is present; otherwise appended after a semicolon.
#'   \item LMM beta clause (if `lmm_fit` is non-`NULL`): primary clause when
#'     no OR or IRR is present; otherwise appended after a semicolon.
#'   \item Absolute gap suffix (if `acceptance_rate` is non-`NULL`): appended
#'     as `", with an absolute [outcome_label] gap of [X] percentage points
#'     ([ref]% vs. [comparison]%)"`.
#' }
#'
#' @family reporting
#' @seealso [mysterycall_results_paragraph()],
#'   [mysterycall_write_results_paragraph()],
#'   [mysterycall_logistic_model()], [mysterycall_poisson_model()],
#'   [mysterycall_nb_model()], [mysterycall_lmm()]
#' @export
#'
#' @examples
#' # --- Minimal example: logistic fit only -------------------------------------
#' fake_logistic <- structure(
#'   list(
#'     n        = 412L,
#'     or_table = data.frame(
#'       term     = c("(Intercept)", "insuranceMedicaid"),
#'       or       = c(2.10, 0.62),
#'       ci_lower = c(1.20, 0.41),
#'       ci_upper = c(3.68, 0.94),
#'       p_value  = c(0.008, 0.024),
#'       stringsAsFactors = FALSE
#'     )
#'   ),
#'   class = "mysterycall_logistic_model"
#' )
#'
#' result <- mysterycall_abstract_numbers(
#'   logistic_fit     = fake_logistic,
#'   exposure_term    = "insuranceMedicaid",
#'   ref_label        = "commercial insurance",
#'   comparison_label = "Medicaid",
#'   acceptance_rate  = c(ref = 0.82, comparison = 0.61)
#' )
#' print(result)
#' result$abstract_sentence
#'
#' # --- Extended example: logistic + Poisson fit -------------------------------
#' fake_poisson <- structure(
#'   list(
#'     n         = 298L,
#'     irr_table = data.frame(
#'       term      = c("(Intercept)", "insuranceMedicaid"),
#'       irr       = c(0.95, 1.40),
#'       ci_lower  = c(0.70, 1.12),
#'       ci_upper  = c(1.29, 1.75),
#'       p_value   = c(0.782, 0.003),
#'       stringsAsFactors = FALSE
#'     )
#'   ),
#'   class = "mysterycall_poisson_model"
#' )
#'
#' result2 <- mysterycall_abstract_numbers(
#'   logistic_fit  = fake_logistic,
#'   poisson_fit   = fake_poisson,
#'   exposure_term = "insuranceMedicaid",
#'   ref_label     = "commercial insurance",
#'   acceptance_rate = c(ref = 0.82, comparison = 0.61)
#' )
#' result2$abstract_sentence
mysterycall_abstract_numbers <- function(logistic_fit     = NULL,
                                         poisson_fit      = NULL,
                                         lmm_fit          = NULL,
                                         exposure_term,
                                         ref_label        = "the reference group",
                                         comparison_label = NULL,
                                         outcome_label    = "appointment acceptance",
                                         digits_or        = 2L,
                                         digits_p         = 3L,
                                         acceptance_rate  = NULL) {

  # -- Require at least one model -----------------------------------------------
  if (is.null(logistic_fit) && is.null(poisson_fit) && is.null(lmm_fit)) {
    stop(
      "At least one of `logistic_fit`, `poisson_fit`, or `lmm_fit` must be non-NULL.",
      call. = FALSE
    )
  }

  # -- exposure_term -------------------------------------------------------------
  if (!is.character(exposure_term) || length(exposure_term) != 1L ||
      !nzchar(exposure_term)) {
    stop("`exposure_term` must be a non-empty character scalar.", call. = FALSE)
  }

  # -- Class checks on fit objects ----------------------------------------------
  if (!is.null(logistic_fit) &&
      !inherits(logistic_fit, "mysterycall_logistic_model")) {
    stop(
      "`logistic_fit` must be a `mysterycall_logistic_model` object or NULL.",
      call. = FALSE
    )
  }
  if (!is.null(poisson_fit) &&
      !inherits(poisson_fit, c("mysterycall_poisson_model",
                               "mysterycall_nb_model"))) {
    stop(
      paste0(
        "`poisson_fit` must be a `mysterycall_poisson_model`, ",
        "`mysterycall_nb_model`, or NULL."
      ),
      call. = FALSE
    )
  }
  if (!is.null(lmm_fit) && !inherits(lmm_fit, "mysterycall_lmm")) {
    stop("`lmm_fit` must be a `mysterycall_lmm` object or NULL.", call. = FALSE)
  }

  # -- acceptance_rate ----------------------------------------------------------
  if (!is.null(acceptance_rate)) {
    if (!is.numeric(acceptance_rate) || length(acceptance_rate) != 2L) {
      stop(
        paste0(
          "`acceptance_rate` must be a two-element named numeric vector ",
          "c(ref = ..., comparison = ...) or NULL."
        ),
        call. = FALSE
      )
    }
    if (!all(c("ref", "comparison") %in% names(acceptance_rate))) {
      stop(
        "`acceptance_rate` must be named with elements 'ref' and 'comparison'.",
        call. = FALSE
      )
    }
  }

  digits_or <- as.integer(digits_or)
  digits_p  <- as.integer(digits_p)

  # -- Derive comparison_label --------------------------------------------------
  if (is.null(comparison_label)) {
    derived <- sub("^[a-z_\\.]+", "", exposure_term, perl = TRUE)
    comparison_label <- if (nzchar(derived)) derived else exposure_term
  }

  # -- Extract n_total ----------------------------------------------------------
  n_total <- as.integer(
    if (!is.null(logistic_fit)) {
      logistic_fit$n
    } else if (!is.null(poisson_fit)) {
      poisson_fit$n
    } else {
      lmm_fit$n
    }
  )

  # -- Helper: extract one row from a table by term -----------------------------
  .extract_row <- function(tbl, term, label) {
    row <- tbl[tbl$term == term, , drop = FALSE]
    if (!nrow(row)) {
      warning(
        sprintf(
          "exposure_term '%s' not found in %s. Result will be NA.",
          term, label
        ),
        call. = FALSE
      )
      return(NULL)
    }
    row[1L, , drop = FALSE]
  }

  # -- OR from logistic_fit -----------------------------------------------------
  or      <- NA_real_
  or_ci   <- NA_character_
  or_p    <- NA_character_
  or_lo   <- NA_real_
  or_hi   <- NA_real_
  or_praw <- NA_real_

  if (!is.null(logistic_fit)) {
    row <- .extract_row(logistic_fit$or_table, exposure_term,
                        "logistic_fit$or_table")
    if (!is.null(row)) {
      or      <- round(row$or[[1L]],       digits_or)
      or_lo   <- round(row$ci_lower[[1L]], digits_or)
      or_hi   <- round(row$ci_upper[[1L]], digits_or)
      or_praw <- row$p_value[[1L]]
      or_ci   <- .fmt_est_ci(or, or_lo, or_hi, digits_or)
      or_p    <- .fmt_slot_pval(or_praw, digits_p)
    }
  }

  # -- IRR from poisson_fit / nb_model ------------------------------------------
  irr      <- NA_real_
  irr_ci   <- NA_character_
  irr_p    <- NA_character_
  irr_lo   <- NA_real_
  irr_hi   <- NA_real_
  irr_praw <- NA_real_

  if (!is.null(poisson_fit)) {
    row <- .extract_row(poisson_fit$irr_table, exposure_term,
                        "poisson_fit$irr_table")
    if (!is.null(row)) {
      irr      <- round(row$irr[[1L]],      digits_or)
      irr_lo   <- round(row$ci_lower[[1L]], digits_or)
      irr_hi   <- round(row$ci_upper[[1L]], digits_or)
      irr_praw <- row$p_value[[1L]]
      irr_ci   <- .fmt_est_ci(irr, irr_lo, irr_hi, digits_or)
      irr_p    <- .fmt_slot_pval(irr_praw, digits_p)
    }
  }

  # -- Beta from lmm_fit --------------------------------------------------------
  beta      <- NA_real_
  beta_ci   <- NA_character_
  beta_p    <- NA_character_
  beta_lo   <- NA_real_
  beta_hi   <- NA_real_
  beta_praw <- NA_real_
  lmm_log   <- FALSE

  if (!is.null(lmm_fit)) {
    lmm_log <- isTRUE(lmm_fit$log_transformed)
    row      <- .extract_row(lmm_fit$coef_table, exposure_term,
                             "lmm_fit$coef_table")
    if (!is.null(row)) {
      beta      <- round(row$estimate[[1L]], digits_or)
      beta_lo   <- round(row$ci_lower[[1L]], digits_or)
      beta_hi   <- round(row$ci_upper[[1L]], digits_or)
      beta_praw <- row$p_value[[1L]]
      beta_ci   <- .fmt_est_ci(beta, beta_lo, beta_hi, digits_or)
      beta_p    <- .fmt_slot_pval(beta_praw, digits_p)
    }
  }

  # -- Absolute gap -------------------------------------------------------------
  absolute_gap <- if (!is.null(acceptance_rate)) {
    acceptance_rate[["ref"]] - acceptance_rate[["comparison"]]
  } else {
    NA_real_
  }

  # -- Abstract sentence --------------------------------------------------------
  abstract_sentence <- .build_abstract_sentence(
    n_total          = n_total,
    comparison_label = comparison_label,
    ref_label        = ref_label,
    outcome_label    = outcome_label,
    or               = or,
    or_lo            = or_lo,
    or_hi            = or_hi,
    or_praw          = or_praw,
    irr              = irr,
    irr_lo           = irr_lo,
    irr_hi           = irr_hi,
    irr_praw         = irr_praw,
    beta             = beta,
    beta_lo          = beta_lo,
    beta_hi          = beta_hi,
    beta_praw        = beta_praw,
    lmm_log          = lmm_log,
    absolute_gap     = absolute_gap,
    acceptance_rate  = acceptance_rate,
    digits_or        = digits_or,
    digits_p         = digits_p
  )

  # -- Build numbers_list -------------------------------------------------------
  numbers_list <- c(n_total = as.character(n_total))

  if (!is.na(or)) {
    numbers_list <- c(
      numbers_list,
      OR      = sprintf("%.*f", digits_or, or),
      OR_CI   = sprintf("%.*f-%.*f", digits_or, or_lo, digits_or, or_hi),
      OR_full = or_ci,
      OR_p    = or_p
    )
  }

  if (!is.na(irr)) {
    numbers_list <- c(
      numbers_list,
      IRR      = sprintf("%.*f", digits_or, irr),
      IRR_CI   = sprintf("%.*f-%.*f", digits_or, irr_lo, digits_or, irr_hi),
      IRR_full = irr_ci,
      IRR_p    = irr_p
    )
  }

  if (!is.na(beta)) {
    b_tag <- if (lmm_log) "beta_log" else "beta_days"
    numbers_list <- c(
      numbers_list,
      setNames(sprintf("%.*f", digits_or, beta),                                  b_tag),
      setNames(sprintf("%.*f-%.*f", digits_or, beta_lo, digits_or, beta_hi),      paste0(b_tag, "_CI")),
      setNames(beta_ci,                                                            paste0(b_tag, "_full")),
      setNames(beta_p,                                                             paste0(b_tag, "_p"))
    )
  }

  if (!is.na(absolute_gap) && !is.null(acceptance_rate)) {
    gap_pct  <- round(abs(absolute_gap) * 100)
    ref_pct  <- round(acceptance_rate[["ref"]]        * 100)
    comp_pct <- round(acceptance_rate[["comparison"]] * 100)
    numbers_list <- c(
      numbers_list,
      absolute_gap_pct    = sprintf("%d%%", gap_pct),
      ref_rate_pct        = sprintf("%d%%", ref_pct),
      comparison_rate_pct = sprintf("%d%%", comp_pct)
    )
  }

  numbers_list <- c(numbers_list, abstract_sentence = abstract_sentence)

  structure(
    list(
      n_total           = n_total,
      or                = or,
      or_ci             = or_ci,
      or_p              = or_p,
      irr               = irr,
      irr_ci            = irr_ci,
      irr_p             = irr_p,
      beta              = beta,
      beta_ci           = beta_ci,
      beta_p            = beta_p,
      absolute_gap      = absolute_gap,
      abstract_sentence = abstract_sentence,
      numbers_list      = numbers_list
    ),
    class = "mysterycall_abstract_numbers"
  )
}


# -- S3 print method -----------------------------------------------------------

#' Print method for mysterycall_abstract_numbers objects
#'
#' Displays each element of `numbers_list` with its name, one entry per line,
#' making the key abstract numbers easy to scan and copy-paste.
#'
#' @param x A `mysterycall_abstract_numbers` object returned by
#'   [mysterycall_abstract_numbers()].
#' @param ... Ignored.
#'
#' @return `invisible(x)`.
#'
#' @family reporting
#' @export
#'
#' @examples
#' fake_logistic <- structure(
#'   list(
#'     n        = 412L,
#'     or_table = data.frame(
#'       term     = c("(Intercept)", "insuranceMedicaid"),
#'       or       = c(2.10, 0.62),
#'       ci_lower = c(1.20, 0.41),
#'       ci_upper = c(3.68, 0.94),
#'       p_value  = c(0.008, 0.024),
#'       stringsAsFactors = FALSE
#'     )
#'   ),
#'   class = "mysterycall_logistic_model"
#' )
#' result <- mysterycall_abstract_numbers(
#'   logistic_fit     = fake_logistic,
#'   exposure_term    = "insuranceMedicaid",
#'   ref_label        = "commercial insurance",
#'   comparison_label = "Medicaid",
#'   acceptance_rate  = c(ref = 0.82, comparison = 0.61)
#' )
#' print(result)
print.mysterycall_abstract_numbers <- function(x, ...) {
  cat("mysterycall_abstract_numbers\n\n")
  nms <- names(x$numbers_list)
  for (i in seq_along(x$numbers_list)) {
    val <- x$numbers_list[[i]]
    if (nms[[i]] == "abstract_sentence") {
      cat(sprintf("  %-25s\n", nms[[i]]))
      cat(strwrap(val, width = 72L, indent = 4L, exdent = 4L), sep = "\n")
      cat("\n")
    } else {
      cat(sprintf("  %-25s %s\n", nms[[i]], val))
    }
  }
  invisible(x)
}
