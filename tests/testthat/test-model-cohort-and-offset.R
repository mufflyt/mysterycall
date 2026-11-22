# Regression tests for the model cohort / exposure defects found in the
# Poisson-NB audit, plus independent numerical reference checks.
#
# The defect that motivated this file: with a non-positive exposure column,
# offset(log(exposure)) is -Inf or NaN, lme4 drops those rows under its own
# na.action, and the returned object still reported n = 120 / n_dropped = 0
# while the model had actually been fitted on 117 rows. Every denominator
# downstream of that object was wrong, and nothing said so.

# -- Synthetic fixture (no research data) -------------------------------------
make_calls <- function(n_phys = 40L, seed = 2026L) {
  set.seed(seed)
  phys <- sprintf("P%03d", seq_len(n_phys))
  re <- stats::rnorm(n_phys, 0, 0.3)
  names(re) <- phys
  d <- data.frame(
    physician = rep(phys, each = 2L),
    insurance = rep(c("Medicaid", "Private"), times = n_phys),
    stringsAsFactors = FALSE
  )
  eta <- 2.0 + 0.35 * (d$insurance == "Medicaid") + re[d$physician]
  d$wait <- stats::rpois(nrow(d), exp(eta))
  d$exposure <- stats::runif(nrow(d), 1, 3)
  d$wait_od <- stats::rnbinom(nrow(d), mu = exp(eta), size = 1.5)
  d
}

fit_quietly <- function(...) {
  suppressMessages(suppressWarnings(mysterycall_poisson_model(...)))
}

# -- validate_log_offset() ----------------------------------------------------

test_that("validate_log_offset accepts strictly positive finite exposure", {
  expect_true(validate_log_offset(c(0.5, 1, 100), "exposure"))
})

test_that("validate_log_offset rejects zero, negative and non-finite", {
  expect_error(
    validate_log_offset(c(1, 0, 2), "exposure"),
    "strictly positive and finite"
  )
  expect_error(
    validate_log_offset(c(1, -1, 2), "exposure"),
    "strictly positive and finite"
  )
  expect_error(
    validate_log_offset(c(1, Inf, 2), "exposure"),
    "strictly positive and finite"
  )
  # The message must not promise a silent substitution.
  expect_error(
    validate_log_offset(c(1, 0), "exposure"),
    "not replaced with a small constant"
  )
  expect_error(
    validate_log_offset(c("a", "b"), "exposure"),
    "must be numeric"
  )
})

test_that("validate_log_offset reports how many values are bad and where", {
  expect_error(
    validate_log_offset(c(1, 0, 0, 2), "exposure"),
    "2 of 4 value\\(s\\)"
  )
  expect_error(
    validate_log_offset(c(1, 0, 0, 2), "exposure"),
    "row\\(s\\) 2, 3"
  )
})

# -- assert_model_cohort() ----------------------------------------------------

test_that("assert_model_cohort passes when the counts agree", {
  stub <- structure(list(), class = "mc_cohort_stub")
  local_mocked_bindings(
    nobs = function(object, ...) 100L,
    .package = "stats"
  )
  expect_equal(assert_model_cohort(stub, 100L, "fn"), 100L)
})

test_that("assert_model_cohort errors when the engine dropped rows", {
  stub <- structure(list(), class = "mc_cohort_stub")
  local_mocked_bindings(
    nobs = function(object, ...) 97L,
    .package = "stats"
  )
  expect_error(
    assert_model_cohort(stub, 100L, "mysterycall_poisson_model"),
    "used 97 row\\(s\\) but 100 complete case\\(s\\)"
  )
  expect_error(
    assert_model_cohort(stub, 100L, "mysterycall_poisson_model"),
    "dropped 3 row\\(s\\) on its own"
  )
})

# -- summarise_fit_warnings() -------------------------------------------------

test_that("summarise_fit_warnings dedupes and caps the message flood", {
  expect_equal(summarise_fit_warnings(character(0)), character(0))
  expect_equal(
    summarise_fit_warnings(rep("same warning", 500L)),
    "same warning"
  )

  many <- sprintf("non-integer x = %f", seq_len(120))
  out <- summarise_fit_warnings(many, max_shown = 10L)
  expect_length(out, 11L)
  expect_match(out[[11L]], "110 further distinct non-convergence warning")
})

test_that("a convergence warning is never discarded by the cap", {
  # The failure this guards: one data problem emits a warning per
  # observation, and the single warning that matters -- glmmTMB's
  # "extreme or very small eigenvalues detected", the only signal for a
  # numerically singular covariance when the optimizer code is 0 -- arrives
  # last and was dropped, leaving the object claiming the fit converged.
  flood <- sprintf("non-integer x = %f", seq_len(120) + 0.5)
  conv <- "Model convergence problem; extreme or very small eigenvalues"

  out <- summarise_fit_warnings(c(flood, conv), max_shown = 10L)

  expect_true(any(grepl("eigenvalue", out, fixed = TRUE)))
  # Convergence messages come first, so a reader sees them.
  expect_match(out[[1L]], "eigenvalue")
})

test_that("the convergence pattern excludes singularity by design", {
  pat <- .mc_conv_warning_pattern()
  expect_false(grepl(pat, "boundary (singular) fit", ignore.case = TRUE))
  expect_true(grepl(pat, "failed to converge", ignore.case = TRUE))
  expect_true(grepl(pat, "non-positive-definite Hessian", ignore.case = TRUE))
  expect_true(grepl(pat, "extreme or very small eigenvalues",
                    ignore.case = TRUE))
})

# -- The cohort defect, end to end -------------------------------------------

test_that("non-positive exposure is refused instead of shrinking the cohort", {
  skip_if_not_installed("lme4")
  d <- make_calls()

  d_zero <- d
  d_zero$exposure[1:3] <- 0
  expect_error(
    fit_quietly(d_zero, "wait", "insurance", "physician",
                offset_col = "exposure"),
    "strictly positive and finite"
  )

  d_neg <- d
  d_neg$exposure[1:3] <- -1
  expect_error(
    fit_quietly(d_neg, "wait", "insurance", "physician",
                offset_col = "exposure"),
    "strictly positive and finite"
  )
})

test_that("a valid offset fits and the reported cohort matches the model", {
  skip_if_not_installed("lme4")
  d <- make_calls()

  fit <- fit_quietly(d, "wait", "insurance", "physician",
                     offset_col = "exposure")

  expect_equal(fit$n, nrow(d))
  expect_equal(fit$n, as.integer(stats::nobs(fit$model)))
  expect_equal(fit$n_dropped, 0L)
})

test_that("missing exposure is dropped by the documented route and counted", {
  skip_if_not_installed("lme4")
  d <- make_calls()
  d$exposure[1:3] <- NA_real_

  fit <- fit_quietly(d, "wait", "insurance", "physician",
                     offset_col = "exposure")

  # Dropped through the package's complete-case filter, which reports it,
  # not by the engine behind the caller's back.
  expect_equal(fit$n_dropped, 3L)
  expect_equal(fit$n, nrow(d) - 3L)
  expect_equal(fit$n, as.integer(stats::nobs(fit$model)))
})

# -- Non-integer outcome ------------------------------------------------------

test_that("a non-integer count outcome warns, naming the column", {
  skip_if_not_installed("lme4")
  d <- make_calls()
  d$wait <- d$wait + 0.5

  expect_warning(
    suppressMessages(mysterycall_poisson_model(
      d, "wait", "insurance", "physician")),
    "`wait` is not integer-valued"
  )
})

test_that("engine warnings are no longer stored one per observation", {
  skip_if_not_installed("lme4")
  d <- make_calls()
  d$wait <- d$wait + 0.5

  fit <- fit_quietly(d, "wait", "insurance", "physician")

  # Previously this held one "non-integer x = ..." string per row.
  expect_lt(length(fit$convergence$messages), nrow(d))
})

test_that("integer-valued outcomes do not trigger the warning", {
  d <- make_calls()
  expect_silent(warn_non_integer_counts(d$wait, "wait"))
  expect_silent(warn_non_integer_counts(c(0, 1, 2, NA), "wait"))
})

# -- Independent numerical references ----------------------------------------

test_that("Poisson fixed effects match a direct lme4::glmer fit", {
  skip_if_not_installed("lme4")
  d <- make_calls()

  fit <- fit_quietly(d, "wait", "insurance", "physician")
  ref <- suppressWarnings(lme4::glmer(
    wait ~ insurance + (1 | physician),
    data = d, family = stats::poisson(link = "log"), nAGQ = 0L
  ))
  ref_fe <- stats::coef(summary(ref))

  # Same optimizer, same data: agreement should be exact, not approximate.
  expect_equal(fit$irr_table$estimate, unname(ref_fe[, "Estimate"]))
  expect_equal(fit$irr_table$se, unname(ref_fe[, "Std. Error"]))
  expect_equal(fit$irr_table$p_value, unname(ref_fe[, "Pr(>|z|)"]))
})

test_that("IRR and Wald CI are the documented transforms of the estimate", {
  skip_if_not_installed("lme4")
  d <- make_calls()
  fit <- fit_quietly(d, "wait", "insurance", "physician")

  z <- stats::qnorm(0.975)
  expect_equal(fit$irr_table$irr, exp(fit$irr_table$estimate))
  expect_equal(
    fit$irr_table$ci_lower,
    exp(fit$irr_table$estimate - z * fit$irr_table$se)
  )
  expect_equal(
    fit$irr_table$ci_upper,
    exp(fit$irr_table$estimate + z * fit$irr_table$se)
  )
})

test_that("conf_level widens and narrows the interval it is given", {
  skip_if_not_installed("lme4")
  d <- make_calls()

  f95 <- fit_quietly(d, "wait", "insurance", "physician", conf_level = 0.95)
  f80 <- fit_quietly(d, "wait", "insurance", "physician", conf_level = 0.80)

  z80 <- stats::qnorm(0.90)
  expect_equal(
    f80$irr_table$ci_lower,
    exp(f80$irr_table$estimate - z80 * f80$irr_table$se)
  )
  # Point estimates are identical; only the interval changes.
  expect_equal(f95$irr_table$estimate, f80$irr_table$estimate)
  expect_true(all(f80$irr_table$ci_lower > f95$irr_table$ci_lower))
})

test_that("negative binomial fixed effects match a direct glmmTMB fit", {
  skip_if_not_installed("glmmTMB")
  d <- make_calls()

  fit <- suppressMessages(suppressWarnings(mysterycall_nb_model(
    d, "wait_od", "insurance", "physician")))
  ref <- suppressWarnings(glmmTMB::glmmTMB(
    wait_od ~ insurance + (1 | physician),
    data = d, family = glmmTMB::nbinom2(link = "log")
  ))
  ref_fe <- stats::coef(summary(ref))$cond

  expect_equal(unname(fit$irr_table$estimate), unname(ref_fe[, "Estimate"]))
  expect_equal(unname(fit$irr_table$se), unname(ref_fe[, "Std. Error"]))
  expect_equal(unname(fit$irr_table$irr), exp(unname(ref_fe[, "Estimate"])))
})

test_that("negative binomial refuses a non-positive offset too", {
  skip_if_not_installed("glmmTMB")
  d <- make_calls()
  d$exposure[1:3] <- 0

  expect_error(
    suppressMessages(suppressWarnings(mysterycall_nb_model(
      d, "wait_od", "insurance", "physician", offset_col = "exposure"))),
    "strictly positive and finite"
  )
})

# -- Invariants (property-style) ---------------------------------------------

test_that("row order does not change the estimates", {
  skip_if_not_installed("lme4")
  d <- make_calls()
  set.seed(11)
  d_perm <- d[sample(nrow(d)), , drop = FALSE]

  fit <- fit_quietly(d, "wait", "insurance", "physician")
  fit_perm <- fit_quietly(d_perm, "wait", "insurance", "physician")

  # Tolerance covers optimizer path differences from row ordering alone.
  expect_equal(fit$irr_table$estimate, fit_perm$irr_table$estimate,
               tolerance = 1e-6)
  expect_equal(fit$n, fit_perm$n)
})

test_that("relevelling the predictor inverts the IRR it reports", {
  skip_if_not_installed("lme4")
  d <- make_calls()
  d$insurance <- factor(d$insurance)
  d_rel <- d
  d_rel$insurance <- stats::relevel(d_rel$insurance, ref = "Private")

  fit <- fit_quietly(d, "wait", "insurance", "physician")
  fit_rel <- fit_quietly(d_rel, "wait", "insurance", "physician")

  expect_equal(fit$factor_refs$insurance, "Medicaid")
  expect_equal(fit_rel$factor_refs$insurance, "Private")
  # Same comparison, opposite direction: the two IRRs must be reciprocal.
  expect_equal(fit$irr_table$irr[[2L]] * fit_rel$irr_table$irr[[2L]], 1,
               tolerance = 1e-6)
})

test_that("a character predictor and its factor give the same fit", {
  skip_if_not_installed("lme4")
  d <- make_calls()
  d_fac <- d
  d_fac$insurance <- factor(d_fac$insurance)

  fit <- fit_quietly(d, "wait", "insurance", "physician")
  fit_fac <- fit_quietly(d_fac, "wait", "insurance", "physician")

  expect_equal(fit$factor_refs, fit_fac$factor_refs)
  expect_equal(fit$irr_table$estimate, fit_fac$irr_table$estimate)
})

# -- The cohort invariant on the other engine-backed fitters ------------------
#
# assert_model_cohort() is a mandatory invariant for every fitter that
# reports a cohort size a reader would quote, not only the two count models:
# mysterycall_lmm(), mysterycall_logistic_model() and mysterycall_gee() all
# return an `n` and all delegate to an engine that applies its own na.action.
#
# Scope note: these assertions exercise the invariant's satisfied path. No
# public input to these three fitters can now make an engine drop a row --
# cohort-altering arguments are refused by name and the offset is validated
# -- so removing the three call sites would not make these tests fail. The
# helper's detecting behaviour is covered directly by the two
# assert_model_cohort() unit tests above, which a mutation does break.

test_that("mysterycall_lmm reports the cohort the engine fitted", {
  skip_if_not_installed("lme4")
  d <- make_calls()

  fit <- suppressMessages(suppressWarnings(mysterycall_lmm(
    d, "wait", "insurance", "physician")))

  expect_equal(fit$n, as.integer(stats::nobs(fit$model)))
})

test_that("mysterycall_lmm cohort invariant survives missing predictors", {
  skip_if_not_installed("lme4")
  d <- make_calls()
  d$insurance[1:4] <- NA_character_

  fit <- suppressMessages(suppressWarnings(mysterycall_lmm(
    d, "wait", "insurance", "physician")))

  expect_equal(fit$n, as.integer(stats::nobs(fit$model)))
  expect_equal(fit$n + fit$n_dropped, nrow(d))
})

test_that("mysterycall_logistic_model reports the fitted cohort", {
  skip_if_not_installed("lme4")
  d <- make_calls()
  d$offered <- as.integer(d$wait < stats::median(d$wait))

  fit <- suppressMessages(suppressWarnings(mysterycall_logistic_model(
    d, "offered", "insurance", "physician")))

  expect_equal(fit$n, as.integer(stats::nobs(fit$model)))
  expect_equal(fit$n + fit$n_dropped, nrow(d))
})

test_that("mysterycall_gee reports a cohort consistent with its fit", {
  skip_if_not_installed("geepack")
  d <- make_calls()
  d$offered <- as.integer(d$wait < stats::median(d$wait))

  fit <- suppressMessages(suppressWarnings(mysterycall_gee(
    d, outcome = "offered", predictors = "insurance",
    cluster = "physician")))

  # geepack may not implement nobs(); the invariant degrades to a no-op
  # rather than failing, so assert only what is actually knowable here.
  n_engine <- tryCatch(as.integer(stats::nobs(fit$model)),
                       error = function(e) NA_integer_)
  if (!is.na(n_engine)) {
    expect_equal(fit$n, n_engine)
  }
  expect_true(fit$n > 0L)
})
