# Regression tests for the defects an independent review found in the
# statistical-accessor and convergence work. Each block names the failure it
# guards, so a future change that reintroduces it fails here rather than in
# a manuscript.

mc_rf_counts <- function(seed = 42L, n_phys = 20L, per = 6L) {
  set.seed(seed)
  d <- data.frame(
    phys = rep(sprintf("P%02d", seq_len(n_phys)), each = per),
    ins = rep(c("BCBS", "Medicaid"), length.out = n_phys * per),
    stringsAsFactors = FALSE
  )
  d$wait <- stats::rpois(nrow(d), 12)
  d$exposure <- 1
  d
}

fit_pois <- function(...) {
  suppressMessages(suppressWarnings(mysterycall_poisson_model(...)))
}

# -- confint() must not contradict the table the object reports -------------
#
# It defaulted to level = 0.95 regardless of the conf_level the model was
# fitted with, so a study pre-registered at 90% that quoted confint()
# published a 95% interval with no warning.

test_that("confint() defaults to the level the model was fitted with", {
  skip_if_not_installed("lme4")
  d <- mc_rf_counts()

  for (lv in c(0.95, 0.90, 0.80)) {
    fit <- fit_pois(d, "wait", "ins", "phys", conf_level = lv)
    ci <- stats::confint(fit)
    expect_equal(unname(ci[, 1L]), log(fit$irr_table$ci_lower),
                 info = sprintf("conf_level = %.2f", lv))
    expect_equal(unname(ci[, 2L]), log(fit$irr_table$ci_upper),
                 info = sprintf("conf_level = %.2f", lv))
  }
})

test_that("confint() still honours an explicitly supplied level", {
  skip_if_not_installed("lme4")
  d <- mc_rf_counts()
  fit90 <- fit_pois(d, "wait", "ins", "phys", conf_level = 0.90)
  fit95 <- fit_pois(d, "wait", "ins", "phys", conf_level = 0.95)

  expect_equal(
    unname(stats::confint(fit90, level = 0.95)[, 1L]),
    log(fit95$irr_table$ci_lower)
  )
  # And an explicit level genuinely differs from the fitted default.
  expect_false(isTRUE(all.equal(
    unname(stats::confint(fit90, level = 0.95)[, 1L]),
    unname(stats::confint(fit90)[, 1L])
  )))
})

test_that("confint() on an LMM uses the t quantile the fitter uses", {
  skip_if_not_installed("lme4")
  # Small residual df is exactly where a normal quantile is anticonservative,
  # which is why mysterycall_lmm() reports Satterthwaite t intervals.
  set.seed(42)
  n <- 24L
  d <- data.frame(
    wait = stats::rnorm(n, 20, 5),
    ins = rep(c("BCBS", "Medicaid"), length.out = n),
    phys = rep(paste0("Dr_", seq_len(6)), each = 4L),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(d, "wait", "ins", "phys")))
  ci <- stats::confint(fit)

  expect_equal(unname(ci[, 1L]), fit$coef_table$ci_lower)
  expect_equal(unname(ci[, 2L]), fit$coef_table$ci_upper)
  # A normal quantile would be strictly narrower here; confirm we did not
  # silently use one.
  z_lower <- fit$coef_table$estimate -
    stats::qnorm(0.975) * fit$coef_table$se
  expect_true(all(ci[, 1L] < z_lower))
})

test_that("confint() rejects an out-of-range level", {
  skip_if_not_installed("lme4")
  fit <- fit_pois(mc_rf_counts(), "wait", "ins", "phys")
  expect_error(stats::confint(fit, level = 0), "strictly between 0 and 1")
  expect_error(stats::confint(fit, level = 1), "strictly between 0 and 1")
})

# -- A boundary-singular fit has converged ----------------------------------
#
# lme4 writes "boundary (singular) fit" into optinfo$conv$lme4$messages, the
# same slot as real convergence failures, so testing that slot for
# emptiness reported every singular fit as non-convergent. Singular random
# intercepts are common when each physician is called only a few times.

test_that("a singular fit with optimizer code 0 is reported as converged", {
  skip_if_not_installed("lme4")
  set.seed(99)
  n <- 200L
  d <- data.frame(
    wait = stats::rpois(n, 12),
    ins = rep(c("BCBS", "Medicaid"), length.out = n),
    phys = sample(sprintf("Dr_%02d", seq_len(50)), n, replace = TRUE),
    stringsAsFactors = FALSE
  )

  fit <- fit_pois(d, "wait", "ins", "phys")

  expect_equal(fit$model@optinfo$conv$opt, 0L)
  expect_true(fit$convergence$singular)
  # Singularity is a property of the data, reported in its own field.
  expect_true(fit$convergence$converged)
})

# -- summary() must work for every class it is registered on ----------------
#
# .mc_model_summary() hard-coded irr_table / fit_warnings, which only the two
# count classes have, so an LMM or logistic summary printed a bare header and
# claimed zero fit warnings whether or not any had occurred.

test_that("summary() reports coefficients for every fitted class", {
  skip_if_not_installed("lme4")
  d <- mc_rf_counts()
  d$offered <- as.integer(d$wait < 12)

  pois <- fit_pois(d, "wait", "ins", "phys")
  logi <- suppressMessages(suppressWarnings(
    mysterycall_logistic_model(d, "offered", "ins", "phys")))
  lmm <- suppressMessages(suppressWarnings(
    mysterycall_lmm(d, "wait", "ins", "phys")))
  fits <- list(pois, logi, lmm)
  if (requireNamespace("glmmTMB", quietly = TRUE)) {
    d$wait_od <- stats::rnbinom(nrow(d), mu = 12, size = 4)
    fits <- c(fits, list(suppressMessages(suppressWarnings(
      mysterycall_nb_model(d, "wait_od", "ins", "phys")))))
  }

  for (fit in fits) {
    s <- base::summary(fit)
    expect_s3_class(s, "mysterycall_model_summary")
    expect_false(is.null(s$coefficients))
    expect_true(nrow(s$coefficients) > 0L)
    expect_output(print(s), "Fixed effects")
  }
})

test_that("summary() does not fabricate a fit-warning count", {
  skip_if_not_installed("lme4")
  d <- mc_rf_counts()
  lmm <- suppressMessages(suppressWarnings(
    mysterycall_lmm(d, "wait", "ins", "phys")))

  # The LMM class does not record warnings separately, so the summary must
  # say so rather than print "0".
  expect_false(base::summary(lmm)$has_fit_warnings)
  expect_output(print(base::summary(lmm)), "not recorded separately")

  pois <- fit_pois(d, "wait", "ins", "phys")
  expect_true(base::summary(pois)$has_fit_warnings)
})

# -- Cohort-altering arguments are refused by name --------------------------
#
# `subset` is a documented glmer argument forwarded through `...`. Passing it
# made the engine fit fewer rows than the reported cohort, which the cohort
# assertion then reported as the engine dropping rows "on its own" -- sending
# the analyst to hunt a nonexistent offset problem.

test_that("subset and na.action are refused with an actionable message", {
  skip_if_not_installed("lme4")
  d <- mc_rf_counts()

  expect_error(
    mysterycall_poisson_model(d, "wait", "ins", "phys",
                              subset = rep(TRUE, nrow(d))),
    "does not accept `subset`"
  )
  expect_error(
    mysterycall_poisson_model(d, "wait", "ins", "phys",
                              subset = rep(TRUE, nrow(d))),
    "Filter `data` before calling"
  )
  expect_error(
    mysterycall_poisson_model(d, "wait", "ins", "phys",
                              na.action = stats::na.exclude),
    "does not accept `na.action`"
  )
})

test_that("other dots arguments still reach the engine", {
  skip_if_not_installed("lme4")
  d <- mc_rf_counts()

  # Assert the argument actually arrived, not merely that the fit ran: the
  # optimizer name is recorded on the fitted object, so a dropped `...`
  # would show the lme4 default instead.
  fit <- fit_pois(d, "wait", "ins", "phys",
                  control = lme4::glmerControl(optimizer = "Nelder_Mead"))
  expect_equal(fit$model@optinfo$optimizer, "Nelder_Mead")

  fit2 <- fit_pois(d, "wait", "ins", "phys",
                   control = lme4::glmerControl(optimizer = "bobyqa"))
  expect_equal(fit2$model@optinfo$optimizer, "bobyqa")
})

test_that("partial argument matching cannot bypass the dots guard", {
  skip_if_not_installed("lme4")
  d <- mc_rf_counts()

  # R matches arguments partially, so `subs =` reaches lme4::glmer()'s
  # `subset` formal. An exact-name check waved it through, and the cohort
  # assertion then blamed the offset.
  expect_error(
    mysterycall_poisson_model(d, "wait", "ins", "phys",
                              subs = rep(c(TRUE, FALSE), nrow(d) / 2L)),
    "does not accept `subs`"
  )
  expect_error(
    mysterycall_poisson_model(d, "wait", "ins", "phys",
                              na.ac = stats::na.exclude),
    "does not accept `na.ac`"
  )
})

test_that("a clean fit stays converged however many warnings it emits", {
  skip_if_not_installed("lme4")
  # More than 10 distinct non-convergence warnings, which overflows the cap
  # in summarise_fit_warnings(). The overflow sentinel used to contain the
  # word "convergence" and so re-entered the convergence set, making the
  # convergence verdict depend on how many distinct warnings fired.
  set.seed(3)
  n <- 240L
  d <- data.frame(
    phys = rep(sprintf("P%02d", seq_len(40)), each = 6L),
    ins = rep(c("BCBS", "Medicaid"), length.out = n),
    stringsAsFactors = FALSE
  )
  d$wait <- stats::rpois(n, 12) + 0.5

  fit <- fit_pois(d, "wait", "ins", "phys")

  expect_equal(fit$model@optinfo$conv$opt, 0L)
  expect_length(fit$model@optinfo$conv$lme4$messages, 0L)
  expect_true(fit$convergence$converged)
  expect_gt(length(fit$fit_warnings), 10L)
})

test_that("a non-constant dispformula yields a usable dispersion", {
  skip_if_not_installed("glmmTMB")
  d <- mc_rf_counts()
  d$wait_od <- stats::rnbinom(nrow(d), mu = 12, size = 4)

  # The hand-rolled NB2 formula divided by sqrt(mu + mu^2/theta), and
  # sigma() returns NA when the dispersion is not a single scalar, so every
  # residual came out NA and sum(na.rm = TRUE) reported a dispersion of
  # exactly 0 -- read as extreme underdispersion. The engine's own Pearson
  # residuals are computable here, so the statistic is real.
  fit <- suppressMessages(suppressWarnings(mysterycall_nb_model(
    d, "wait_od", "ins", "phys", dispformula = ~ins)))

  expect_true(is.na(fit$theta))
  expect_true(is.finite(fit$overdispersion))
  expect_gt(fit$overdispersion, 0)
  expect_equal(fit$dispersion_details$n_pearson_na, 0L)
  # The NA guard remains for the case where no residual is computable at
  # all; no public input reaches it now, so it is not asserted here.
})

test_that("a zero-inflated fit reports the zero-inflated dispersion", {
  skip_if_not_installed("glmmTMB")
  set.seed(11)
  n <- 400L
  d <- data.frame(
    phys = rep(sprintf("P%02d", seq_len(50)), each = 8L),
    ins = rep(c("BCBS", "Medicaid"), length.out = n),
    stringsAsFactors = FALSE
  )
  mu0 <- exp(log(12) + 0.3 * (d$ins == "Medicaid"))
  d$wait <- stats::rnbinom(n, mu = mu0, size = 5) * stats::rbinom(n, 1, 0.7)

  fit <- suppressMessages(suppressWarnings(mysterycall_nb_model(
    d, "wait", "ins", "phys", ziformula = ~1)))

  # Independent reference: the Pearson statistic formed from the
  # zero-inflated mean and the zero-inflated variance.
  m <- fit$model
  p0 <- stats::predict(m, type = "zprob")
  mu <- stats::predict(m, type = "conditional")
  th <- stats::sigma(m)
  var_zi <- (1 - p0) * mu * (1 + mu / th + p0 * mu)
  reference <- sum(((d$wait - (1 - p0) * mu)^2) / var_zi) /
    fit$dispersion_details$df

  expect_gt(mean(p0), 0.1)
  expect_equal(fit$overdispersion, reference, tolerance = 1e-8)
  # The superseded conditional-variance formula inflated this to ~2.5.
  expect_lt(fit$overdispersion, 1.5)
})

test_that("a model without zero-inflation is numerically unchanged", {
  skip_if_not_installed("glmmTMB")
  set.seed(77)
  n <- 300L
  d <- data.frame(
    phys = rep(sprintf("P%02d", seq_len(50)), each = 6L),
    ins = rep(c("BCBS", "Medicaid", "Medicare"), length.out = n),
    stringsAsFactors = FALSE
  )
  d$wait <- stats::rnbinom(
    n, mu = exp(log(10) + 0.25 * (d$ins == "Medicaid")), size = 3)

  fit <- suppressMessages(suppressWarnings(mysterycall_nb_model(
    d, "wait", "ins", "phys")))

  # The superseded hand-rolled NB2 formula, recomputed here: for a model
  # with no zero-inflation it must agree exactly, so switching to the
  # engine's residuals changed no previously reported value.
  m <- fit$model
  y <- d$wait
  y_hat <- stats::fitted(m)
  th <- stats::sigma(m)
  superseded <- sum(((y - y_hat) /
    sqrt(y_hat + y_hat^2 / max(th, 0.001)))^2, na.rm = TRUE) /
    fit$dispersion_details$df

  expect_equal(fit$overdispersion, superseded)
})

test_that("the dispersion details stay auditable", {
  skip_if_not_installed("lme4")
  fit <- fit_pois(mc_rf_counts(), "wait", "ins", "phys")
  det <- fit$dispersion_details

  expect_false(is.na(det$n_pearson_na))
  expect_true(nzchar(det$method))
  expect_match(det$formula, "pearson")
  # The identity the reader is invited to check must actually hold.
  expect_equal(fit$overdispersion, det$pearson_chisq / det$df)
  expect_match(det$assumptions, "ziformula|zero-inflat")
})

test_that("an offset error names rows in the caller's frame", {
  skip_if_not_installed("lme4")
  d <- mc_rf_counts()
  d$exposure[1:5] <- NA_real_
  d$exposure[6] <- 0

  # Row 6 is the real offender. Validating the filtered cohort made the
  # message say "row 1", which is an NA row in the caller's data.
  expect_error(
    fit_pois(d, "wait", "ins", "phys", offset_col = "exposure"),
    "row\\(s\\) 6"
  )
})

# -- Validation order must not reject legitimately excluded rows ------------
#
# Checking the whole supplied column meant a row that the complete-case
# filter would have removed anyway -- a practice with no recorded wait and a
# zero observation window -- aborted the entire analysis.

test_that("a bad exposure on an already-excluded row does not abort", {
  skip_if_not_installed("lme4")
  d <- mc_rf_counts()
  d$exposure[3L] <- 0
  d$wait[3L] <- NA_integer_

  fit <- fit_pois(d, "wait", "ins", "phys", offset_col = "exposure")

  expect_equal(fit$n_dropped, 1L)
  expect_equal(fit$n, nrow(d) - 1L)
})

test_that("a bad exposure on an included row still aborts", {
  skip_if_not_installed("lme4")
  d <- mc_rf_counts()
  d$exposure[3L] <- 0

  expect_error(
    fit_pois(d, "wait", "ins", "phys", offset_col = "exposure"),
    "strictly positive and finite"
  )
})

test_that("NaN exposure errors even though complete.cases would drop it", {
  skip_if_not_installed("lme4")
  d <- mc_rf_counts()
  d$exposure[3L] <- NaN

  expect_error(
    fit_pois(d, "wait", "ins", "phys", offset_col = "exposure"),
    "NaN is not a missing exposure"
  )
})

test_that("a NaN outcome is refused rather than counted as missing", {
  skip_if_not_installed("lme4")
  d <- mc_rf_counts()
  # complete.cases() cannot tell NaN from NA, so without this check a NaN
  # outcome would be excluded silently and reported as missing data. The
  # asymmetry with the offset is deliberate: an invalid outcome is never a
  # declared exclusion, so it is refused wherever it appears.
  d$wait[5L] <- NaN
  expect_error(
    fit_pois(d, "wait", "ins", "phys"),
    "NaN is not a missing outcome"
  )
})

# -- The adversarial NB fixture must fit a usable model ---------------------
#
# It generated Poisson counts with unit exposure and then fitted nbinom2, so
# theta was unidentifiable: optimizer code 1, non-positive-definite Hessian,
# NA AIC. Every nb assertion in the adversarial suite was validated against
# standard errors from that fit.

test_that("the adversarial NB fixture yields a converged, usable fit", {
  skip_if_not_installed("glmmTMB")

  fit <- suppressMessages(suppressWarnings(mc_adv_fit(mc_adv_calls(), "nb")))

  expect_true(fit$convergence$converged)
  expect_equal(fit$model$fit$convergence, 0L)
  expect_true(isTRUE(fit$model$sdr$pdHess))
  expect_true(is.finite(fit$aic))
  # theta is identifiable and finite. The fixture simulates size = 30, and
  # theta-hat for a mildly overdispersed sample of 180 is noisy, so the
  # bound is loose on purpose: what matters is that it is estimable at all,
  # which it was not when the fixture generated Poisson counts.
  expect_true(is.finite(fit$theta))
  expect_gt(fit$theta, 1)
  expect_lt(fit$theta, 1e4)
})

test_that("the adversarial Poisson fixture also converges", {
  skip_if_not_installed("lme4")
  fit <- suppressMessages(suppressWarnings(
    mc_adv_fit(mc_adv_calls(), "poisson")))
  expect_true(fit$convergence$converged)
})
