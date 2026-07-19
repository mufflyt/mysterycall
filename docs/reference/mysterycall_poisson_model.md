# Fit a Poisson GLMER for mystery caller wait-time analysis

Runs a multilevel Poisson regression
([`lme4::glmer`](https://rdrr.io/pkg/lme4/man/glmer.html)) appropriate
for mystery caller studies where the same physician may be called
multiple times (e.g. with different insurance types). The physician
identifier is modelled as a random intercept, which accounts for
correlation within physicians. Fixed-effect results are returned as
incidence rate ratios (IRR) with Wald confidence intervals.

## Usage

``` r
mysterycall_poisson_model(
  data,
  outcome,
  predictors,
  random_intercept,
  conf_level = 0.95,
  nAGQ = 0L,
  offset_col = NULL,
  ...
)
```

## Arguments

- data:

  A data frame containing all model columns. Rows with `NA` in any model
  column are dropped before fitting; the count is reported.

- outcome:

  Character scalar naming the count-outcome column (e.g.
  `"business_days_until_appointment"`). Must be non-negative numeric.

- predictors:

  Character vector of fixed-effect predictor column names. Factor and
  character columns are used as-is; their reference level is the first
  level alphabetically (or the first
  [`levels()`](https://rdrr.io/r/base/levels.html) for factors).

- random_intercept:

  Character scalar naming the grouping column for the random intercept
  (e.g. `"name"` for physician). A `(1 | column)` term is added to the
  formula automatically.

- conf_level:

  Confidence level for Wald CIs. Default `0.95`.

- nAGQ:

  Integer passed to
  [`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html). `0`
  (default) uses the fastest approximation; `1` uses the Laplace
  approximation; values `> 1` use adaptive Gauss-Hermite quadrature
  (slower, more accurate for small cluster sizes).

- offset_col:

  Optional character scalar naming a numeric column to use as a
  log-offset (e.g. log(exposure time)). When supplied, the term
  `offset(log(offset_col))` is appended to the fixed-effects formula.

- ...:

  Additional arguments forwarded to
  [`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html).

## Value

A list of class `mysterycall_poisson_model` containing:

- `model`:

  `glmerMod`. The fitted multilevel Poisson model.

- `irr_table`:

  `tibble`. One row per fixed-effect term with columns: `term`
  (character), `estimate` (numeric, log scale), `se` (numeric),
  `z_value` (numeric), `p_value` (numeric), `p_value_fmt` (character,
  formatted), `irr` (numeric, incidence rate ratio), `ci_lower`
  (numeric), `ci_upper` (numeric).

- `random_effects`:

  `data.frame` from
  [`lme4::VarCorr()`](https://rdrr.io/pkg/nlme/man/VarCorr.html).
  Describes random-intercept variance and standard deviation.

- `factor_refs`:

  `list` (named). Reference levels for each character/factor predictor.

- `formula`:

  `formula`. The formula passed to
  [`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html).

- `n`:

  `integer`. Number of complete-case rows used for fitting.

- `n_dropped`:

  `integer`. Rows excluded due to missing values.

- `n_clusters`:

  `integer`. Number of unique values of `random_intercept`.

- `overdispersion`:

  `numeric`. Pearson chi-square / residual df. Values substantially
  above 1 (common threshold: 2) suggest overdispersion; consider a
  negative binomial model.

- `convergence`:

  `list`. Elements: `converged` (logical), `singular` (logical),
  `messages` (character vector).

- `aic`:

  `numeric`. Akaike Information Criterion.

- `bic`:

  `numeric`. Bayesian Information Criterion.

## Interpreting IRRs

An IRR of 1.40 for `insurance_typeMedicaid` means physicians contacted
with Medicaid insurance had, on average, 40% longer wait times than the
reference insurance group. Compute as `exp(estimate)` with Wald CI
`exp(estimate +/- z * se)`.

## Overdispersion

Poisson assumes mean = variance. If `overdispersion` is substantially
greater than 1 (a common threshold is 2), the standard errors will be
underestimated. Consider fitting a negative binomial model or using
quasi-Poisson standard errors for inference.

## See also

[`mysterycall_wait_time_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_summary.md),
[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md),
[`mysterycall_create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_formula.md)

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
[`mysterycall_overdispersion_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_test.md),
[`mysterycall_plot_distribution()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_distribution.md),
[`mysterycall_plot_effect()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_effect.md),
[`mysterycall_plot_emmeans_full()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans_full.md),
[`mysterycall_plot_emmeans_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans_interaction.md),
[`mysterycall_plot_inclexcl()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_inclexcl.md),
[`mysterycall_plot_residuals()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_residuals.md),
[`mysterycall_plot_sjplot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_sjplot_interaction.md),
[`mysterycall_plot_stacked_bar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_stacked_bar.md),
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
set.seed(1978)
df <- data.frame(
  wait_days = rpois(40, lambda = 18),
  insurance = rep(c("Medicaid", "BCBS"), each = 20),
  gender    = sample(c("Male", "Female"), 40, replace = TRUE),
  physician = rep(paste0("Dr_", 1:8), each = 5),
  stringsAsFactors = FALSE
)
result <- mysterycall_poisson_model(
  df,
  outcome          = "wait_days",
  predictors       = c("insurance", "gender"),
  random_intercept = "physician"
)
#> Fitting Poisson GLMER: wait_days ~ insurance + gender + (1 | physician)
#> boundary (singular) fit: see help('isSingular')
#> Convergence issues detected:
#>   boundary (singular) fit: see help('isSingular')
#> Consider simplifying predictors or using nAGQ = 1.
#> Singular fit: random-intercept variance is ~0. The physician-level random effect explains little variation.
#> Model fitted: n=40, physicians=8, AIC=230.8, overdispersion=0.90
result$irr_table
#> # A tibble: 3 × 9
#>   term       estimate     se z_value p_value p_value_fmt   irr ci_lower ci_upper
#>   <chr>         <dbl>  <dbl>   <dbl>   <dbl> <chr>       <dbl>    <dbl>    <dbl>
#> 1 (Intercep…   2.88   0.0670  43.0     0     <0.001      17.8    15.6      20.3 
#> 2 insurance…   0.0109 0.0738   0.148   0.883 0.883        1.01    0.875     1.17
#> 3 genderMale   0.0458 0.0744   0.616   0.538 0.538        1.05    0.905     1.21
```
