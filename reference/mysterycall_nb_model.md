# Fit a Negative Binomial GLMM for overdispersed wait-time analysis

Runs a multilevel negative binomial regression
([`glmmTMB::glmmTMB`](https://rdrr.io/pkg/glmmTMB/man/glmmTMB.html)) for
mystery caller studies where the Poisson model shows overdispersion
([`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
reports phi \> 2). The physician identifier is modelled as a random
intercept. Fixed-effect results are returned as incidence rate ratios
(IRR) with Wald confidence intervals.

## Usage

``` r
mysterycall_nb_model(
  data,
  outcome,
  predictors,
  random_intercept,
  conf_level = 0.95,
  offset_col = NULL,
  ...
)
```

## Arguments

- data:

  A data frame containing all model columns. Rows with `NA` in any model
  column are dropped before fitting.

- outcome:

  Character scalar naming the count-outcome column (e.g.
  `"business_days_until_appointment"`). Must be non-negative
  integer-valued.

- predictors:

  Character vector of fixed-effect predictor column names. Factor and
  character columns are used as-is; the reference level is the first
  level alphabetically (or the first
  [`levels()`](https://rdrr.io/r/base/levels.html) for factors).

- random_intercept:

  Character scalar naming the grouping column for the random intercept
  (e.g. `"npi"` for physician). A `(1 | column)` term is added to the
  formula automatically.

- conf_level:

  Confidence level for Wald CIs. Default `0.95`.

- offset_col:

  Optional character scalar naming a numeric column to use as a
  log-offset. When supplied, `offset(log(offset_col))` is appended to
  the fixed-effects formula.

- ...:

  Additional arguments forwarded to
  [`glmmTMB::glmmTMB()`](https://rdrr.io/pkg/glmmTMB/man/glmmTMB.html).

## Value

A list of class `mysterycall_nb_model` containing:

- `model`:

  `glmmTMB`. The fitted model object.

- `irr_table`:

  `tibble`. One row per fixed-effect term: `term`, `estimate` (log
  scale), `se`, `z_value`, `p_value`, `p_value_fmt`, `irr`, `ci_lower`,
  `ci_upper`.

- `theta`:

  `numeric`. Negative binomial dispersion parameter (shape,
  `theta > 0`). Higher values indicate less overdispersion. Variance =
  mean + mean^2 / theta.

- `random_effects`:

  `data.frame` from
  [`lme4::VarCorr()`](https://rdrr.io/pkg/nlme/man/VarCorr.html).

- `factor_refs`:

  `list`. Reference levels for character/factor predictors.

- `formula`:

  `formula`. The formula passed to glmmTMB.

- `n`:

  `integer`. Complete-case rows used.

- `n_dropped`:

  `integer`. Rows excluded for missing values.

- `n_clusters`:

  `integer`. Unique values of `random_intercept`.

- `overdispersion`:

  `numeric`. Pearson chi-square / residual df after NB fit. Values near
  1 indicate adequate fit. Values \> 2 suggest the NB model still
  underfits; consider zero-inflated NB.

- `convergence`:

  `list`. `converged` (logical), `messages` (character vector).

- `aic`:

  `numeric`. AIC.

- `bic`:

  `numeric`. BIC.

## Details

Use this function when
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
returns `overdispersion` substantially greater than 2: the negative
binomial adds a per-observation variance term (theta) that absorbs the
excess variance and yields correctly-sized standard errors.

## When to use negative binomial vs Poisson

Run
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
first. If `result$overdispersion > 2`, switch to
`mysterycall_nb_model()`. The negative binomial model will give wider
(more honest) confidence intervals and correct p-values; Poisson
standard errors are deflated under overdispersion, producing spuriously
small p-values.

## Interpreting theta

`theta` (the shape parameter) controls how quickly variance grows with
the mean. As theta -\> Inf, the NB distribution approaches Poisson.
Values of theta \< 5 indicate substantial overdispersion.

## See also

[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
for the Poisson equivalent;
[`mysterycall_wait_time_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_summary.md)
for descriptive summaries.

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
[`mysterycall_gee()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_gee.md),
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
set.seed(1978)
df <- data.frame(
  wait_days = rnbinom(40, mu = 18, size = 2),
  insurance = rep(c("Medicaid", "BCBS"), each = 20),
  gender    = sample(c("Male", "Female"), 40, replace = TRUE),
  physician = rep(paste0("Dr_", 1:8), each = 5),
  stringsAsFactors = FALSE
)
result <- mysterycall_nb_model(
  df,
  outcome          = "wait_days",
  predictors       = c("insurance", "gender"),
  random_intercept = "physician"
)
#> Fitting Negative Binomial GLMM: wait_days ~ insurance + gender + (1 | physician)
#> Model fitted: n=40, physicians=8, AIC=299.0, theta=1.99
result$irr_table
#> # A tibble: 3 × 9
#>   term      estimate    se z_value  p_value p_value_fmt    irr ci_lower ci_upper
#>   <chr>        <dbl> <dbl>   <dbl>    <dbl> <chr>        <dbl>    <dbl>    <dbl>
#> 1 (Interce…   2.60   0.218  12.0   6.32e-33 < 0.001     13.5      8.80     20.7 
#> 2 insuranc…   0.143  0.239   0.596 5.51e- 1 0.551        1.15     0.722     1.84
#> 3 genderMa…  -0.0243 0.240  -0.101 9.20e- 1 0.920        0.976    0.609     1.56
```
