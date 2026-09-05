# Rigorous Three-Part Acceptance Rate Calculator

Implements the three-part formula used in orthopaedic sports medicine
mystery-caller audit studies:

## Usage

``` r
mysterycall_acceptance_rate_calc(
  data,
  insurance_col = "insurance",
  insurance_groups = NULL,
  inclusion_col = "reason_for_exclusions",
  inclusion_value = "Able to contact",
  reached_declined_values = mysterycall_reached_declined_reasons(),
  wait_col = "business_days_until_appointment",
  id_col = "phone",
  medicaid_accept_col = NULL,
  medicaid_screen_group = NULL,
  conf_level = 0.95
)
```

## Arguments

- data:

  data.frame containing at least the columns named by `insurance_col`,
  `inclusion_col`, and `id_col`.

- insurance_col:

  Character scalar. Name of the column recording insurance type. Default
  `"insurance"`.

- insurance_groups:

  Character vector of insurance levels to evaluate (e.g.
  `c("Medicaid", "Blue Cross/Blue Shield")`). When `NULL` (default), all
  unique non-`NA` values found in `insurance_col` are used in
  alphabetical order.

- inclusion_col:

  Character scalar. Name of the column that records contact / exclusion
  status. Rows equal to `inclusion_value` are considered successfully
  contacted. Default `"reason_for_exclusions"`.

- inclusion_value:

  Character scalar. The exact string in `inclusion_col` that means
  "successfully contacted". Default `"Able to contact"`.

- reached_declined_values:

  Character vector of `inclusion_col` strings for offices that were
  **reached but declined** ("Not accepting new patients", "Referral
  required", "\>5 min on hold"). These are kept in the denominator (the
  office was reached and said no) even though they are not in the
  numerator; every other non-`inclusion_value` reason is treated as
  unreachable and excluded. This keeps the denominator consistent with
  [`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md)'s
  `n_reached`. Default
  [`mysterycall_reached_declined_reasons()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reached_declined_reasons.md).
  Must match your data's reason vocabulary; override consistently across
  acceptance-rate functions.

- wait_col:

  Character scalar or `NULL`. Name of a numeric column holding days to
  appointment. When non-`NULL`, only rows with `wait_col > 0` contribute
  to the numerator (rows with `wait_col == 0` or `NA` are excluded from
  the numerator but not from the denominator). Default
  `"business_days_until_appointment"`.

- id_col:

  Character scalar. Column used to deduplicate physicians (e.g. phone
  number or NPI). Default `"phone"`.

- medicaid_accept_col:

  Character scalar or `NULL`. When non-`NULL`, rows with `NA` in this
  column are excluded from the numerator. Useful when a "Did you accept
  Medicaid?" field is present. Default `NULL`.

- medicaid_screen_group:

  Character vector or `NULL`. Restricts the `medicaid_accept_col`
  NA-screen to only these insurance group(s). This matters when the "Did
  you accept Medicaid?" field is, by design, `NA` on non-Medicaid rows:
  applying the screen to every group would then force those groups'
  rates to zero. When `NULL` (default) the screen applies to all groups
  (the original behaviour); set e.g. `"Medicaid"` to screen only the
  Medicaid arm. Ignored when `medicaid_accept_col` is `NULL`.

- conf_level:

  Numeric scalar in (0, 1). Confidence level for Wilson score intervals.
  Default `0.95`.

## Value

A list of class `"mysterycall_acceptance_rate_calc"` with four elements:

- `table`:

  `data.frame` with one row per insurance group. Columns: `insurance`,
  `n_total` (distinct IDs assigned to group), `n_excluded` (unreachable,
  distinct), `n_numerator` (accepting, distinct), `n_denominator`
  (reachable = total - excluded), `rate_pct` (acceptance rate as
  percentage), `ci_lower_pct`, `ci_upper_pct` (Wilson CI bounds as
  percentages), `sentence` (formatted result string).

- `overall`:

  `data.frame` with one row combining all specified insurance groups.
  `NULL` when only one group is evaluated. Same columns as `table`.

- `sentences`:

  Character vector, one entry per insurance group, e.g.
  `"Medicaid acceptance rate: 209/371 = 56.3% (95% CI: 51.2%-61.4%)"`.

- `gap_sentence`:

  Character scalar describing the spread. When exactly two groups are
  evaluated:
  `"Physicians accepted Medicaid at 56.3% vs BCBS at 82.4%, a gap of 26.1 percentage points."`
  When three or more groups are evaluated, the sentence reports the
  min-to-max range. `NA_character_` when fewer than two valid rates
  exist.

## Details

**Numerator** – distinct physicians (by `id_col`) who:

1.  Are assigned to `insurance_groups` level X.

2.  Have `inclusion_col == inclusion_value` (successfully contacted).

3.  Have `wait_col > 0` (offered a real appointment), when `wait_col` is
    not `NULL`.

4.  Are not `NA` in `medicaid_accept_col`, when `medicaid_accept_col` is
    not `NULL` (explicitly recorded Medicaid acceptance status).

**Denominator** – distinct physicians assigned to insurance X
(`total_assigned`) minus those who were unreachable
(`inclusion_col != inclusion_value`).

**Rate** – Numerator / Denominator, with Wilson score confidence
intervals.

## Deduplication

All counts deduplicate on `id_col` via
[`unique()`](https://rdrr.io/r/base/unique.html). Each physician is
expected to appear at most once per insurance group; the deduplication
step is a safeguard against duplicate call rows. A physician who has
both a reachable and an unreachable row for the same insurance group
will be counted in *both* the total and the excluded sets, which may
undercount the denominator. Clean data with one row per physician per
insurance group will not be affected.

## See also

[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md),
[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md).
This function generalizes the two-group (Medicaid/BCBS)
[`mysterycall_insurance_acceptance_rates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_acceptance_rates.md),
which is now deprecated in its favor – use
`medicaid_screen_group = "Medicaid"` to reproduce the legacy asymmetric
Medicaid-only NA-screen.

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
n <- 80
df <- data.frame(
  phone     = paste0("555-", formatC(seq_len(n), width = 4, flag = "0")),
  insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = n / 2L),
  reason_for_exclusions = sample(
    c("Able to contact", "No answer", "Line disconnected"),
    n, replace = TRUE, prob = c(0.75, 0.15, 0.10)
  ),
  business_days_until_appointment = ifelse(
    stats::runif(n) > 0.3,
    sample(1:30, n, replace = TRUE),
    0L
  ),
  stringsAsFactors = FALSE
)

## Two-group comparison (Medicaid vs BCBS)
res <- mysterycall_acceptance_rate_calc(
  data             = df,
  insurance_groups = c("Medicaid", "Blue Cross/Blue Shield")
)
print(res)
#> Medicaid acceptance rate: 26/26 = 100.0% (95% CI: 87.1% to 100.0%)
#> Blue Cross/Blue Shield acceptance rate: 31/31 = 100.0% (95% CI: 89.0% to 100.0%) 
#> Physicians accepted Medicaid at 100.0% vs Blue Cross/Blue Shield at 100.0%, a gap of 0.0 percentage points. 
res$table
#>                insurance n_total n_excluded n_numerator n_denominator rate_pct
#> 1               Medicaid      40         14          26            26      100
#> 2 Blue Cross/Blue Shield      40          9          31            31      100
#>   ci_lower_pct ci_upper_pct
#> 1     87.12711          100
#> 2     88.97446          100
#>                                                                           sentence
#> 1               Medicaid acceptance rate: 26/26 = 100.0% (95% CI: 87.1% to 100.0%)
#> 2 Blue Cross/Blue Shield acceptance rate: 31/31 = 100.0% (95% CI: 89.0% to 100.0%)

## Without wait-time filter
res2 <- mysterycall_acceptance_rate_calc(
  data      = df,
  wait_col  = NULL
)
res2$sentences
#> [1] "Blue Cross/Blue Shield acceptance rate: 31/31 = 100.0% (95% CI: 89.0% to 100.0%)"
#> [2] "Medicaid acceptance rate: 26/26 = 100.0% (95% CI: 87.1% to 100.0%)"              
```
