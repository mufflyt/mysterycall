# Automatically select and compare wait-time models

Fits a Poisson GLMM first, checks overdispersion, and upgrades to a
negative binomial GLMM when warranted. Optionally fits a Linear Mixed
Model (LMM) in parallel and evaluates whether it is defensible as a
communication/sensitivity tool. Returns the statistically preferred
count model with a structured recommendation attached.

## Usage

``` r
mysterycall_auto_model(
  data,
  outcome,
  predictors,
  random_intercept,
  phi_threshold = mysterycall_overdispersion_threshold(),
  conf_level = 0.95,
  include_lmm = TRUE,
  lmm_normality_threshold = 0.05,
  ...
)
```

## Arguments

- data:

  A data frame.

- outcome:

  Character scalar. Name of the count (wait-day) outcome column.

- predictors:

  Character vector of fixed-effect column names.

- random_intercept:

  Character scalar. Grouping column for the physician random intercept.

- phi_threshold:

  Numeric. Pearson phi above which the NB model replaces Poisson.
  Default
  [`mysterycall_overdispersion_threshold()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_threshold.md)
  (1.5), the package-wide overdispersion threshold.

- conf_level:

  Numeric. Confidence level for Wald CIs. Default `0.95`.

- include_lmm:

  Logical. Fit an LMM and evaluate its suitability? Default `TRUE`. The
  LMM is *never* the primary model; it is always a secondary
  communication/sensitivity check.

- lmm_normality_threshold:

  Numeric. Shapiro-Wilk p-value threshold above which LMM residuals are
  considered approximately normal. Default `0.05`.

- ...:

  Additional arguments forwarded to all model-fitting functions.

## Value

The selected count model - either a `mysterycall_poisson_model` or
`mysterycall_nb_model` - with an extra element `$selection`:

- `poisson_phi`:

  Numeric. Overdispersion from the initial Poisson fit.

- `model_chosen`:

  Character. `"poisson"` or `"negative_binomial"`.

- `reason`:

  Character. Explanation of count-model selection.

- `lmm`:

  A `mysterycall_lmm` object, or `NULL` when `include_lmm = FALSE` or
  fitting failed.

- `lmm_shapiro_p`:

  Numeric. Shapiro-Wilk p-value on LMM residuals, or `NA`.

- `lmm_defensible`:

  Logical. `TRUE` when LMM residuals pass normality **and** outcome
  range exceeds 30 days.

- `lmm_recommendation`:

  Character. Plain-language guidance on whether and how to use the LMM.

- `recommendation`:

  Character. Overall one-paragraph guidance covering both the primary
  model and the LMM.

## Details

**Decision tree**

1.  Fit Poisson GLMM and compute Pearson overdispersion (phi).

2.  If phi \<= `phi_threshold`: primary model = Poisson. Otherwise:
    re-fit as negative binomial (NB) GLMM.

3.  If `include_lmm = TRUE`: fit LMM and run a Shapiro-Wilk normality
    test on the residuals. If residuals are approximately normal (p \>=
    `lmm_normality_threshold`) **and** the outcome range exceeds 30
    days, the LMM is flagged as defensible for reporting day-scale
    coefficients alongside the primary count model. Otherwise the LMM is
    flagged as not recommended.

The **primary return value** is the selected count model (Poisson or NB)

- the same class as
  [`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
  /
  [`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
  so all downstream functions work unchanged. The LMM and routing
  metadata live in `result$selection`.

## See also

[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md),
[`mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_comparison_table.md)

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
  wait = rpois(60, 18),
  ins  = rep(c("Medicaid", "BCBS"), 30),
  phys = rep(paste0("Dr_", 1:10), each = 6),
  stringsAsFactors = FALSE
)
result <- mysterycall_auto_model(df, "wait", "ins", "phys")
#> Step 1/3: Fitting Poisson GLMM to assess overdispersion...
#> Fitting Poisson GLMER: wait ~ ins + (1 | phys)
#> boundary (singular) fit: see help('isSingular')
#> Convergence issues detected:
#>   boundary (singular) fit: see help('isSingular')
#> Consider simplifying predictors or using nAGQ = 1.
#> Singular fit: random-intercept variance is ~0. The physician-level random effect explains little variation.
#> Model fitted: n=60, physicians=10, AIC=340.4, overdispersion=0.86
#> Poisson GLMM selected: phi = 0.86 <= 1.5 (no overdispersion detected). 
#> Step 3/3: Fitting LMM to evaluate day-scale coefficients...
#> Fitting LMM: wait ~ ins + (1 | phys)
#> boundary (singular) fit: see help('isSingular')
#> Model fitted: n=60, physicians=10, AIC=342.6, sigma=3.93, R2m=0.095, R2c=0.095
print(result)
#> Poisson GLMER  n = 60  physicians = 10  AIC = 340.4  BIC = 346.7
#>   Warning: convergence warnings; singular fit
#>   Reference levels: ins='BCBS'
#> 
#> Fixed effects (IRR with Wald CI):
#>          term    irr ci_lower ci_upper p_value_fmt
#> 1 (Intercept) 17.000   15.587   18.541     < 0.001
#> 2 insMedicaid  1.149    1.020    1.294       0.022
#> 
#> Random intercept (phys):  variance = 0.0000  SD = 0.0000
#> 
#> === Auto-Model Selection ===
#> Count model: poisson (Poisson phi = 0.86)
#> LMM: Shapiro-Wilk p = 0.830  |  Defensible: NO
#> 
#> --- Recommendation ---
#> PRIMARY MODEL: Poisson GLMM (phi = 0.86 <= 1.5; no overdispersion). Report
#>   incidence rate ratios (IRRs) with 95% Wald CIs. SENSITIVITY /
#>   COMMUNICATION: LMM is not recommended: outcome range = 17 days (< 30). A
#>   floor effect near zero violates the normality assumption. Stick with the
#>   Poisson GLMM. Do not report LMM coefficients as primary results.
#> 
```
