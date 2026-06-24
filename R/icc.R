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
    if (!is.null(seed)) set.seed(seed)
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
        stop("Package 'glmmTMB' is required to extract variance from NB models.",
             call. = FALSE)
      }
      vc <- glmmTMB::VarCorr(model_result$model)
      as.numeric(vc$cond[[1L]])
    } else {
      if (!requireNamespace("lme4", quietly = TRUE)) {
        stop("Package 'lme4' is required to extract variance from Poisson models.",
             call. = FALSE)
      }
      vc <- lme4::VarCorr(model_result$model)
      as.numeric(vc[[1L]])
    }
  }, error = function(e) {
    stop("Could not extract random-intercept variance: ", conditionMessage(e),
         call. = FALSE)
  })
}

.compute_icc <- function(sigma2_u, is_nb, theta) {
  pi2_3 <- pi^2 / 3
  if (is_nb && !is.null(theta) && !is.na(theta) && theta > 0) {
    denom <- sigma2_u + psigamma(1 / theta, deriv = 1L) + pi2_3
  } else {
    if (is_nb) {
      message("theta is NA/NULL; falling back to Poisson latent-variable ICC formula.")
    }
    denom <- sigma2_u + pi2_3
  }
  sigma2_u / denom
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
    cat(sprintf("  %d%% CI  = [%.4f, %.4f]  (%d bootstrap replicates)\n",
                round(x$n_boot), x$ci[1], x$ci[2], x$n_boot))
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
