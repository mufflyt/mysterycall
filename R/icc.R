#' Intraclass correlation coefficient for mystery-caller models
#'
#' @name icc
NULL

#' Extract the intraclass correlation coefficient from a fitted model
#'
#' Computes the ICC for the physician random intercept using the latent-variable
#' method (Nakagawa & Schielzeth 2010). The ICC quantifies what proportion of
#' the total outcome variance is attributable to between-physician clustering,
#' which justifies the use of a GLMM over a simple GLM.
#'
#' For **Poisson** models:
#' \deqn{\text{ICC} = \frac{\sigma^2_u}{\sigma^2_u + \pi^2/3}}
#'
#' For **negative binomial** models:
#' \deqn{\text{ICC} = \frac{\sigma^2_u}{\sigma^2_u + \psi_1(1/\theta) + \pi^2/3}}
#'
#' where \eqn{\sigma^2_u} is the physician random-intercept variance,
#' \eqn{\pi^2/3} is the logistic-distribution variance (latent-variable
#' approximation), and \eqn{\psi_1} is the trigamma function.
#'
#' @param model_result A `mysterycall_poisson_model` or `mysterycall_nb_model`
#'   object returned by [mysterycall_poisson_model()] or [mysterycall_nb_model()].
#' @param conf_level Numeric. Confidence level for bootstrap CI. Default `0.95`.
#'   Used only when `n_boot > 0`.
#' @param n_boot Integer. Number of bootstrap replicates for confidence interval.
#'   Default `0L` (no bootstrap; CI is `c(NA, NA)`). Values of 500-2000 are
#'   recommended for publication.
#' @param seed Integer or `NULL`. Random seed for bootstrap reproducibility.
#'   Default `NULL`.
#'
#' @return A list of class `mysterycall_icc` with elements:
#' \describe{
#'   \item{`icc`}{Numeric. ICC point estimate.}
#'   \item{`sigma2_u`}{Numeric. Physician random-intercept variance on the
#'     log scale.}
#'   \item{`method`}{Character. `"latent_variable_poisson"` or
#'     `"latent_variable_nb"`.}
#'   \item{`ci`}{Numeric vector length 2. Bootstrap percentile CI, or
#'     `c(NA, NA)` when `n_boot = 0`.}
#'   \item{`n_boot`}{Integer. Number of bootstrap replicates used.}
#'   \item{`interpretation`}{Character. One-sentence plain-language summary.}
#'   \item{`model_class`}{Character. Class of `model_result`.}
#' }
#'
#' @references
#' Nakagawa S, Schielzeth H (2010). A general and simple method for obtaining
#' R^2 from generalized linear mixed-effects models. *Methods in Ecology and
#' Evolution* 4(2):133-142. \doi{10.1111/j.2041-210x.2012.00261.x}
#'
#' @family outcomes
#' @seealso [mysterycall_poisson_model()], [mysterycall_nb_model()],
#'   [mysterycall_icc_sentence()]
#' @export
#'
#' @examplesIf requireNamespace("lme4", quietly = TRUE)
#' set.seed(1)
#' df <- data.frame(
#'   wait = rpois(60, 21),
#'   ins  = rep(c("Medicaid", "BCBS"), 30),
#'   phys = rep(paste0("Dr", 1:10), each = 6),
#'   stringsAsFactors = FALSE
#' )
#' fit <- mysterycall_poisson_model(df, "wait", "ins", "phys")
#' icc <- mysterycall_icc(fit)
#' print(icc)
mysterycall_icc <- function(model_result,
                             conf_level = 0.95,
                             n_boot     = 0L,
                             seed       = NULL) {

  if (!inherits(model_result, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    stop(
      "`model_result` must be a `mysterycall_poisson_model` or `mysterycall_nb_model`.",
      call. = FALSE
    )
  }
  if (is.null(model_result$model)) {
    stop(
      "`model_result$model` is NULL. Refit the model with a real dataset before computing the ICC.",
      call. = FALSE
    )
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1) {
    stop("`conf_level` must be a single number in (0, 1).", call. = FALSE)
  }

  n_boot <- as.integer(n_boot)
  is_nb  <- inherits(model_result, "mysterycall_nb_model")

  sigma2_u <- .extract_sigma2_u(model_result, is_nb)

  icc_val <- .compute_icc(sigma2_u, is_nb, model_result$theta)
  method  <- if (is_nb) "latent_variable_nb" else "latent_variable_poisson"

  ci <- c(NA_real_, NA_real_)
  if (n_boot > 0L) {
    if (!is.null(seed)) withr::local_seed(seed)
    ci <- .bootstrap_icc(model_result, is_nb, n_boot, conf_level)
  }

  pct  <- round(icc_val * 100, 1)
  interp <- sprintf(
    "ICC = %.3f: %.1f%% of outcome variance is attributable to between-physician clustering.",
    icc_val, pct
  )

  structure(
    list(
      icc         = icc_val,
      sigma2_u    = sigma2_u,
      method      = method,
      ci          = ci,
      n_boot      = n_boot,
      conf_level  = conf_level,
      interpretation = interp,
      model_class = class(model_result)[1L]
    ),
    class = "mysterycall_icc"
  )
}

.extract_sigma2_u <- function(model_result, is_nb) {
  tryCatch({
    if (is_nb) {
      if (!requireNamespace("glmmTMB", quietly = TRUE)) {
        stop(
          "This function requires the glmmTMB package.\n",
          "Install it with: install.packages(\"glmmTMB\")",
          call. = FALSE
        )
      }
      vc <- glmmTMB::VarCorr(model_result$model)
      as.numeric(vc$cond[[1L]])
    } else {
      if (!requireNamespace("lme4", quietly = TRUE)) {
        stop(
          "This function requires the lme4 package.\n",
          "Install it with: install.packages(\"lme4\")",
          call. = FALSE
        )
      }
      vc <- lme4::VarCorr(model_result$model)
      as.numeric(vc[[1L]])
    }
  }, error = function(e) {
    stop("Could not extract random-intercept variance: ", conditionMessage(e),
         call. = FALSE)
  })
}

# Latent-scale (link-scale) distribution variance for a GLMM, following the
# Nakagawa & Schielzeth (2010) latent-variable method. This is the canonical
# level-1 variance used throughout mysterycall for ICC-type quantities:
#   * Poisson / binomial : pi^2 / 3  (logistic-distribution variance)
#   * negative binomial  : trigamma(1 / theta) + pi^2 / 3
# `is_nb = FALSE` (or an NB model with an unusable theta) returns pi^2 / 3.
# Keeping this in one place ensures mysterycall_icc(),
# mysterycall_random_effect_variance(), and mysterycall_adjusted_power() all
# decompose ICC on the same scale rather than contradicting each other.
.mysterycall_latent_dist_var <- function(is_nb, theta = NULL) {
  pi2_3 <- pi^2 / 3
  if (isTRUE(is_nb) && !is.null(theta) && !is.na(theta) && theta > 0) {
    psigamma(1 / theta, deriv = 1L) + pi2_3
  } else {
    pi2_3
  }
}

.compute_icc <- function(sigma2_u, is_nb, theta) {
  usable_theta <- !is.null(theta) && !is.na(theta) && theta > 0
  if (is_nb && !usable_theta) {
    message("theta is NA/NULL; falling back to Poisson latent-variable ICC formula.")
  }
  sigma2_u / (sigma2_u + .mysterycall_latent_dist_var(is_nb, theta))
}

.bootstrap_icc <- function(model_result, is_nb, n_boot, conf_level) {
  boot_iccs <- numeric(n_boot)
  for (i in seq_len(n_boot)) {
    tryCatch({
      if (is_nb) {
        sim <- stats::simulate(model_result$model, nsim = 1L)[[1L]]
        tmp_data <- model_result$model$frame
        tmp_data[[as.character(stats::formula(model_result$model)[[2L]])]] <- sim
        refit <- suppressWarnings(suppressMessages(
          glmmTMB::glmmTMB(
            stats::formula(model_result$model),
            data   = tmp_data,
            family = glmmTMB::nbinom2(link = "log")
          )
        ))
        s2u  <- as.numeric(glmmTMB::VarCorr(refit)$cond[[1L]])
        theta_b <- glmmTMB::sigma(refit)
        boot_iccs[i] <- .compute_icc(s2u, TRUE, theta_b)
      } else {
        sim <- stats::simulate(model_result$model, nsim = 1L)[[1L]]
        refit <- suppressWarnings(suppressMessages(
          lme4::refit(model_result$model, sim)
        ))
        s2u <- as.numeric(lme4::VarCorr(refit)[[1L]])
        boot_iccs[i] <- .compute_icc(s2u, FALSE, NULL)
      }
    }, error = function(e) {
      boot_iccs[i] <<- NA_real_
    })
  }
  boot_iccs <- boot_iccs[!is.na(boot_iccs)]
  if (length(boot_iccs) < 10L) {
    warning("Fewer than 10 successful bootstrap replicates; CI may be unreliable.",
            call. = FALSE)
    return(c(NA_real_, NA_real_))
  }
  alpha <- 1 - conf_level
  stats::quantile(boot_iccs, probs = c(alpha / 2, 1 - alpha / 2))
}


#' Print method for mysterycall_icc
#'
#' @param x A `mysterycall_icc` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_icc <- function(x, ...) {
  cat(sprintf("Intraclass Correlation Coefficient (%s)\n", x$method))
  cat(sprintf("  ICC       = %.4f\n", x$icc))
  cat(sprintf("  sigma2_u  = %.4f  (physician random-intercept variance)\n", x$sigma2_u))
  if (!is.na(x$ci[1])) {
    cl <- if (is.null(x$conf_level)) 0.95 else x$conf_level
    cat(sprintf("  %d%% CI  = [%.4f, %.4f]  (%d bootstrap replicates)\n",
                round(cl * 100), x$ci[1], x$ci[2], x$n_boot))
  }
  cat("\n", x$interpretation, "\n", sep = "")
  invisible(x)
}


#' Generate a manuscript sentence for the ICC
#'
#' Formats the ICC result from [mysterycall_icc()] into a ready-to-paste
#' methods sentence.
#'
#' @param icc_result A `mysterycall_icc` object.
#'
#' @return A single character string suitable for the methods section.
#'
#' @family outcomes
#' @seealso [mysterycall_icc()]
#' @export
#'
#' @examples
#' fake_icc <- structure(
#'   list(icc = 0.18, sigma2_u = 0.72, method = "latent_variable_poisson",
#'        ci = c(NA, NA), n_boot = 0L,
#'        interpretation = "ICC = 0.18: 18.0% ...",
#'        model_class = "mysterycall_poisson_model"),
#'   class = "mysterycall_icc"
#' )
#' cat(mysterycall_icc_sentence(fake_icc))
mysterycall_icc_sentence <- function(icc_result) {
  if (!inherits(icc_result, "mysterycall_icc")) {
    stop("`icc_result` must be a `mysterycall_icc` object.", call. = FALSE)
  }
  pct <- round(icc_result$icc * 100, 1)
  ci_clause <- if (!is.na(icc_result$ci[1])) {
    sprintf(" (95%% bootstrap CI %.3f-%.3f)",
            icc_result$ci[1], icc_result$ci[2])
  } else {
    ""
  }
  sprintf(
    paste0(
      "The intraclass correlation coefficient was %.3f%s ",
      "(%.1f%% of variance attributable to between-physician clustering), ",
      "justifying the use of a multilevel model."
    ),
    icc_result$icc, ci_clause, pct
  )
}


# ── mysterycall_icc_report ────────────────────────────────────────────────────

#' Inter-caller reliability report for STROBE item 22
#'
#' Computes a comprehensive inter-rater reliability report focused on the
#' **callers** in a mystery-caller study (not model random effects). Satisfies
#' STROBE reporting item 22 by providing ICC, Cohen's kappa, confidence
#' intervals, and a manuscript-ready sentence.
#'
#' The ICC is derived from a one-way random-effects ANOVA where caller is the
#' grouping factor:
#'
#' \deqn{\widehat{\sigma}_b^2 = \frac{MS_B - MS_W}{n_0}, \quad
#'        \text{ICC} = \frac{\widehat{\sigma}_b^2}{\widehat{\sigma}_b^2 + MS_W}}
#'
#' which simplifies to
#'
#' \deqn{\text{ICC} = \frac{MS_B - MS_W}{MS_B + (n_0 - 1)\,MS_W}}
#'
#' where \eqn{n_0 = (N - \sum n_i^2 / N) / (k - 1)} is the effective group
#' size for unbalanced designs (Shrout & Fleiss, 1979).
#'
#' For a binary outcome, the intraclass kappa equals the ICC in the one-way
#' random-effects model (Fleiss, 1971), so both statistics are reported from
#' the same ANOVA decomposition. Confidence intervals use the exact
#' F-distribution method (Shrout & Fleiss, 1979). Kappa is interpreted using
#' Landis & Koch (1977) thresholds.
#'
#' @param data        data.frame with at least `caller_col` and `outcome_col`.
#' @param caller_col  Character. Column identifying which caller made each
#'   call. Default `"caller_id"`.
#' @param outcome_col Character. Column with binary 0/1 outcome (appointment
#'   offered). Non-binary values are coerced via `> 0` with a warning.
#'   Default `"offered"`.
#' @param group_col   Character or `NULL`. Optional grouping variable (e.g.
#'   insurance type). When supplied, stratified results are computed for each
#'   level and stored in `$group_results`. Default `NULL`.
#' @param conf_level  Numeric. Confidence level for the F-distribution CI.
#'   Default `0.95`.
#'
#' @return A list of class `mysterycall_icc_report` containing:
#' \describe{
#'   \item{`icc`}{Numeric. ICC point estimate (one-way random effects, single
#'     measures), clamped to \eqn{[0, 1]}.}
#'   \item{`kappa`}{Numeric. Cohen's kappa (numerically equal to ICC for
#'     binary outcomes in the one-way random-effects model; Fleiss 1971).
#'     Landis & Koch (1977) thresholds are used for the interpretation label.}
#'   \item{`ci`}{Numeric vector of length 2. Exact F-distribution CI for ICC.
#'     `c(NA, NA)` when within-caller variance is zero.}
#'   \item{`n_callers`}{Integer. Number of distinct callers.}
#'   \item{`n_calls`}{Integer. Total calls analysed (complete cases only).}
#'   \item{`n_per_caller`}{Named integer vector. Call counts per caller.}
#'   \item{`sentence`}{Character. Manuscript-ready one-sentence summary, e.g.
#'     `"Inter-caller reliability was ICC=0.82 (95% CI: 0.71-0.91), indicating
#'     excellent agreement (kappa=0.82)."`}
#'   \item{`table`}{data.frame. Per-caller call count, offers, and acceptance
#'     rate (`caller`, `n_calls`, `n_offered`, `accept_rate`).}
#'   \item{`group_results`}{Named list of `mysterycall_icc_report` objects (one
#'     per level of `group_col`), or `NULL` when `group_col` is `NULL`.}
#'   \item{`conf_level`}{Numeric. The `conf_level` argument used.}
#' }
#'
#' @references
#' Fleiss JL (1971). Measuring nominal scale agreement among many raters.
#' *Psychological Bulletin* 76(5):378-382. \doi{10.1037/h0031619}
#'
#' Landis JR, Koch GG (1977). The measurement of observer agreement for
#' categorical data. *Biometrics* 33(1):159-174. \doi{10.2307/2529310}
#'
#' Shrout PE, Fleiss JL (1979). Intraclass correlations: uses in assessing
#' rater reliability. *Psychological Bulletin* 86(2):420-428.
#' \doi{10.1037/0033-2909.86.2.420}
#'
#' @family outcomes
#' @seealso [mysterycall_icc()], [mysterycall_icc_sentence()]
#' @export
#'
#' @examples
#' set.seed(42)
#' df <- data.frame(
#'   caller_id = rep(c("Alice", "Bob", "Carol"), each = 20),
#'   offered   = c(
#'     rbinom(20, 1, 0.70),
#'     rbinom(20, 1, 0.65),
#'     rbinom(20, 1, 0.68)
#'   ),
#'   insurance = rep(c("Medicaid", "BCBS"), 30),
#'   stringsAsFactors = FALSE
#' )
#'
#' ## Basic report
#' rpt <- mysterycall_icc_report(df)
#' print(rpt)
#' cat(rpt$sentence, "\n")
#'
#' ## Stratified by insurance type
#' rpt2 <- mysterycall_icc_report(df, group_col = "insurance")
#' cat(rpt2$sentence, "\n")
#' lapply(rpt2$group_results, function(x) x$sentence)
mysterycall_icc_report <- function(data,
                                    caller_col  = "caller_id",
                                    outcome_col = "offered",
                                    group_col   = NULL,
                                    conf_level  = 0.95) {

  # ---- Input validation ------------------------------------------------------
  if (!is.data.frame(data))
    stop("`data` must be a data.frame.", call. = FALSE)
  if (!is.character(caller_col) || length(caller_col) != 1L)
    stop("`caller_col` must be a single character string.", call. = FALSE)
  if (!is.character(outcome_col) || length(outcome_col) != 1L)
    stop("`outcome_col` must be a single character string.", call. = FALSE)
  if (!caller_col %in% names(data))
    stop(sprintf(
      "caller_col '%s' not found in `data`.\nAvailable columns: %s",
      caller_col, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  if (!outcome_col %in% names(data))
    stop(sprintf(
      "outcome_col '%s' not found in `data`.\nAvailable columns: %s",
      outcome_col, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  if (!is.null(group_col)) {
    if (!is.character(group_col) || length(group_col) != 1L)
      stop("`group_col` must be a single character string or NULL.",
           call. = FALSE)
    if (!group_col %in% names(data))
      stop(sprintf(
        "group_col '%s' not found in `data`.\nAvailable columns: %s",
        group_col, paste(names(data), collapse = ", ")
      ), call. = FALSE)
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1)
    stop("`conf_level` must be a single number in (0, 1).", call. = FALSE)

  # ---- Prepare data ----------------------------------------------------------
  keep_cols <- unique(c(caller_col, outcome_col, group_col))
  df        <- data[stats::complete.cases(data[keep_cols]),
                    keep_cols, drop = FALSE]

  y <- as.numeric(df[[outcome_col]])
  if (!all(y %in% c(0, 1))) {
    warning(
      sprintf("`%s` has values outside {0, 1}; coercing via > 0.", outcome_col),
      call. = FALSE
    )
    y <- as.numeric(y > 0)
  }
  df[[outcome_col]] <- y

  # Case/whitespace-fold caller identity so "Alice" and "alice " are one caller,
  # matching mysterycall_caller_reliability(); otherwise they inflate the caller
  # count and distort the ICC.
  caller <- factor(tools::toTitleCase(tolower(trimws(as.character(df[[caller_col]])))))
  k      <- nlevels(caller)
  N      <- nrow(df)

  if (k < 2L)
    stop(sprintf(
      "At least 2 distinct callers are required for inter-caller reliability; found %d.",
      k
    ), call. = FALSE)
  if (N <= k)
    stop(
      "`n_calls` must exceed `n_callers` (too few observations).",
      call. = FALSE
    )

  # ---- One-way ANOVA decomposition (base R only) -----------------------------
  aov_fit <- stats::aov(df[[outcome_col]] ~ caller)
  ss_tab  <- summary(aov_fit)[[1L]]
  MS_B    <- ss_tab["caller",    "Mean Sq"]
  MS_W    <- ss_tab["Residuals", "Mean Sq"]
  df_B    <- ss_tab["caller",    "Df"]   # k - 1
  df_W    <- ss_tab["Residuals", "Df"]   # N - k

  counts <- as.integer(table(caller))           # n_i per caller
  n_0    <- (N - sum(counts^2) / N) / (k - 1L) # effective n (Shrout & Fleiss)

  # Handle degenerate case: no outcome variance at all
  if (isTRUE(all.equal(MS_B, 0)) && isTRUE(all.equal(MS_W, 0))) {
    warning(
      "All outcome values are identical across all calls; ICC is undefined (returning 0).",
      call. = FALSE
    )
    icc_val <- 0
  } else {
    icc_raw <- (MS_B - MS_W) / (MS_B + (n_0 - 1) * MS_W)
    icc_val <- max(0, min(1, icc_raw))
  }

  # For a binary outcome in a one-way random-effects model, the intraclass
  # kappa equals the ICC (Fleiss, 1971).
  kappa_val <- icc_val

  # ---- CI via exact F-distribution (Shrout & Fleiss, 1979) ------------------
  ci <- c(NA_real_, NA_real_)
  if (MS_W > 0) {
    alpha <- 1 - conf_level
    F_obs <- MS_B / MS_W
    # Lower bound
    F_L   <- F_obs / stats::qf(1 - alpha / 2, df1 = df_B, df2 = df_W)
    icc_L <- (F_L - 1) / (F_L + n_0 - 1)
    # Upper bound
    F_U   <- F_obs * stats::qf(1 - alpha / 2, df1 = df_W, df2 = df_B)
    icc_U <- (F_U - 1) / (F_U + n_0 - 1)
    ci    <- c(max(0, icc_L), min(1, icc_U))
  }

  # ---- Landis & Koch (1977) kappa interpretation ----------------------------
  kappa_label <- if      (kappa_val < 0.20) "poor"
                 else if (kappa_val < 0.40) "fair"
                 else if (kappa_val < 0.60) "moderate"
                 else if (kappa_val < 0.80) "good"
                 else                        "excellent"

  # ---- Manuscript sentence ---------------------------------------------------
  ci_str   <- if (!is.na(ci[1])) {
    sprintf("%.2f-%.2f", ci[1], ci[2])
  } else {
    "NA-NA"
  }
  sentence <- sprintf(
    "Inter-caller reliability was ICC=%.2f (%d%% CI: %s), indicating %s agreement (kappa=%.2f).",
    icc_val,
    as.integer(round(conf_level * 100)),
    ci_str,
    kappa_label,
    kappa_val
  )

  # ---- Per-caller summary table ----------------------------------------------
  caller_lvls  <- levels(caller)
  caller_table <- do.call(rbind, lapply(caller_lvls, function(lvl) {
    idx   <- which(caller == lvl)
    n_i   <- length(idx)
    n_yes <- sum(df[[outcome_col]][idx], na.rm = TRUE)
    data.frame(
      caller      = lvl,
      n_calls     = n_i,
      n_offered   = as.integer(n_yes),
      accept_rate = if (n_i > 0L) round(n_yes / n_i, 3L) else NA_real_,
      stringsAsFactors = FALSE
    )
  }))

  # ---- Optional group-level stratification -----------------------------------
  group_results <- NULL
  if (!is.null(group_col)) {
    groups        <- sort(unique(df[[group_col]]))
    group_results <- lapply(groups, function(g) {
      sub <- df[df[[group_col]] == g, , drop = FALSE]
      if (length(unique(sub[[caller_col]])) < 2L) return(NULL)
      mysterycall_icc_report(
        data        = sub,
        caller_col  = caller_col,
        outcome_col = outcome_col,
        group_col   = NULL,       # no nested recursion
        conf_level  = conf_level
      )
    })
    names(group_results) <- as.character(groups)
    group_results        <- Filter(Negate(is.null), group_results)
    if (length(group_results) == 0L) group_results <- NULL
  }

  # ---- Assemble return object ------------------------------------------------
  n_per_caller <- stats::setNames(counts, caller_lvls)

  structure(
    list(
      icc           = icc_val,
      kappa         = kappa_val,
      ci            = ci,
      n_callers     = as.integer(k),
      n_calls       = as.integer(N),
      n_per_caller  = n_per_caller,
      sentence      = sentence,
      table         = caller_table,
      group_results = group_results,
      conf_level    = conf_level
    ),
    class = "mysterycall_icc_report"
  )
}


#' Print method for mysterycall_icc_report
#'
#' @param x A `mysterycall_icc_report` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_icc_report <- function(x, ...) {
  cat("Inter-Rater Reliability Report (STROBE Item 22)\n")
  cat("================================================\n")
  cat(x$sentence, "\n\n")
  cat(sprintf("  Callers : %d\n", x$n_callers))
  cat(sprintf("  Calls   : %d\n\n", x$n_calls))
  cat("Per-Caller Summary:\n")
  print(x$table, row.names = FALSE)
  if (!is.null(x$group_results) && length(x$group_results) > 0L) {
    cat("\nGroup-Level Results:\n")
    for (g in names(x$group_results)) {
      cat(sprintf("  [%s] %s\n", g, x$group_results[[g]]$sentence))
    }
  }
  invisible(x)
}
