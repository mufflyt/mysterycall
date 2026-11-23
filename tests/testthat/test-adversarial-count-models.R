# Adversarial contract tests for mysterycall Poisson and NB fitters.
# Designed to fail on incomplete implementations; no conditional skips.
# Execute within the package's tests/testthat directory.

# mc_adv_calls(), mc_adv_fit() and mc_adv_families are defined in
# helper-adversarial.R, so that test-adversarial-wiring.R -- which runs
# in a separate environment -- can use the same fixtures. No assertion
# in this file has been changed.


for (family_name in mc_adv_families) {
  base::local({
    family_id <- family_name

    testthat::test_that(
      base::sprintf("%s rejects every invalid finite offset", family_id), {
        for (invalid_value in base::c(-2, 0, Inf, -Inf, NaN)) {
          sample_calls <- mc_adv_calls()
          sample_calls$exposure[3] <- invalid_value
          testthat::expect_error(
            mc_adv_fit(sample_calls, family_id),
            regexp = "offset|exposure|positive|finite|non.finite",
            info = base::sprintf("%s value=%s", family_id,
                                 base::as.character(invalid_value))
          )
        }
      }
    )

    testthat::test_that(
      base::sprintf("%s missing exposure has honest denominator", family_id), {
        sample_calls <- mc_adv_calls()
        sample_calls$exposure[3] <- NA_real_
        fitted_result <- mc_adv_fit(sample_calls, family_id)
        testthat::expect_identical(fitted_result$n, 179L)
        testthat::expect_identical(fitted_result$n_dropped, 1L)
        testthat::expect_equal(stats::nobs(fitted_result$model), 179)
        testthat::expect_identical(
          fitted_result$n + fitted_result$n_dropped,
          base::nrow(sample_calls)
        )
      }
    )

    testthat::test_that(
      base::sprintf("%s finite offset preserves all rows", family_id), {
        sample_calls <- mc_adv_calls()
        sample_calls$exposure <- base::seq(0.5, 1.5,
                                          length.out = base::nrow(sample_calls))
        fitted_result <- mc_adv_fit(sample_calls, family_id)
        testthat::expect_equal(stats::nobs(fitted_result$model), 180)
        testthat::expect_identical(fitted_result$n, 180L)
        testthat::expect_identical(fitted_result$n_dropped, 0L)
      }
    )

    testthat::test_that(
      base::sprintf("%s invalid outcomes never get rounded", family_id), {
        for (invalid_value in base::c(-1, Inf, -Inf, NaN)) {
          sample_calls <- mc_adv_calls()
          sample_calls$wait_days[1] <- invalid_value
          testthat::expect_error(
            mc_adv_fit(sample_calls, family_id),
            info = base::sprintf("%s outcome=%s", family_id,
                                 base::as.character(invalid_value))
          )
        }
      }
    )

    testthat::test_that(
      base::sprintf("%s noninteger warnings do not imply failure", family_id), {
        sample_calls <- mc_adv_calls()
        sample_calls$wait_days[1] <- 5.5
        captured_warnings <- base::character()
        fitted_result <- base::withCallingHandlers(
          mc_adv_fit(sample_calls, family_id),
          warning = function(warning_condition) {
            captured_warnings <<- base::c(
              captured_warnings, base::conditionMessage(warning_condition)
            )
            base::invokeRestart("muffleWarning")
          }
        )
        all_warnings <- base::c(
          captured_warnings, fitted_result$convergence$messages
        )
        testthat::expect_true(base::any(base::grepl(
          "non.integer|non-integer|integer", all_warnings,
          ignore.case = TRUE
        )))
        testthat::expect_true(base::isTRUE(fitted_result$convergence$converged),
                              info = "Noninteger warning is not optimizer failure")
      }
    )

    testthat::test_that(
      base::sprintf("%s strict count policy rejects fractions", family_id), {
        fitter <- base::switch(
          family_id,
          poisson = mysterycall::mysterycall_poisson_model,
          nb = mysterycall::mysterycall_nb_model
        )
        testthat::expect_true(
          "strict_counts" %in% base::names(base::formals(fitter)),
          info = "Add an explicit opt-in strict_counts argument"
        )
        sample_calls <- mc_adv_calls()
        sample_calls$wait_days[1] <- 5.5
        testthat::expect_error(
          fitter(sample_calls, "wait_days", "insurance", "physician",
                 strict_counts = TRUE),
          regexp = "integer|count"
        )
      }
    )

    testthat::test_that(
      base::sprintf("%s true numerical results equal engine", family_id), {
        fitted_result <- mc_adv_fit(mc_adv_calls(), family_id)
        engine_fit <- fitted_result$model
        engine_coef <- if (family_id == "poisson") {
          lme4::fixef(engine_fit)
        } else {
          glmmTMB::fixef(engine_fit)$cond
        }
        coef_table <- fitted_result$irr_table
        testthat::expect_equal(
          base::unname(coef_table$estimate),
          base::unname(engine_coef[coef_table$term]),
          tolerance = 1e-8
        )
        testthat::expect_equal(
          coef_table$irr, base::exp(coef_table$estimate),
          tolerance = 1e-10
        )
        testthat::expect_equal(
          coef_table$ci_lower,
          base::exp(coef_table$estimate -
            stats::qnorm(0.975) * coef_table$se),
          tolerance = 1e-8
        )
        testthat::expect_equal(
          coef_table$ci_upper,
          base::exp(coef_table$estimate +
            stats::qnorm(0.975) * coef_table$se),
          tolerance = 1e-8
        )
      }
    )

    testthat::test_that(
      base::sprintf("%s accessors are real, not NULL fallbacks", family_id), {
        fitted_result <- mc_adv_fit(mc_adv_calls(), family_id)
        engine_fit <- fitted_result$model
        engine_coef <- if (family_id == "poisson") {
          lme4::fixef(engine_fit)
        } else {
          glmmTMB::fixef(engine_fit)$cond
        }
        testthat::expect_equal(stats::coef(fitted_result), engine_coef)
        testthat::expect_equal(
          stats::nobs(fitted_result), stats::nobs(engine_fit)
        )
        testthat::expect_equal(
          stats::fitted(fitted_result), stats::fitted(engine_fit),
          tolerance = 1e-8
        )
        testthat::expect_true(base::is.matrix(stats::vcov(fitted_result)))
        testthat::expect_true(base::is.matrix(stats::confint(fitted_result)))
        testthat::expect_true(base::inherits(
          stats::formula(fitted_result), "formula"
        ))
        testthat::expect_equal(
          base::length(stats::residuals(fitted_result)),
          stats::nobs(engine_fit)
        )
        testthat::expect_false(base::is.null(base::summary(fitted_result)))
        testthat::expect_false(base::identical(
          base::class(base::summary(fitted_result)), "summaryDefault"
        ))
      }
    )

    testthat::test_that(
      base::sprintf("%s declared dispersion convention is reproducible",
                    family_id), {
        fitted_result <- mc_adv_fit(mc_adv_calls(), family_id)
        testthat::expect_true(base::is.finite(fitted_result$overdispersion))
        testthat::expect_true(fitted_result$overdispersion >= 0)
        testthat::expect_true(base::is.list(fitted_result$dispersion_details))
        testthat::expect_true(base::is.numeric(
          fitted_result$dispersion_details$df
        ))
        testthat::expect_true(base::is.character(
          fitted_result$dispersion_details$method
        ))
        testthat::expect_true(base::nzchar(
          fitted_result$dispersion_details$method
        ))
        testthat::expect_equal(
          fitted_result$overdispersion,
          fitted_result$dispersion_details$pearson_chisq /
            fitted_result$dispersion_details$df,
          tolerance = 1e-8
        )
      }
    )
  })
}
