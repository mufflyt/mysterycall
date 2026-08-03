# Auto-generate manuscript sentences for a two-way interaction

Takes a fitted model and two variable names, computes estimated marginal
means (EMMs) for the full cross of those variables via
[`emmeans::emmeans()`](https://rvlenth.github.io/emmeans/reference/emmeans.html),
and auto-generates one manuscript-ready sentence per level of `var1`.
Each sentence reports the mean (or rate) and 95% CI for every level of
`var2` within that `var1` stratum, plus the within-stratum pairwise
difference. All sentences are also collapsed into a single paste-ready
paragraph. When an interaction p-value can be extracted from the model
summary it is appended as a trailing sentence.

## Usage

``` r
mysterycall_interaction_sentences(
  model,
  var1,
  var2,
  type = "response",
  conf_level = 0.95,
  digits = 1L,
  ref_group2 = NULL,
  outcome_label = "wait time (days)"
)

# S3 method for class 'mysterycall_interaction_sentences'
print(x, ...)
```

## Arguments

- model:

  A fitted model object accepted by
  [`emmeans::emmeans()`](https://rvlenth.github.io/emmeans/reference/emmeans.html).
  Typical classes include `glmerMod`, `lmerMod`, `glm`, and `lm`.

- var1:

  Character scalar. First variable in the interaction (e.g.
  `"scenario"`). One sentence is produced per level of `var1`.

- var2:

  Character scalar. Second variable in the interaction (e.g.
  `"insurance"`). Levels of `var2` are compared within each `var1`
  sentence.

- type:

  Character scalar. The `type` argument forwarded to
  [`emmeans::emmeans()`](https://rvlenth.github.io/emmeans/reference/emmeans.html).
  Default `"response"` back-transforms estimates to the original outcome
  scale (e.g. rate for Poisson, probability for logistic).

- conf_level:

  Numeric scalar in (0, 1). Confidence level for the intervals. Default
  `0.95`.

- digits:

  Integer scalar. Number of decimal places for means and CI bounds in
  the formatted sentences. Default `1L`.

- ref_group2:

  Character scalar or `NULL`. When non-`NULL`, the named level of `var2`
  is placed first in each sentence and used as the reference when
  computing the within-stratum difference. When `NULL` (default) the
  first factor level determined by emmeans is used.

- outcome_label:

  Character scalar. Human-readable label for the outcome quantity
  written into each sentence. Default `"wait time (days)"`.

- x:

  A `mysterycall_interaction_sentences` object.

- ...:

  Ignored; present for S3 method consistency.

## Value

A list of class `mysterycall_interaction_sentences` with elements:

- `sentences`:

  Named character vector. One sentence per level of `var1`. Names equal
  the `var1` level labels.

- `emmeans_table`:

  `data.frame`. The raw
  [`emmeans::emmeans()`](https://rvlenth.github.io/emmeans/reference/emmeans.html)
  output converted via
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html). Column
  names vary by model family (e.g. `rate` vs `emmean`, `asymp.LCL` vs
  `lower.CL`).

- `paragraph`:

  Character scalar. All sentences joined with a single space, ready to
  paste into a manuscript.

- `var1`:

  Character scalar. The `var1` argument.

- `var2`:

  Character scalar. The `var2` argument.

- `type`:

  Character scalar. The emmeans `type` used.

## Print method

`print.mysterycall_interaction_sentences()` writes the `$paragraph`
element to the console via [`cat()`](https://rdrr.io/r/base/cat.html),
so the text appears as plain prose without surrounding quotes or list
structure.

## emmeans column detection

Column names in the emmeans data frame differ by model family. This
function detects the estimate and CI columns automatically:

- Estimate: `rate`, `emmean`, `response`, `prob` (first match).

- Lower CI: `asymp.LCL`, `lower.CL`, `lower.HPD`.

- Upper CI: `asymp.UCL`, `upper.CL`, `upper.HPD`.

An informative error is raised when none of the candidate names are
found.

## Interaction p-value

The function silently attempts to extract the smallest p-value for any
`var1:var2` coefficient row from
[`summary()`](https://rdrr.io/pkg/lme4/man/summary.merMod.html).
Coefficients are matched when their row name contains both `var1` and
`var2` and a colon. On success, a trailing sentence reporting
significance is appended to `$paragraph`. Failure (e.g. for unsupported
model classes or missing interaction terms) is ignored silently.

## See also

[`mysterycall_interaction_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_table.md),
[`mysterycall_marginal_effects()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_marginal_effects.md)

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
if (FALSE) { # \dontrun{
library(lme4)

set.seed(42)
df <- data.frame(
  wait_days = rpois(120, lambda = 20),
  scenario  = rep(c("Urgent", "Routine"), each = 60),
  insurance = rep(c("Medicaid", "BCBS", "Medicare"), times = 40),
  physician = rep(paste0("Dr", 1:10), each = 12),
  stringsAsFactors = FALSE
)

fit <- lme4::glmer(
  wait_days ~ scenario * insurance + (1 | physician),
  data   = df,
  family = poisson()
)

result <- mysterycall_interaction_sentences(
  model         = fit,
  var1          = "scenario",
  var2          = "insurance",
  ref_group2    = "BCBS",
  outcome_label = "wait time (days)"
)

print(result)          # prints paragraph to console
result$sentences       # named vector, one element per scenario level
result$emmeans_table   # raw emmeans data frame
} # }
```
