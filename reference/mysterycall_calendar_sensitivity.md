# Calendar-days vs. business-days sensitivity analysis for wait-time models

Fits the same linear mixed model
([`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md))
on two wait-time columns – one in calendar days, one in business days
(Mon-Fri, US federal holidays excluded) – and returns a side-by-side
comparison table with a ready-to-paste supplemental paragraph.

## Usage

``` r
mysterycall_calendar_sensitivity(
  data,
  calendar_col,
  business_col,
  predictors,
  random_intercept,
  conf_level = 0.95,
  ref_label = NULL,
  supp_table_num = "[X]",
  output_path = NULL,
  ...
)
```

## Arguments

- data:

  A data frame. Must contain `calendar_col`, `business_col`,
  `predictors`, and `random_intercept`.

- calendar_col:

  Character scalar. Name of the calendar-days column (e.g.
  `"wait_days"`). Must be numeric.

- business_col:

  Character scalar. Name of the business-days column (e.g.
  `"business_days"`). Must be numeric.

- predictors:

  Character vector of fixed-effect predictor column names (e.g.
  `"scenario"`). Passed directly to
  [`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md).

- random_intercept:

  Character scalar. Grouping column for the random intercept (e.g.
  `"practice_id"`). Passed to
  [`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md).

- conf_level:

  Numeric. Confidence level for Wald CIs. Default `0.95`.

- ref_label:

  Character scalar. Human-readable label for the reference group used in
  the supplemental paragraph (e.g. `"Straight couple"`). Default `NULL`
  (omitted from prose).

- supp_table_num:

  Character scalar. Supplemental table number to embed in the paragraph
  (e.g. `"S2"`). Default `"[X]"`.

- output_path:

  Character scalar or `NULL`. When a path ending in `.docx` is supplied
  the comparison table is exported to Word via `flextable` and
  `officer`. Requires both packages.

- ...:

  Additional arguments forwarded to
  [`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md).

## Value

A list of class `mysterycall_calendar_sensitivity` with elements:

- `calendar_lmm`:

  `mysterycall_lmm` object fit on `calendar_col`.

- `business_lmm`:

  `mysterycall_lmm` object fit on `business_col`.

- `comparison_table`:

  `data.frame`. One row per non-intercept fixed-effect term with
  columns: `term`, `cal_est`, `cal_ci_lo`, `cal_ci_hi`, `cal_p`,
  `biz_est`, `biz_ci_lo`, `biz_ci_hi`, `biz_p`, `direction_consistent`
  (logical), `magnitude_ratio` (business / calendar estimate).

- `summary_table`:

  `data.frame`. Print-ready version with formatted strings: `Term`,
  `Calendar days`, `Business days`, `Consistent`.

- `n_calendar`:

  Integer. Complete cases for the calendar model.

- `n_business`:

  Integer. Complete cases for the business model.

- `all_consistent`:

  Logical. `TRUE` when every term has consistent direction across both
  models.

- `paragraph`:

  Character scalar. Supplemental paragraph ready to paste into the
  manuscript.

- `docx_path`:

  Character path or `NULL`.

## Details

This function fulfils the M&M promise of a supplemental table comparing
calendar vs. business days. Run it once data collection is complete and
paste `$paragraph` into the supplement.

## Interpreting direction_consistent

`TRUE` means the point estimate for that term has the same sign in both
models (both negative = shorter wait, or both positive = longer wait). A
difference in magnitude is expected because business days are roughly
5/7 of calendar days; `magnitude_ratio` near 0.71 is unremarkable.

## See also

[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md),
[`mysterycall_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_business_days.md),
[`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md)

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
  wait_days     = round(rnorm(60, 21, 8)),
  business_days = round(rnorm(60, 15, 6)),
  scenario      = rep(c("Straight", "Lesbian", "Single"), 20),
  practice      = rep(paste0("P", 1:20), each = 3),
  stringsAsFactors = FALSE
)
res <- mysterycall_calendar_sensitivity(
  df,
  calendar_col     = "wait_days",
  business_col     = "business_days",
  predictors       = "scenario",
  random_intercept = "practice",
  ref_label        = "Straight couple",
  supp_table_num   = "S2"
)
#> Fitting calendar-days model (wait_days)...
#> Fitting business-days model (business_days)...
#> Warning: Outcome range is only 26 days (< 30). LMM assumes approximate normality; with a narrow range the distribution may be non-normal or floor-censored. Consider Poisson/NB GLMM instead and check the Q-Q plot.
#> Warning: Convergence issues detected:
#>   boundary (singular) fit: see help('isSingular')
#> Warning: Singular fit: physician random-intercept variance is ~0. Consider a fixed-effects-only model.
print(res)
#> Calendar vs. Business Days Sensitivity Analysis
#>   Calendar model: n = 60  |  Business model: n = 60
#>   Direction consistent across all terms: NO -- see Consistent column
#> 
#>              Term               Calendar days              Business days
#>    scenarioSingle  0 (-5.8 to 5.8), p = 1.000 2 (-1.4 to 5.3), p = 0.265
#>  scenarioStraight -1 (-6.8 to 4.8), p = 0.736 2 (-1.4 to 5.4), p = 0.253
#>  Consistent
#>         Yes
#>          No
#> 
#> -- Supplemental paragraph --
#> As a pre-specified sensitivity analysis, we repeated the secondary wait-time
#> analysis substituting business days (Monday through Friday, excluding the 11
#> U.S. federal holidays) for calendar days. Business days were computed using the
#> R package \emph{bizdays} with a US Federal holiday calendar. The calendar-day
#> model included 60 observations with a recorded appointment date; the
#> business-day model included 60 observations. Both models used the same
#> mixed-effects linear regression specification (scenario as fixed effect
#> compared with Straight couple (reference); physician practice as random
#> intercept). Results were directionally consistent for most comparisons, with
#> the exception of scenarioStraight. Shapiro-Wilk normality tests on model
#> residuals: calendar-day model: W = 0.971, p = 0.168; business-day model: W =
#> 0.981, p = 0.464. Full results are presented in Supplemental Table S2.
```
