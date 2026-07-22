#' Simple Poisson Regression for Group Comparison of Count Outcomes
#'
#' Fits a plain (non-multilevel) Poisson GLM to compare a count outcome across
#' groups. Returns an IRR table and a manuscript-ready summary statement
#' explaining why Poisson regression is preferred over Kruskal-Wallis for count
#' data.
#'
#' @details
#' Unlike [mysterycall_poisson_model()], this function uses `glm()` with no
#' random intercept. It is appropriate for quick two-group comparisons or when
#' the clustering structure is not the focus. For studies with physician-level
#' clustering use [mysterycall_poisson_model()] instead.
#'
#' The incidence rate ratio (IRR) is `exp(coef(model))`. Profile-likelihood
#' confidence intervals from [stats::confint()] are used when the model
#' converges; otherwise Wald CIs fall back.
#'
#' @param data A data frame.
#' @param outcome Character scalar. Name of the count outcome column (e.g.
#'   `"business_days_until_appointment"`). Must be non-negative integers.
#' @param group Character scalar. Name of the grouping column (e.g.
#'   `"insurance"`). Character or factor.
#' @param reference Optional character scalar. Reference level for `group`.
#'   Defaults to the first level alphabetically.
#' @param conf_level Confidence level. Default `0.95`.
#' @param outcome_label Optional human-readable label for `outcome` used in the
#'   summary sentence (e.g. `"business days until appointment"`).
#' @param use_profile_ci Logical. Use profile-likelihood CIs (default `TRUE`).
#'   Set to `FALSE` for large datasets where `confint()` is slow.
#'
#' @return A list of class `mysterycall_simple_poisson` with:
#' \describe{
#'   \item{`model`}{`glm` object.}
#'   \item{`irr_table`}{`data.frame`. One row per non-intercept term:
#'     `term`, `level`, `irr`, `ci_lower`, `ci_upper`, `p_value`,
#'     `p_value_fmt`, `direction` (`"higher"` / `"lower"` / `"same"`).}
#'   \item{`reference`}{Character. Reference level used.}
#'   \item{`summary_statement`}{Character. Manuscript-ready paragraph.}
#'   \item{`n`}{Integer. Complete-case rows used.}
#'   \item{`dispersion`}{Numeric. Pearson dispersion statistic (phi). Values
#'     > 1.5 suggest overdispersion; consider negative-binomial instead.}
#' }
#'
#' @references
#' Coxe, S., West, S. G., & Aiken, L. S. (2009). The analysis of count data:
#' A gentle introduction to Poisson regression and its alternatives.
#' *Journal of Personality Assessment*, 91(2), 121-136.
#'
#' Cameron, A. C., & Trivedi, P. K. (2013). *Regression Analysis of Count
#' Data* (2nd ed.). Cambridge University Press.
#'
#' @family outcomes
#' @seealso [mysterycall_poisson_model()] for a multilevel (GLMM) alternative;
#'   [mysterycall_overdispersion_test()] to assess whether negative-binomial is
#'   warranted; [mysterycall_check_normality()] which detects count data and
#'   recommends this function.
#' @importFrom stats glm poisson coef confint complete.cases as.formula vcov
#'   qnorm pnorm residuals relevel
#' @importFrom checkmate assert_data_frame assert_string assert_names assert_number assert_flag
#' @export
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   days      = rpois(120, lambda = 12),
#'   insurance = rep(c("BCBS", "Medicaid", "Medicare"), 40)
#' )
#' result <- mysterycall_simple_poisson(df, "days", "insurance",
#'                                      reference = "BCBS",
#'                                      outcome_label = "business days until appointment")
#' cat(result$summary_statement)
#' print(result$irr_table)
mysterycall_simple_poisson <- function(data,
                                       outcome,
                                       group,
                                       reference     = NULL,
                                       conf_level    = 0.95,
                                       outcome_label = NULL,
                                       use_profile_ci = TRUE) {

  # -- Input validation ---------------------------------------------------------
  checkmate::assert_data_frame(data, min.rows = 0)
  checkmate::assert_string(outcome)
  checkmate::assert_string(group)
  checkmate::assert_names(names(data), must.include = c(outcome, group))
  checkmate::assert_number(conf_level, lower = 0, upper = 1)
  checkmate::assert_flag(use_profile_ci)

  y <- data[[outcome]]
  if (!is.numeric(y))
    stop(sprintf("Outcome '%s' must be numeric.", outcome), call. = FALSE)
  if (any(y < 0, na.rm = TRUE)) {
    n_neg <- sum(y < 0, na.rm = TRUE)
    stop(sprintf(
      "Outcome '%s' contains %d negative value%s (min = %g).\nNegative wait days are impossible \u2014 check for data entry errors or date calculation bugs.",
      outcome, n_neg, if (n_neg == 1L) "" else "s", min(y, na.rm = TRUE)
    ), call. = FALSE)
  }
  if (any(y > 365, na.rm = TRUE)) {
    n_long <- sum(y > 365, na.rm = TRUE)
    warning(sprintf(
      "Outcome '%s' contains %d value%s exceeding 365 days (max = %g).\nWait times over one year are likely a year-typo error (e.g. 2027 instead of 2026) \u2014 verify appointment dates before modelling.",
      outcome, n_long, if (n_long == 1L) "" else "s", max(y, na.rm = TRUE)
    ), call. = FALSE)
  }

  g <- data[[group]]
  if (!is.factor(g) && !is.character(g))
    stop(sprintf("Group '%s' must be a factor or character column.", group), call. = FALSE)

  outcome_label <- outcome_label %||% gsub("_", " ", outcome)

  # -- Complete cases -----------------------------------------------------------
  cc <- stats::complete.cases(data[, c(outcome, group)])
  n_dropped <- sum(!cc)
  if (n_dropped > 0L)
    message(sprintf("%d row(s) with missing values excluded.", n_dropped))
  data <- data[cc, , drop = FALSE]
  n <- nrow(data)
  if (n == 0L) stop("No complete cases remain.", call. = FALSE)

  # -- Reference level ----------------------------------------------------------
  g <- data[[group]]
  levels_g <- sort(unique(as.character(g)))
  if (!is.null(reference)) {
    if (!reference %in% levels_g)
      stop(sprintf("'%s' is not a level of '%s'.", reference, group), call. = FALSE)
    data[[group]] <- relevel(factor(data[[group]]), ref = reference)
  } else {
    data[[group]] <- factor(data[[group]])
    reference <- levels(data[[group]])[1L]
  }
  non_ref <- setdiff(levels(data[[group]]), reference)

  # -- Fit model ----------------------------------------------------------------
  fml <- stats::as.formula(sprintf("%s ~ %s", outcome, group))
  message(sprintf("Fitting simple Poisson GLM: %s", deparse(fml)))

  model <- tryCatch(
    stats::glm(fml, family = stats::poisson(link = "log"), data = data),
    error = function(e) stop(sprintf("glm() failed: %s", e$message), call. = FALSE)
  )

  # -- IRR table ----------------------------------------------------------------
  cf   <- stats::coef(model)
  se   <- sqrt(diag(stats::vcov(model)))
  z    <- cf / se
  pv   <- 2 * stats::pnorm(-abs(z))
  z_crit <- stats::qnorm(1 - (1 - conf_level) / 2)

  if (use_profile_ci) {
    ci <- tryCatch(
      suppressMessages(stats::confint(model, level = conf_level)),
      error = function(e) {
        message("Profile CI failed; falling back to Wald CI.")
        cbind(cf - z_crit * se, cf + z_crit * se)
      }
    )
  } else {
    ci <- cbind(cf - z_crit * se, cf + z_crit * se)
  }

  fmt_p <- function(p) {
    ifelse(is.na(p), NA_character_,
           ifelse(p < 0.001, "< 0.001", sprintf("%.3f", p)))
  }

  non_int <- names(cf)[names(cf) != "(Intercept)"]
  irr_table <- data.frame(
    term      = non_int,
    level     = sub(paste0("^", group), "", non_int),
    irr       = exp(cf[non_int]),
    ci_lower  = exp(ci[non_int, 1L]),
    ci_upper  = exp(ci[non_int, 2L]),
    p_value   = pv[non_int],
    p_value_fmt = fmt_p(pv[non_int]),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  irr_table$direction <- ifelse(
    irr_table$irr > 1, "higher",
    ifelse(irr_table$irr < 1, "lower", "same")
  )

  # -- Dispersion ---------------------------------------------------------------
  phi <- sum(stats::residuals(model, type = "pearson")^2) / model$df.residual

  # -- Summary statement --------------------------------------------------------
  intercept_irr <- exp(cf[["(Intercept)"]])

  lines <- character(0L)
  lines[1L] <- sprintf(
    paste0(
      "Simple Poisson regression was used in place of Kruskal-Wallis because ",
      "%s is a count outcome (non-negative integers). ",
      "Poisson regression models the incidence rate ratio (IRR) directly, ",
      "which is more interpretable than a rank-based test statistic for count data."
    ),
    outcome_label
  )
  lines[2L] <- sprintf(
    "The baseline rate (%s) is estimated at %.2f events.",
    reference, intercept_irr
  )

  for (i in seq_len(nrow(irr_table))) {
    row <- irr_table[i, ]
    pct_diff <- abs(row$irr - 1) * 100
    lines <- c(lines, sprintf(
      paste0(
        "For %s compared to %s, the %s rate is approximately %.2f times %s ",
        "(%d%% %s; 95%% CI: %.2f-%.2f, p %s)."
      ),
      row$level, reference, outcome_label,
      row$irr, row$direction,
      round(pct_diff), row$direction,
      row$ci_lower, row$ci_upper, row$p_value_fmt
    ))
  }

  if (phi > mysterycall_overdispersion_threshold()) {
    lines <- c(lines, sprintf(
      paste0(
        "Note: the Pearson dispersion statistic is %.2f (> %.2f), suggesting ",
        "overdispersion. Consider negative-binomial regression via ",
        "mysterycall_nb_model()."
      ),
      phi, mysterycall_overdispersion_threshold()
    ))
  }

  summary_statement <- paste(lines, collapse = " ")

  structure(
    list(
      model            = model,
      irr_table        = irr_table,
      reference        = reference,
      summary_statement = summary_statement,
      n                = n,
      dispersion       = phi
    ),
    class = "mysterycall_simple_poisson"
  )
}


#' Print a `mysterycall_simple_poisson` object
#'
#' @param x A `mysterycall_simple_poisson` object.
#' @param digits Number of decimal places for printed estimates. Default `3`.
#' @param ... Ignored; present for S3 method consistency.
#' @return `x`, invisibly.
#' @export
print.mysterycall_simple_poisson <- function(x, digits = 3, ...) {
  cat(sprintf("Simple Poisson GLM  n = %d  Pearson phi = %.2f\n",
              x$n, x$dispersion))
  cat(sprintf("Reference level: %s\n\n", x$reference))
  tbl <- x$irr_table[, c("level", "irr", "ci_lower", "ci_upper", "p_value_fmt")]
  tbl$irr      <- round(tbl$irr,      digits)
  tbl$ci_lower <- round(tbl$ci_lower, digits)
  tbl$ci_upper <- round(tbl$ci_upper, digits)
  names(tbl)[names(tbl) == "p_value_fmt"] <- "p-value"
  print(tbl, row.names = FALSE)
  cat("\nSummary statement:\n")
  cat(strwrap(x$summary_statement, width = 80), sep = "\n")
  invisible(x)
}
