# Test overdispersion in a fitted count model

Computes the Pearson chi-square dispersion statistic (phi = chi-sq /
residual df) for any fitted count model and returns a plain-language
interpretation. The calculation mirrors the `overdisp_fun()` approach
used in the mystery-caller Rmd analyses: Pearson residuals are squared
and summed, divided by the residual degrees of freedom, and tested
against a chi-square distribution.

## Usage

``` r
mysterycall_overdispersion_test(
  model,
  phi_thresholds = c(mild = 1.2, moderate = 1.5, severe = 2),
  digits = 3L
)
```

## Arguments

- model:

  A fitted model object. Supported classes:

  `glmerMod`

  :   From [`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html).

  `glm`

  :   From [`stats::glm()`](https://rdrr.io/r/stats/glm.html).

  `negbin`

  :   From [`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html).

  Any object that responds to
  [`residuals()`](https://rdrr.io/r/stats/residuals.html) with
  `type = "pearson"` and to
  [`df.residual()`](https://rdrr.io/r/stats/df.residual.html) is also
  accepted.

- phi_thresholds:

  Named numeric vector. Boundaries used to assign the verbal
  interpretation category. Must have names `"mild"`, `"moderate"`, and
  `"severe"` and must satisfy `mild < moderate < severe`. Default:
  `c(mild = 1.2, moderate = 1.5, severe = 2.0)`.

- digits:

  Integer. Number of decimal places for phi and the p-value in formatted
  output. Default `3L`.

## Value

A list of class `"mysterycall_overdispersion_test"` with elements:

- `phi`:

  Numeric. Pearson dispersion ratio (chi-sq / df).

- `pearson_chisq`:

  Numeric. Raw Pearson chi-square statistic.

- `df`:

  Integer. Residual degrees of freedom.

- `p_value`:

  Numeric. P-value from `pchisq(pearson_chisq, df, lower.tail = FALSE)`.

- `p_fmt`:

  Character. Formatted p-value (e.g. `"<0.001"`).

- `interpretation`:

  Character. One-sentence verbal category.

- `recommendation`:

  Character. One-sentence action sentence.

- `sentence`:

  Character. Combined summary sentence suitable for inline reporting.

## Details

This is the standalone export of the overdispersion check that
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
performs internally. Use it to diagnose any fitted count model *after*
fitting — including negative binomial models, where phi near 1.0
confirms that the dispersion was adequately absorbed.

## Interpretation thresholds

- phi \< 1.0:

  Underdispersion — the model may overfit.

- 1.0 \<= phi \< 1.2:

  No significant overdispersion.

- 1.2 \<= phi \< 1.5:

  Mild overdispersion.

- 1.5 \<= phi \< 2.0:

  Moderate overdispersion.

- phi \>= 2.0:

  Severe overdispersion.

## Mixed-effects caveat

For mixed-effects models (`glmmTMB`, `merMod`),
[`df.residual()`](https://rdrr.io/r/stats/df.residual.html) counts only
the fixed-effect parameters and ignores the effective degrees of freedom
consumed by the random effects, so phi is an **approximation** rather
than an exact dispersion ratio. The verbal interpretation accounts for
this by treating low residual phi as expected for negative-binomial and
mixed models (dispersion absorbed by the NB variance or random
intercepts) rather than as overfitting. For a formal simulation-based
check on a GLMM, prefer
[`DHARMa::testDispersion()`](https://rdrr.io/pkg/DHARMa/man/testDispersion.html).

## See also

[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
[`mysterycall_check_zero_inflation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_zero_inflation.md)

Other outcomes:
[`.as_positive_logical()`](https://mufflyt.github.io/mysterycall/reference/dot-as_positive_logical.md),
[`.disp_rate_ci()`](https://mufflyt.github.io/mysterycall/reference/dot-disp_rate_ci.md),
[`.fmt_model_pval()`](https://mufflyt.github.io/mysterycall/reference/dot-fmt_model_pval.md),
[`.fmt_pvalue()`](https://mufflyt.github.io/mysterycall/reference/dot-fmt_pvalue.md),
[`.me_find_mf_col()`](https://mufflyt.github.io/mysterycall/reference/dot-me_find_mf_col.md),
[`.me_mf_to_orig()`](https://mufflyt.github.io/mysterycall/reference/dot-me_mf_to_orig.md),
[`.wait_stats()`](https://mufflyt.github.io/mysterycall/reference/dot-wait_stats.md),
[`.wilson_ci()`](https://mufflyt.github.io/mysterycall/reference/dot-wilson_ci.md),
[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md),
[`mysterycall_acceptance_rate_calc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate_calc.md),
[`mysterycall_auto_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_auto_model.md),
[`mysterycall_bootstrap_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bootstrap_ci.md),
[`mysterycall_calendar_sensitivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_calendar_sensitivity.md),
[`mysterycall_caller_drift()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caller_drift.md),
[`mysterycall_check_zero_inflation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_zero_inflation.md),
[`mysterycall_forest_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_forest_plot.md),
[`mysterycall_icc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_icc.md),
[`mysterycall_icc_report()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_icc_report.md),
[`mysterycall_icc_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_icc_sentence.md),
[`mysterycall_impute_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_impute_calls.md),
[`mysterycall_insurance_acceptance_rates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_acceptance_rates.md),
[`mysterycall_insurance_wait_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_wait_sentence.md),
[`mysterycall_interaction_sentences()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_sentences.md),
[`mysterycall_interaction_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_table.md),
[`mysterycall_irr_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_plot.md),
[`mysterycall_irr_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_table.md),
[`mysterycall_kaplan_meier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_kaplan_meier.md),
[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md),
[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
[`mysterycall_marginal_effects()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_marginal_effects.md),
[`mysterycall_missing_data_analysis()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_missing_data_analysis.md),
[`mysterycall_model_gt()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_gt.md),
[`mysterycall_model_mae_rmse()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_mae_rmse.md),
[`mysterycall_model_metrics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_metrics.md),
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
[`mysterycall_nb_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_power.md),
[`mysterycall_plot_distribution()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_distribution.md),
[`mysterycall_plot_effect()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_effect.md),
[`mysterycall_plot_emmeans_full()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans_full.md),
[`mysterycall_plot_emmeans_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans_interaction.md),
[`mysterycall_plot_inclexcl()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_inclexcl.md),
[`mysterycall_plot_residuals()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_residuals.md),
[`mysterycall_plot_sjplot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_sjplot_interaction.md),
[`mysterycall_plot_stacked_bar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_stacked_bar.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_power_curve()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_power_curve.md),
[`mysterycall_predicted_means()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_predicted_means.md),
[`mysterycall_sample_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_demographics.md),
[`mysterycall_screen_interactions()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_screen_interactions.md),
[`mysterycall_screen_predictors()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_screen_predictors.md),
[`mysterycall_select_best_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_select_best_model.md),
[`mysterycall_sensitivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity.md),
[`mysterycall_simple_poisson()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_simple_poisson.md),
[`mysterycall_wait_time_by_group()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_by_group.md),
[`mysterycall_wait_time_crossover()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_crossover.md),
[`mysterycall_wait_time_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_sentence.md),
[`mysterycall_wait_time_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_summary.md),
[`plot.mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/plot.mysterycall_lmm.md),
[`print.mysterycall_acceptance_rate_calc()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_acceptance_rate_calc.md),
[`print.mysterycall_auto_model()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_auto_model.md),
[`print.mysterycall_calendar_sensitivity()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_calendar_sensitivity.md),
[`print.mysterycall_caller_drift()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_caller_drift.md),
[`print.mysterycall_icc()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_icc.md),
[`print.mysterycall_icc_report()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_icc_report.md),
[`print.mysterycall_impute_calls()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_impute_calls.md),
[`print.mysterycall_interaction_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_interaction_table.md),
[`print.mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_lmm.md),
[`print.mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_logistic_model.md),
[`print.mysterycall_missing_data()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_missing_data.md),
[`print.mysterycall_model_mae_rmse()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_mae_rmse.md),
[`print.mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_nb_model.md),
[`print.mysterycall_nb_power()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_nb_power.md),
[`print.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_poisson_model.md),
[`print.mysterycall_power_curve()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_power_curve.md),
[`print.mysterycall_predicted_means()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_predicted_means.md),
[`print.mysterycall_sensitivity()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_sensitivity.md),
[`print.mysterycall_wait_time_crossover()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_wait_time_crossover.md),
[`tidy.mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/tidy.mysterycall_lmm.md),
[`tidy.mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/tidy.mysterycall_logistic_model.md),
[`tidy.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/tidy.mysterycall_poisson_model.md)

## Examples

``` r
## Poisson GLM on count data ------------------------------------------------
set.seed(42)
n   <- 200
dat <- data.frame(
  y   = rpois(n, lambda = exp(0.5 + 0.3 * rnorm(n))),
  x1  = rnorm(n),
  grp = sample(c("A", "B"), n, replace = TRUE)
)
fit <- glm(y ~ x1 + grp, data = dat, family = poisson())
result <- mysterycall_overdispersion_test(fit)
print(result)
#> Pearson dispersion phi=1.240 (chi-sq=244, df=197, p=0.012): Mild overdispersion (phi=1.240). Negative binomial model may improve fit. 
#> Consider fitting a negative binomial model with mysterycall_nb_model() to improve standard-error estimates. 

## Gaussian GLM (non-count, shows underdispersion path) ---------------------
fit2 <- glm(mpg ~ wt + cyl, data = mtcars, family = gaussian())
mysterycall_overdispersion_test(fit2)
#> Pearson dispersion phi=6.592 (chi-sq=191, df=29, p=<0.001): Severe overdispersion (phi=6.592). Negative binomial or zero-inflated model strongly recommended. 
#> Switch to a negative binomial or zero-inflated negative binomial model immediately; Poisson standard errors are severely underestimated. 
```
