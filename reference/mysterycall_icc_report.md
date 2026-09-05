# Inter-caller reliability report for STROBE item 22

Computes a comprehensive inter-rater reliability report focused on the
**callers** in a mystery-caller study (not model random effects).
Satisfies STROBE reporting item 22 by providing ICC, Cohen's kappa,
confidence intervals, and a manuscript-ready sentence.

## Usage

``` r
mysterycall_icc_report(
  data,
  caller_col = "caller_id",
  outcome_col = "offered",
  group_col = NULL,
  conf_level = 0.95
)
```

## Arguments

- data:

  data.frame with at least `caller_col` and `outcome_col`.

- caller_col:

  Character. Column identifying which caller made each call. Default
  `"caller_id"`.

- outcome_col:

  Character. Column with binary 0/1 outcome (appointment offered).
  Non-binary values are coerced via `> 0` with a warning. Default
  `"offered"`.

- group_col:

  Character or `NULL`. Optional grouping variable (e.g. insurance type).
  When supplied, stratified results are computed for each level and
  stored in `$group_results`. Default `NULL`.

- conf_level:

  Numeric. Confidence level for the F-distribution CI. Default `0.95`.

## Value

A list of class `mysterycall_icc_report` containing:

- `icc`:

  Numeric. ICC point estimate (one-way random effects, single measures),
  clamped to \\\[0, 1\]\\.

- `kappa`:

  Numeric. Cohen's kappa (numerically equal to ICC for binary outcomes
  in the one-way random-effects model; Fleiss 1971). Landis &
  Koch (1977) thresholds are used for the interpretation label.

- `ci`:

  Numeric vector of length 2. Exact F-distribution CI for ICC.
  `c(NA, NA)` when within-caller variance is zero.

- `n_callers`:

  Integer. Number of distinct callers.

- `n_calls`:

  Integer. Total calls analysed (complete cases only).

- `n_per_caller`:

  Named integer vector. Call counts per caller.

- `sentence`:

  Character. Manuscript-ready one-sentence summary, e.g.
  `"Inter-caller reliability was ICC=0.82 (95% CI: 0.71 to 0.91), indicating excellent agreement (kappa=0.82)."`

- `table`:

  data.frame. Per-caller call count, offers, and acceptance rate
  (`caller`, `n_calls`, `n_offered`, `accept_rate`).

- `group_results`:

  Named list of `mysterycall_icc_report` objects (one per level of
  `group_col`), or `NULL` when `group_col` is `NULL`.

- `conf_level`:

  Numeric. The `conf_level` argument used.

## Details

The ICC is derived from a one-way random-effects ANOVA where caller is
the grouping factor:

\$\$\widehat{\sigma}\_b^2 = \frac{MS_B - MS_W}{n_0}, \quad \text{ICC} =
\frac{\widehat{\sigma}\_b^2}{\widehat{\sigma}\_b^2 + MS_W}\$\$

which simplifies to

\$\$\text{ICC} = \frac{MS_B - MS_W}{MS_B + (n_0 - 1)\\MS_W}\$\$

where \\n_0 = (N - \sum n_i^2 / N) / (k - 1)\\ is the effective group
size for unbalanced designs (Shrout & Fleiss, 1979).

For a binary outcome, the intraclass kappa equals the ICC in the one-way
random-effects model (Fleiss, 1971), so both statistics are reported
from the same ANOVA decomposition. Confidence intervals use the exact
F-distribution method (Shrout & Fleiss, 1979). Kappa is interpreted
using Landis & Koch (1977) thresholds.

## References

Fleiss JL (1971). Measuring nominal scale agreement among many raters.
*Psychological Bulletin* 76(5):378-382.
[doi:10.1037/h0031619](https://doi.org/10.1037/h0031619)

Landis JR, Koch GG (1977). The measurement of observer agreement for
categorical data. *Biometrics* 33(1):159-174.
[doi:10.2307/2529310](https://doi.org/10.2307/2529310)

Shrout PE, Fleiss JL (1979). Intraclass correlations: uses in assessing
rater reliability. *Psychological Bulletin* 86(2):420-428.
[doi:10.1037/0033-2909.86.2.420](https://doi.org/10.1037/0033-2909.86.2.420)

## See also

[`mysterycall_icc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_icc.md),
[`mysterycall_icc_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_icc_sentence.md)

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
set.seed(42)
df <- data.frame(
  caller_id = rep(c("Alice", "Bob", "Carol"), each = 20),
  offered   = c(
    rbinom(20, 1, 0.70),
    rbinom(20, 1, 0.65),
    rbinom(20, 1, 0.68)
  ),
  insurance = rep(c("Medicaid", "BCBS"), 30),
  stringsAsFactors = FALSE
)

## Basic report
rpt <- mysterycall_icc_report(df)
print(rpt)
#> Inter-Rater Reliability Report (STROBE Item 22)
#> ================================================
#> Inter-caller reliability was ICC=0.00 (95% CI: 0.00 to 0.63), indicating poor agreement (kappa=0.00). 
#> 
#>   Callers : 3
#>   Calls   : 60
#> 
#> Per-Caller Summary:
#>  caller n_calls n_offered accept_rate
#>   Alice      20        11        0.55
#>     Bob      20        10        0.50
#>   Carol      20        14        0.70
cat(rpt$sentence, "\n")
#> Inter-caller reliability was ICC=0.00 (95% CI: 0.00 to 0.63), indicating poor agreement (kappa=0.00). 

## Stratified by insurance type
rpt2 <- mysterycall_icc_report(df, group_col = "insurance")
cat(rpt2$sentence, "\n")
#> Inter-caller reliability was ICC=0.00 (95% CI: 0.00 to 0.63), indicating poor agreement (kappa=0.00). 
lapply(rpt2$group_results, function(x) x$sentence)
#> $BCBS
#> [1] "Inter-caller reliability was ICC=0.00 (95% CI: 0.00 to 0.58), indicating poor agreement (kappa=0.00)."
#> 
#> $Medicaid
#> [1] "Inter-caller reliability was ICC=0.00 (95% CI: 0.00 to 0.68), indicating poor agreement (kappa=0.00)."
#> 
```
