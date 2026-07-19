# Kaplan-Meier time-to-appointment analysis by insurance group

Fits a Kaplan-Meier survival model to wait-time data from mystery-caller
studies. In this framing the "event" is receiving an appointment and
"time" is the wait in days. Callers who never receive an appointment are
right-censored at `max_days`. A log-rank test compares the groups. The
optional plot is built manually with ggplot2 (step functions + ribbon CI
bands) — survminer is not required.

## Usage

``` r
mysterycall_kaplan_meier(
  data,
  time_col,
  event_col = "offered",
  group_col,
  max_days = 90,
  conf_level = 0.95,
  plot = TRUE,
  plot_title = "Time to Appointment by Insurance Type",
  ylab = "Callers still awaiting an appointment (%)",
  legend_title = NULL,
  palette = NULL,
  risk_table = TRUE
)
```

## Arguments

- data:

  A `data.frame` containing the study data.

- time_col:

  Character. Name of the column containing days until appointment
  (numeric). Rows where an appointment was never offered should have
  `NA` or a value `>= max_days`.

- event_col:

  Character. Name of the binary event column: `1` = appointment
  offered/obtained, `0` = censored (no appointment). Logical columns are
  coerced to integer silently. Default `"offered"`.

- group_col:

  Character. Name of the grouping variable (e.g., `"insurance"`). Must
  have at least two levels. Required.

- max_days:

  Numeric scalar. Maximum follow-up days for administrative censoring.
  When `event_col = 0` and `time_col = NA`, time is imputed as
  `max_days`. All times are clamped to `[0, max_days]`. Default `90`.

- conf_level:

  Numeric scalar in `(0, 1)`. Confidence level for survival confidence
  intervals. Default `0.95`.

- plot:

  Logical. If `TRUE` (default) and ggplot2 is installed, produce a
  Kaplan-Meier plot.

- plot_title:

  Character. Title for the plot. Default
  `"Time to Appointment by Insurance Type"`.

- ylab:

  Character. Label for the y-axis, which shows the survival function
  \\S(t)\\ – the fraction of callers who have *not yet* secured an
  appointment by day \\t\\. Default
  `"Callers still awaiting an appointment (%)"`, a plain-language
  phrasing; pass any string to override.

- legend_title:

  Character scalar or `NULL`. Title shown above the colour/fill legend.
  Default `NULL` uses a prettified `group_col` (underscores to spaces,
  title case) rather than the raw variable name; pass an explicit string
  (e.g. `"Subspecialty"`) to override, or `""` to drop the legend title
  entirely.

- palette:

  Character vector of colors, one per group level. Default `NULL` uses
  viridis if installed, otherwise ggplot2 defaults.

- risk_table:

  Logical. If `TRUE` (default) and ggplot2 is available, attach a
  number-at-risk table below the KM plot using patchwork (if installed).

## Value

A named list of class `mysterycall_kaplan_meier` containing:

- `survfit`:

  The [`survfit`](https://rdrr.io/pkg/survival/man/survfit.html) object.

- `logrank_p`:

  Numeric. Log-rank chi-square p-value.

- `logrank_p_fmt`:

  Character. Formatted p-value string, e.g. `"p = 0.003"` or
  `"p < 0.001"`.

- `median_by_group`:

  A `data.frame` with columns `group`, `median_days`, `ci_lower_days`,
  `ci_upper_days`. Medians are `NA` when the survival function never
  drops below 0.5 (median not reached).

- `plot`:

  A `ggplot` object (or a patchwork composite when `risk_table = TRUE`
  and patchwork is installed), or `NULL` when ggplot2 is unavailable or
  `plot = FALSE`.

- `sentence`:

  A character string summarising the result, ready for insertion into a
  manuscript Results section.

## Details

**Required package:** survival must be installed
(`install.packages("survival")`). It is listed in `Suggests`.

**Censoring imputation:** Rows where `event_col = 0` (or `NA`) AND
`time_col = NA` have their time set to `max_days`. Rows with
`event_col = 1` and missing time are dropped with a warning.

**Plot:** The KM step functions are drawn with
[`geom_step`](https://ggplot2.tidyverse.org/reference/geom_path.html)
and shaded CI bands with
[`geom_ribbon`](https://ggplot2.tidyverse.org/reference/geom_ribbon.html).
The log-rank p-value is annotated in the upper-right panel area. If
patchwork is installed and `risk_table = TRUE`, a number-at-risk table
is appended below the main panel.

## See also

[`mysterycall_lmm`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md),
[`mysterycall_poisson_model`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)

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
df <- data.frame(
  days      = c(3, 7, 14, 21, 90, 5, 10, 30, 90, 90),
  offered   = c(1,  1,  1,  1,  0, 1,  1,  1,  0,  0),
  insurance = c(
    "Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid",
    "BCBS",     "BCBS",     "BCBS",     "BCBS",     "BCBS"
  )
)

result <- mysterycall_kaplan_meier(
  data      = df,
  time_col  = "days",
  event_col = "offered",
  group_col = "insurance",
  max_days  = 90
)

cat(result$sentence, "\n")
print(result$median_by_group)
if (!is.null(result$plot)) print(result$plot)
} # }
```
