#' Screen candidate predictors for a GLMM outcome
#'
#' @name mysterycall_screen_predictors
NULL

#' Univariable GLMM screening of candidate predictors
#'
#' Fits one mixed-effects model per candidate column and returns a ranked
#' table of incidence rate ratios (Poisson / negative binomial) or odds
#' ratios (logistic), confidence intervals, and p-values. This answers the
#' reviewer question "how did you choose predictors?" by providing a
#' pre-specified, reproducible univariable screening step prior to the main
#' multivariable model.
#'
#' For each variable in `candidate_cols` the function:
#' \enumerate{
#'   \item Skips the variable when it has fewer than `min_levels` unique
#'     non-NA values.
#'   \item Builds the formula \code{outcome ~ predictor + (1 | random_intercept)}.
#'   \item Fits with [lme4::glmer()] (Poisson or binomial) or
#'     [glmmTMB::glmmTMB()] (negative binomial), wrapped in [tryCatch()].
#'   \item Extracts the coefficient for the first non-intercept term, then
#'     exponentiates to obtain the IRR or OR and its Wald confidence interval.
#'   \item Labels the result "significant" when \code{p < alpha_screen}.
#' }
#'
#' @param data A data frame containing all columns referenced by
#'   `outcome_col`, `random_intercept`, and `candidate_cols`.
#' @param outcome_col Character scalar. Name of the outcome column.
#'   For `family = "poisson"` or `"nb"` this must be a non-negative integer
#'   count; for `family = "logistic"` it must be 0/1 or a two-level factor.
#' @param random_intercept Character scalar. Name of the grouping column for
#'   the physician-level random intercept (e.g. `"physician"` or `"last"`).
#' @param candidate_cols Character vector or `NULL`. Columns to screen. When
#'   `NULL`, all columns in `data` are used except `outcome_col`,
#'   `random_intercept`, and any columns listed in `exclude_cols`.
#' @param exclude_cols Character vector. Columns to always skip, regardless
#'   of `candidate_cols`. Default `character(0)`.
#' @param family Character scalar. Model family: `"poisson"` (default),
#'   `"nb"` (negative binomial via glmmTMB), or `"logistic"` (binomial logit).
#' @param alpha_screen Numeric scalar. Liberal p-value threshold used only
#'   to flag "significant" predictors in the output table. Default `0.20`
#'   (appropriate for variable selection, not confirmatory inference).
#' @param conf_level Numeric scalar in (0, 1). Confidence level for Wald
#'   intervals. Default `0.95`.
#' @param min_levels Integer scalar. Predictors with fewer than `min_levels`
#'   unique non-NA values are skipped. Default `2L`.
#' @param verbose Logical. When `TRUE`, prints a one-line progress message
#'   before fitting each predictor. Default `FALSE`.
#' @param max_predictors Integer scalar. Maximum number of predictors to fit;
#'   screening stops after this many attempts (skipped predictors count toward
#'   the limit). Default `100L`.
#'
#' @return A list of class `"mysterycall_screen_predictors"` with elements:
#' \describe{
#'   \item{`table`}{A [`tibble::tibble`] with one row per candidate column
#'     and columns:
#'     \describe{
#'       \item{`predictor`}{Character. Column name.}
#'       \item{`estimate`}{Numeric. IRR (Poisson/NB) or OR (logistic).
#'         `NA` when fitting failed or predictor was skipped.}
#'       \item{`ci_lower`}{Numeric. Lower confidence bound (exponentiated).}
#'       \item{`ci_upper`}{Numeric. Upper confidence bound (exponentiated).}
#'       \item{`p_value`}{Numeric. Two-sided Wald p-value.}
#'       \item{`p_fmt`}{Character. Formatted p-value (`"< 0.001"` or
#'         `"0.XXX"`).}
#'       \item{`n_levels`}{Integer. Number of unique non-NA values observed
#'         in that column.}
#'       \item{`significant`}{Logical. `TRUE` when `p_value < alpha_screen`.}
#'       \item{`skipped`}{Logical. `TRUE` when the predictor was not fitted
#'         (too few levels, or error during fitting).}
#'       \item{`skip_reason`}{Character. Explanation when `skipped = TRUE`;
#'         `NA_character_` otherwise.}
#'     }
#'     Rows are sorted by `p_value` ascending (skipped rows last).}
#'   \item{`n_screened`}{Integer. Number of predictors actually fitted
#'     (not skipped).}
#'   \item{`n_significant`}{Integer. Number of fitted predictors with
#'     `p_value < alpha_screen`.}
#'   \item{`family`}{Character. The `family` argument used.}
#'   \item{`sentence`}{Character. A plain-language summary suitable for a
#'     Methods or Results section.}
#'   \item{`significant_predictors`}{Character vector of predictor names
#'     with `p_value < alpha_screen`.}
#' }
#'
#' @section Interpretation note:
#' `alpha_screen = 0.20` is deliberately liberal. This is standard practice
#' for predictor pre-selection (Hosmer & Lemeshow recommend 0.15-0.25); it
#' is **not** a significance threshold for the final model.
#'
#' @section Negative binomial:
#' When `family = "nb"`, the `glmmTMB` package is required.
#' [glmmTMB::glmmTMB()] is called with `family = glmmTMB::nbinom2(link =
#' "log")`.
#'
#' @importFrom stats as.formula model.frame
#' @family outcomes
#' @seealso [mysterycall_logistic_model()], [mysterycall_poisson_model()],
#'   [mysterycall_select_best_model()], [mysterycall_screen_interactions()]
#' @export
#'
#' @examples
#' \donttest{
#' if (requireNamespace("lme4", quietly = TRUE)) {
#'   set.seed(42)
#'   n <- 120
#'   df <- data.frame(
#'     wait_days   = rpois(n, lambda = 14),
#'     insurance   = sample(c("Medicaid", "BCBS"), n, replace = TRUE),
#'     gender      = sample(c("M", "F"), n, replace = TRUE),
#'     region      = sample(c("NE", "SE", "MW", "W"), n, replace = TRUE),
#'     practice_sz = sample(1:5, n, replace = TRUE),
#'     physician   = rep(paste0("Dr_", 1:12), each = 10),
#'     stringsAsFactors = FALSE
#'   )
#'   result <- mysterycall_screen_predictors(
#'     data             = df,
#'     outcome_col      = "wait_days",
#'     random_intercept = "physician",
#'     family           = "poisson",
#'     alpha_screen     = 0.20,
#'     verbose          = TRUE
#'   )
#'   print(result$table)
#'   cat(result$sentence, "\n")
#' }
#' }
mysterycall_screen_predictors <- function(data,
                                           outcome_col,
                                           random_intercept,
                                           candidate_cols   = NULL,
                                           exclude_cols     = character(0L),
                                           family           = c("poisson", "nb", "logistic"),
                                           alpha_screen     = 0.20,
                                           conf_level       = 0.95,
                                           min_levels       = 2L,
                                           verbose          = FALSE,
                                           max_predictors   = 100L) {

  # ---- Argument validation ---------------------------------------------------
  family <- match.arg(family)

  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!is.character(outcome_col) || length(outcome_col) != 1L) {
    stop("`outcome_col` must be a single character string.", call. = FALSE)
  }
  if (!outcome_col %in% names(data)) {
    stop(sprintf("`outcome_col` '%s' not found in `data`.", outcome_col), call. = FALSE)
  }
  if (!is.character(random_intercept) || length(random_intercept) != 1L) {
    stop("`random_intercept` must be a single character string.", call. = FALSE)
  }
  if (!random_intercept %in% names(data)) {
    stop(
      sprintf("`random_intercept` '%s' not found in `data`.", random_intercept),
      call. = FALSE
    )
  }
  if (!is.numeric(alpha_screen) || length(alpha_screen) != 1L ||
      alpha_screen <= 0 || alpha_screen >= 1) {
    stop("`alpha_screen` must be a single number in (0, 1).", call. = FALSE)
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1) {
    stop("`conf_level` must be a single number in (0, 1).", call. = FALSE)
  }
  if (!is.numeric(min_levels) || length(min_levels) != 1L || min_levels < 1L) {
    stop("`min_levels` must be a positive integer scalar.", call. = FALSE)
  }
  min_levels <- as.integer(min_levels)
  if (!is.numeric(max_predictors) || length(max_predictors) != 1L ||
      max_predictors < 1L) {
    stop("`max_predictors` must be a positive integer scalar.", call. = FALSE)
  }
  max_predictors <- as.integer(max_predictors)

  # ---- Check required packages -----------------------------------------------
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop(
      "Package 'lme4' is required for mysterycall_screen_predictors(). ",
      "Install with: install.packages('lme4')",
      call. = FALSE
    )
  }
  if (identical(family, "nb") && !requireNamespace("glmmTMB", quietly = TRUE)) {
    stop(
      "Package 'glmmTMB' is required when `family = \"nb\"`. ",
      "Install with: install.packages('glmmTMB')",
      call. = FALSE
    )
  }

  # ---- Resolve candidate columns ---------------------------------------------
  always_exclude <- unique(c(outcome_col, random_intercept, exclude_cols))

  if (is.null(candidate_cols)) {
    candidate_cols <- setdiff(names(data), always_exclude)
  } else {
    if (!is.character(candidate_cols)) {
      stop("`candidate_cols` must be a character vector or NULL.", call. = FALSE)
    }
    missing_cands <- setdiff(candidate_cols, names(data))
    if (length(missing_cands) > 0L) {
      stop(
        "Columns in `candidate_cols` not found in `data`: ",
        paste(missing_cands, collapse = ", "),
        call. = FALSE
      )
    }
    candidate_cols <- setdiff(candidate_cols, always_exclude)
  }

  if (length(candidate_cols) == 0L) {
    stop("No candidate columns remain after exclusions.", call. = FALSE)
  }

  # Respect max_predictors
  if (length(candidate_cols) > max_predictors) {
    if (verbose) {
      message(sprintf(
        "[screen_predictors] Truncating to first %d of %d candidates (max_predictors).",
        max_predictors, length(candidate_cols)
      ))
    }
    candidate_cols <- candidate_cols[seq_len(max_predictors)]
  }

  # ---- z critical value ------------------------------------------------------
  z_crit <- stats::qnorm(1 - (1 - conf_level) / 2)

  # ---- Fitting helpers --------------------------------------------------------

  # Format p-value for display
  .fmt_p <- function(p) {
    if (is.na(p)) return(NA_character_)
    if (p < 0.001) return("< 0.001")
    sprintf("%.3f", p)
  }

  # Fit one model and extract IRR/OR + CI + p for the first non-intercept term
  .fit_one <- function(pred) {
    fml <- stats::as.formula(
      sprintf("%s ~ %s + (1 | %s)", outcome_col, pred, random_intercept)
    )

    fit <- tryCatch({
      if (identical(family, "nb")) {
        glmmTMB::glmmTMB(
          fml,
          data   = data,
          family = glmmTMB::nbinom2(link = "log")
        )
      } else if (identical(family, "logistic")) {
        lme4::glmer(fml, data = data, family = stats::binomial(link = "logit"),
                    nAGQ = 0L,
                    control = lme4::glmerControl(optimizer = "bobyqa"))
      } else {
        lme4::glmer(fml, data = data, family = stats::poisson(link = "log"),
                    nAGQ = 0L,
                    control = lme4::glmerControl(optimizer = "bobyqa"))
      }
    }, error = function(e) {
      structure(list(message = conditionMessage(e)), class = "screen_fit_error")
    }, warning = function(w) {
      # Convergence warnings are common in screening; suppress and continue.
      # Re-run silently.
      withCallingHandlers(
        if (identical(family, "nb")) {
          glmmTMB::glmmTMB(
            fml,
            data   = data,
            family = glmmTMB::nbinom2(link = "log")
          )
        } else if (identical(family, "logistic")) {
          lme4::glmer(fml, data = data, family = stats::binomial(link = "logit"),
                      nAGQ = 0L,
                      control = lme4::glmerControl(optimizer = "bobyqa"))
        } else {
          lme4::glmer(fml, data = data, family = stats::poisson(link = "log"),
                      nAGQ = 0L,
                      control = lme4::glmerControl(optimizer = "bobyqa"))
        },
        warning = function(w2) invokeRestart("muffleWarning")
      )
    })

    if (inherits(fit, "screen_fit_error")) {
      return(list(
        estimate   = NA_real_,
        ci_lower   = NA_real_,
        ci_upper   = NA_real_,
        p_value    = NA_real_,
        skipped    = TRUE,
        skip_reason = paste0("Model error: ", fit$message)
      ))
    }

    # Extract fixed-effects coefficient table
    coef_tbl <- tryCatch({
      if (identical(family, "nb")) {
        as.data.frame(summary(fit)$coefficients$cond)
      } else {
        as.data.frame(summary(fit)$coefficients)
      }
    }, error = function(e) NULL)

    if (is.null(coef_tbl) || nrow(coef_tbl) < 2L) {
      return(list(
        estimate    = NA_real_,
        ci_lower    = NA_real_,
        ci_upper    = NA_real_,
        p_value     = NA_real_,
        skipped     = TRUE,
        skip_reason = "Could not extract coefficient table (< 2 rows)"
      ))
    }

    # First non-intercept row
    non_int <- coef_tbl[rownames(coef_tbl) != "(Intercept)", , drop = FALSE]
    if (nrow(non_int) == 0L) {
      return(list(
        estimate    = NA_real_,
        ci_lower    = NA_real_,
        ci_upper    = NA_real_,
        p_value     = NA_real_,
        skipped     = TRUE,
        skip_reason = "No non-intercept coefficient found"
      ))
    }

    row1     <- non_int[1L, , drop = FALSE]
    beta     <- as.numeric(row1[[1L]])   # Estimate column
    se       <- as.numeric(row1[[2L]])   # Std. Error column

    # p-value: use column 4 if present (z-test), else derive from z
    if (ncol(row1) >= 4L) {
      p_val <- as.numeric(row1[[ncol(row1)]])
    } else {
      z_val <- beta / se
      p_val <- 2 * stats::pnorm(-abs(z_val))
    }

    list(
      estimate    = exp(beta),
      ci_lower    = exp(beta - z_crit * se),
      ci_upper    = exp(beta + z_crit * se),
      p_value     = p_val,
      skipped     = FALSE,
      skip_reason = NA_character_
    )
  }

  # ---- Screen each candidate -------------------------------------------------
  rows <- vector("list", length(candidate_cols))

  for (i in seq_along(candidate_cols)) {
    pred <- candidate_cols[[i]]

    col_vals  <- data[[pred]]
    n_levels  <- length(unique(col_vals[!is.na(col_vals)]))

    if (verbose) {
      message(sprintf(
        "[screen_predictors] (%d/%d) Fitting: %s  (n_levels = %d)",
        i, length(candidate_cols), pred, n_levels
      ))
    }

    if (n_levels < min_levels) {
      rows[[i]] <- list(
        predictor   = pred,
        estimate    = NA_real_,
        ci_lower    = NA_real_,
        ci_upper    = NA_real_,
        p_value     = NA_real_,
        p_fmt       = NA_character_,
        n_levels    = n_levels,
        significant = NA,
        skipped     = TRUE,
        skip_reason = sprintf(
          "Only %d unique non-NA value(s) (min_levels = %d)", n_levels, min_levels
        )
      )
      next
    }

    res <- .fit_one(pred)

    rows[[i]] <- list(
      predictor   = pred,
      estimate    = res$estimate,
      ci_lower    = res$ci_lower,
      ci_upper    = res$ci_upper,
      p_value     = res$p_value,
      p_fmt       = .fmt_p(res$p_value),
      n_levels    = n_levels,
      significant = if (res$skipped || is.na(res$p_value)) NA else res$p_value < alpha_screen,
      skipped     = res$skipped,
      skip_reason = res$skip_reason
    )
  }

  # ---- Assemble output table -------------------------------------------------
  tbl <- data.frame(
    predictor   = vapply(rows, function(r) r$predictor,   character(1L)),
    estimate    = vapply(rows, function(r) r$estimate,     double(1L)),
    ci_lower    = vapply(rows, function(r) r$ci_lower,     double(1L)),
    ci_upper    = vapply(rows, function(r) r$ci_upper,     double(1L)),
    p_value     = vapply(rows, function(r) r$p_value,      double(1L)),
    p_fmt       = vapply(rows, function(r) {
                    v <- r$p_fmt
                    if (is.null(v) || length(v) == 0L) NA_character_ else v
                  }, character(1L)),
    n_levels    = vapply(rows, function(r) as.integer(r$n_levels), integer(1L)),
    significant = vapply(rows, function(r) {
                    v <- r$significant
                    if (is.null(v) || is.na(v)) NA else as.logical(v)
                  }, logical(1L)),
    skipped     = vapply(rows, function(r) r$skipped,      logical(1L)),
    skip_reason = vapply(rows, function(r) {
                    v <- r$skip_reason
                    if (is.null(v) || length(v) == 0L) NA_character_ else as.character(v)
                  }, character(1L)),
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  # Sort: fitted rows by p_value ascending, then skipped rows
  fitted_idx  <- which(!tbl$skipped)
  skipped_idx <- which(tbl$skipped)
  ord_fitted  <- fitted_idx[order(tbl$p_value[fitted_idx], na.last = TRUE)]
  tbl         <- tbl[c(ord_fitted, skipped_idx), , drop = FALSE]
  rownames(tbl) <- NULL

  # Coerce to tibble when tibble is available (it is in Imports)
  tbl <- tibble::as_tibble(tbl)

  # ---- Summary quantities ----------------------------------------------------
  n_screened    <- sum(!tbl$skipped)
  sig_rows      <- tbl$significant
  sig_rows[is.na(sig_rows)] <- FALSE
  n_significant <- sum(sig_rows)
  sig_preds     <- tbl$predictor[sig_rows]

  # ---- Plain-language sentence -----------------------------------------------
  estimate_label <- if (identical(family, "logistic")) "OR" else "IRR"
  family_label   <- switch(family,
    poisson  = "Poisson GLMM",
    nb       = "negative-binomial GLMM",
    logistic = "logistic GLMM"
  )

  if (n_significant == 0L) {
    sig_phrase <- sprintf(
      "no variables met the liberal p < %.2f screening threshold",
      alpha_screen
    )
  } else if (n_significant == 1L) {
    sig_phrase <- sprintf(
      "1 variable met the liberal p < %.2f screening threshold: %s",
      alpha_screen, sig_preds[[1L]]
    )
  } else {
    sig_phrase <- sprintf(
      "%d variables met the liberal p < %.2f screening threshold: %s",
      n_significant, alpha_screen,
      paste(sig_preds, collapse = ", ")
    )
  }

  sentence <- sprintf(
    paste0(
      "Variable screening (N = %d candidate predictor%s) fitted univariable %s ",
      "models (%s = exp(beta), Wald %d%% CI); %s."
    ),
    n_screened,
    if (n_screened == 1L) "" else "s",
    family_label,
    estimate_label,
    round(conf_level * 100),
    sig_phrase
  )

  # ---- Return ----------------------------------------------------------------
  structure(
    list(
      table                  = tbl,
      n_screened             = n_screened,
      n_significant          = n_significant,
      family                 = family,
      sentence               = sentence,
      significant_predictors = as.character(sig_preds)
    ),
    class = "mysterycall_screen_predictors"
  )
}


# ---- print method ------------------------------------------------------------

#' Print a mysterycall_screen_predictors result
#'
#' @param x A `mysterycall_screen_predictors` object.
#' @param n Integer. Number of rows to print. Default `10L`.
#' @param ... Ignored.
#' @export
#' @keywords internal
print.mysterycall_screen_predictors <- function(x, n = 10L, ...) {
  cat("<mysterycall_screen_predictors>\n")
  cat(sprintf("  Family   : %s\n", x$family))
  cat(sprintf("  Screened : %d predictors fitted\n", x$n_screened))
  cat(sprintf("  Sig (p<threshold): %d\n\n", x$n_significant))
  tbl <- x$table
  if (!is.null(tbl) && nrow(tbl) > 0L) {
    print_tbl <- tbl[seq_len(min(n, nrow(tbl))), , drop = FALSE]
    print(print_tbl)
    if (nrow(tbl) > n) {
      cat(sprintf("  ... %d more rows (use x$table to see all)\n", nrow(tbl) - n))
    }
  }
  cat("\n", x$sentence, "\n", sep = "")
  invisible(x)
}
