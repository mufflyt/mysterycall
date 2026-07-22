#' Monte Carlo power for a population-marginal, post-stratification-weighted
#' effect in a paired-call design
#'
#' Audit studies frequently oversample a rare stratum (rural practices,
#' minority-serving providers, a specific payer market) to get enough calls
#' there, yet want to report an effect that generalizes to the *population* mix.
#' The conditional model coefficient does not answer that question; the
#' population-marginal effect, obtained by post-stratification weighting, does.
#' This simulates a paired design -- each subject (e.g. a provider) is called
#' under two `conditions` (e.g. two insurance types), subjects belong to one of
#' two strata sampled at `stratum_sampling` but reweighted to `pop_stratum` --
#' fits a negative-binomial (or Poisson) GLMM with a subject random intercept,
#' and reports power for three estimands: the conditional condition x stratum
#' interaction, the unweighted marginal condition effect, and the
#' population-weighted marginal condition effect.
#'
#' @param n_subject Number of subjects (each contributes two calls). May be a
#'   vector to trace a power curve.
#' @param cell_means Numeric length-4 vector of the outcome mean in each
#'   condition x stratum cell, in the order
#'   `c(cond1_stratum0, cond2_stratum0, cond1_stratum1, cond2_stratum1)`
#'   (all `> 0`; counts).
#' @param sigma_subject Standard deviation of the subject random intercept on the
#'   log scale.
#' @param phi Negative-binomial dispersion (`size`).
#' @param stratum_sampling Probability a subject is in stratum 1 *in the sample*.
#' @param pop_stratum Target population probability of stratum 1 (drives the
#'   post-stratification weights).
#' @param condition_levels Length-2 labels for the within-subject condition.
#'   Default `c("A", "B")`.
#' @param family Working family for the fit: `"negbin"` (default), `"poisson"`,
#'   or `"auto"` (Poisson unless the Pearson dispersion exceeds
#'   `disp_threshold`).
#' @param disp_threshold Dispersion ratio above which `"auto"` switches to NB.
#'   Default `1.5`.
#' @param alpha Two-sided significance level. Default `0.05`.
#' @param n_sim Monte Carlo replicates per sample size. Default `200`.
#' @param seed Optional integer seed.
#'
#' @return An object of class `"mysterycall_marginal_power"`: a list with `table`
#'   (a tibble: `n_subject`, `n_calls`, `pow_cond_interaction`,
#'   `pow_marg_unweighted`, `pow_marg_popweighted`, mean marginal estimates,
#'   `convergence_rate`, `family_summary`, `n_sim`) and `truth`
#'   (the true population-marginal condition effect in outcome units).
#'   [as.data.frame()] returns the table. Requires the \pkg{glmmTMB} and
#'   \pkg{marginaleffects} packages.
#'
#' @examples
#' \donttest{
#' mysterycall_marginal_power(
#'   n_subject = c(150, 300),
#'   cell_means = c(14, 18, 17, 24),   # BCBS/Medicaid x urban/rural wait days
#'   sigma_subject = 0.4, phi = 1.7,
#'   stratum_sampling = 0.5, pop_stratum = 0.15,
#'   n_sim = 40, seed = 1
#' )
#' }
#' @export
mysterycall_marginal_power <- function(n_subject, cell_means, sigma_subject, phi,
                                       stratum_sampling, pop_stratum,
                                       condition_levels = c("A", "B"),
                                       family = c("negbin", "poisson", "auto"),
                                       disp_threshold = mysterycall_overdispersion_threshold(), alpha = 0.05,
                                       n_sim = 200, seed = NULL) {
  family <- match.arg(family)
  checkmate::assert_integerish(n_subject, lower = 2, any.missing = FALSE,
                               min.len = 1L)
  checkmate::assert_numeric(cell_means, len = 4L, lower = 1e-9, any.missing = FALSE)
  checkmate::assert_number(sigma_subject, lower = 0)
  checkmate::assert_number(phi, lower = 1e-6)
  checkmate::assert_number(stratum_sampling, lower = 1e-6, upper = 1 - 1e-6)
  checkmate::assert_number(pop_stratum, lower = 0, upper = 1)
  checkmate::assert_character(condition_levels, len = 2L, any.missing = FALSE)
  checkmate::assert_number(disp_threshold, lower = 1)
  checkmate::assert_number(alpha, lower = 1e-6, upper = 0.5)
  checkmate::assert_count(n_sim, positive = TRUE)
  for (pkg in c("glmmTMB", "marginaleffects")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop(sprintf("mysterycall_marginal_power() needs the %s package (in Suggests).",
                   pkg), call. = FALSE)
    }
  }
  if (!is.null(seed)) set.seed(seed)

  cond2 <- condition_levels[2]
  int_term <- sprintf("condition%s:stratum", cond2)
  fix <- .mc_marginal_fixed(cell_means, cond2)
  truth <- pop_stratum * (cell_means[4] - cell_means[3]) +
    (1 - pop_stratum) * (cell_means[2] - cell_means[1])

  rows <- lapply(n_subject, function(ns) {
    .mc_marginal_at_n(ns, fix, int_term, sigma_subject, phi, stratum_sampling,
                      pop_stratum, condition_levels, family, disp_threshold,
                      alpha, n_sim)
  })
  tab <- tibble::as_tibble(do.call(rbind, rows))

  structure(
    list(table = tab, truth = unname(truth), alpha = alpha, n_sim = n_sim),
    class = "mysterycall_marginal_power"
  )
}

# coefficients of ~ condition * stratum from the four cell means (log scale)
.mc_marginal_fixed <- function(cell_means, cond2) {
  cm <- unname(cell_means)
  b0 <- log(cm[1])
  b_cond <- log(cm[2]) - b0
  b_str  <- log(cm[3]) - b0
  b_int  <- log(cm[4]) - b0 - b_cond - b_str
  stats::setNames(c(b0, b_cond, b_str, b_int),
                  c("(Intercept)", paste0("condition", cond2), "stratum",
                    sprintf("condition%s:stratum", cond2)))
}

.mc_marginal_design <- function(n_subject, stratum_sampling, pop_stratum,
                                condition_levels) {
  ids <- sprintf("S%05d", seq_len(n_subject))
  stratum <- stats::rbinom(n_subject, 1, stratum_sampling)
  dat <- expand.grid(subject = ids,
                     condition = factor(condition_levels,
                                        levels = condition_levels),
                     stringsAsFactors = FALSE)
  dat$stratum <- stratum[match(dat$subject, ids)]
  dat$popwt <- ifelse(dat$stratum == 1,
                      pop_stratum / stratum_sampling,
                      (1 - pop_stratum) / (1 - stratum_sampling))
  dat
}

.mc_marginal_fit <- function(dat, family_obj) {
  suppressWarnings(tryCatch(
    glmmTMB::glmmTMB(y ~ condition * stratum + (1 | subject),
                     family = family_obj, data = dat),
    error = function(e) NULL))
}

.mc_marginal_disp <- function(fit) {
  rdf <- stats::df.residual(fit)
  if (is.null(rdf) || rdf <= 0) return(NA_real_)
  pr <- stats::residuals(fit, type = "pearson")
  sum(pr^2, na.rm = TRUE) / rdf
}

.mc_marginal_one <- function(dat, fix, int_term, sigma_subject, phi,
                             family, disp_threshold) {
  X <- stats::model.matrix(~ condition * stratum, data = dat)
  eta_fixed <- as.numeric(X %*% fix[colnames(X)])
  subs <- unique(dat$subject)
  u <- stats::setNames(stats::rnorm(length(subs), 0, sigma_subject), subs)
  mu <- exp(eta_fixed + u[dat$subject])
  dat$y <- stats::rnbinom(nrow(dat), mu = mu, size = phi)

  fam_used <- family
  if (family == "negbin") {
    fit <- .mc_marginal_fit(dat, glmmTMB::nbinom2)
  } else if (family == "poisson") {
    fit <- .mc_marginal_fit(dat, stats::poisson)
  } else {
    fp <- .mc_marginal_fit(dat, stats::poisson)
    if (is.null(fp)) {
      fit <- .mc_marginal_fit(dat, glmmTMB::nbinom2); fam_used <- "negbin"
    } else {
      dr <- .mc_marginal_disp(fp)
      if (!is.finite(dr) || dr > disp_threshold) {
        fit <- .mc_marginal_fit(dat, glmmTMB::nbinom2); fam_used <- "negbin"
      } else { fit <- fp; fam_used <- "poisson" }
    }
  }
  if (is.null(fit)) {
    return(list(cond_p = NA_real_, unw_p = NA_real_, pop_p = NA_real_,
                unw_est = NA_real_, pop_est = NA_real_, converged = FALSE,
                family = fam_used))
  }

  cf <- summary(fit)$coefficients$cond
  cond_p <- if (int_term %in% rownames(cf)) cf[int_term, "Pr(>|z|)"] else NA_real_
  # incidental convergence / SE warnings from a degenerate simulated fit are
  # expected noise in Monte Carlo; the replicate simply contributes NA if the
  # marginal comparison fails to compute.
  me_unw <- tryCatch(suppressWarnings(suppressMessages(
    marginaleffects::avg_comparisons(
      fit, variables = "condition", type = "response", re.form = NA))),
    error = function(e) NULL)
  me_pop <- tryCatch(suppressWarnings(suppressMessages(
    marginaleffects::avg_comparisons(
      fit, variables = "condition", wts = "popwt", type = "response",
      re.form = NA))), error = function(e) NULL)

  list(
    cond_p = cond_p,
    unw_p = if (is.null(me_unw)) NA_real_ else me_unw$p.value[1],
    pop_p = if (is.null(me_pop)) NA_real_ else me_pop$p.value[1],
    unw_est = if (is.null(me_unw)) NA_real_ else me_unw$estimate[1],
    pop_est = if (is.null(me_pop)) NA_real_ else me_pop$estimate[1],
    converged = TRUE, family = fam_used
  )
}

.mc_marginal_at_n <- function(n_subject, fix, int_term, sigma_subject, phi,
                              stratum_sampling, pop_stratum, condition_levels,
                              family, disp_threshold, alpha, n_sim) {
  dat <- .mc_marginal_design(n_subject, stratum_sampling, pop_stratum,
                             condition_levels)
  reps <- lapply(seq_len(n_sim), function(i) {
    .mc_marginal_one(dat, fix, int_term, sigma_subject, phi, family,
                     disp_threshold)
  })
  pw <- function(k) mean(vapply(reps, function(r) r[[k]], numeric(1)) < alpha,
                         na.rm = TRUE)
  mn <- function(k) mean(vapply(reps, function(r) r[[k]], numeric(1)),
                         na.rm = TRUE)
  fams <- vapply(reps, function(r) r$family, character(1))
  data.frame(
    n_subject = n_subject,
    n_calls = n_subject * 2L,
    pow_cond_interaction = pw("cond_p"),
    pow_marg_unweighted = pw("unw_p"),
    pow_marg_popweighted = pw("pop_p"),
    mean_marg_unw_est = mn("unw_est"),
    mean_marg_pop_est = mn("pop_est"),
    convergence_rate = mean(vapply(reps, function(r) r$converged, logical(1))),
    family_summary = paste(sprintf("%s: %d", names(table(fams)),
                                   as.integer(table(fams))), collapse = "; "),
    n_sim = n_sim,
    stringsAsFactors = FALSE
  )
}

#' Print a `mysterycall_marginal_power` object
#'
#' @param x A `mysterycall_marginal_power` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return `x`, invisibly.
#' @export
print.mysterycall_marginal_power <- function(x, ...) {
  cat(sprintf(paste0("<mysterycall marginal power: %d sample size(s), %d sims, ",
                     "true marginal effect %.2f>\n"),
              nrow(x$table), x$n_sim, x$truth))
  print(x$table, ...)
  invisible(x)
}

#' Coerce a `mysterycall_marginal_power` object to a data frame
#'
#' @param x A `mysterycall_marginal_power` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return A `data.frame` representation of `x`.
#' @export
as.data.frame.mysterycall_marginal_power <- function(x, ...) {
  as.data.frame(x$table, ...)
}
