# Compute the wait-time equalization (crossover) point between two insurance groups

Fits a simple linear regression of one insurance group's wait times
against another (paired by physician), then solves for the crossover day
— the number of business days at which both groups predict the same wait
time. This mirrors the scatter-plot analysis from the ortho sports
medicine mystery-caller Rmd, where Medicaid and BCBS wait times were
plotted on log-log axes and the intersection with the 45-degree (y = x)
line was computed as \\x\_{\text{cross}} = b / (1 - m)\\, where \\m\\ is
the regression slope and \\b\\ is the intercept.

## Usage

``` r
mysterycall_wait_time_crossover(
  data,
  time_col = "business_days_until_appointment",
  group_col = "insurance",
  id_col = "phone",
  group1 = NULL,
  group2 = NULL,
  log_transform = TRUE,
  conf_level = 0.95,
  min_pairs = 10L
)
```

## Arguments

- data:

  A `data.frame` containing the study data.

- time_col:

  Character scalar. Name of the column containing the wait time in
  business days. Must be numeric and strictly positive when
  `log_transform = TRUE`. Default `"business_days_until_appointment"`.

- group_col:

  Character scalar. Name of the insurance/grouping column. Default
  `"insurance"`.

- id_col:

  Character scalar. Name of the physician identifier column used to pair
  observations across insurance groups (e.g., phone number or NPI).
  Default `"phone"`.

- group1:

  Character scalar or `NULL`. Label for the first group (x-axis
  predictor in the regression). When `NULL` (default), the first value
  in alphabetical order among unique `group_col` values is used.

- group2:

  Character scalar or `NULL`. Label for the second group (y-axis outcome
  in the regression). When `NULL` (default), the second value in
  alphabetical order is used.

- log_transform:

  Logical scalar. When `TRUE` (default), both wait-time columns are
  log-transformed before regression, matching the log-log axes of the
  source Rmd. The crossover point is back-transformed with
  [`exp()`](https://rdrr.io/r/base/Log.html) before it is returned. Rows
  where either group value is `<= 0` are silently dropped when
  `log_transform = TRUE`.

- conf_level:

  Numeric scalar in `(0, 1)`. Confidence level passed through; stored on
  the result for downstream use. Default `0.95`.

- min_pairs:

  Integer scalar. Minimum number of paired physicians required after
  dropping incomplete rows. An error is raised when fewer complete pairs
  are found. Default `10L`.

## Value

A named list of class `mysterycall_wait_time_crossover`:

- `crossover_days`:

  Numeric scalar. The equalization point in business days (original
  scale, regardless of `log_transform`). `NA_real_` when the crossover
  is undefined, i.e., when the regression slope is \\\ge 1\\ (diverging)
  or \\\le 0\\ (no consistent direction).

- `slope`:

  Numeric scalar. Regression slope \\m\\.

- `intercept`:

  Numeric scalar. Regression intercept \\b\\.

- `r_squared`:

  Numeric scalar. \\R^2\\ of the fitted linear model.

- `n_pairs`:

  Integer scalar. Number of physicians with non-missing data in both
  groups.

- `group1`:

  Character scalar. Label of the x-axis group.

- `group2`:

  Character scalar. Label of the y-axis group.

- `conf_level`:

  Numeric scalar. As supplied.

- `log_transform`:

  Logical scalar. As supplied.

- `plot_data`:

  A `data.frame` with two columns named after `group1` and `group2`,
  each containing the original-scale (untransformed) wait times for
  physicians with complete pairs. Suitable for external ggplot2
  scatter-plot construction.

- `model`:

  The fitted `lm` object (on the transformed scale when
  `log_transform = TRUE`).

- `sentence`:

  Character scalar. A plain-language summary suitable for direct
  insertion into a manuscript Results section.

## Details

Beyond the crossover point, `group1` patients experience longer waits
than `group2` patients (when \\0 \< m \< 1\\ and the crossover exists).

**Crossover formula.** The regression line is \\y = m x + b\\. Setting
\\y = x\\ (the 45-degree line) and solving gives \\x = b / (1 - m)\\. A
finite, positive crossover requires \\0 \< m \< 1\\:

- \\m \ge 1\\: the regression line never crosses y = x; `group2` wait
  times diverge from `group1`.

- \\m \le 0\\: the relationship is non-positive; no meaningful
  equalization point exists.

When `log_transform = TRUE` the regression operates on
\\\log(\text{days})\\; the crossover is solved on the log scale and then
returned as \\\exp(x\_{\text{cross}})\\.

**Pairing.** Observations are matched on `id_col` using
`merge(..., by = id_col, all = FALSE)`, so only physicians appearing in
*both* insurance groups contribute. When a physician has more than one
observation per group, all observations are kept and merged by their
natural order after subsetting; for studies with exactly one call per
physician per group this is unambiguous.

## See also

[`mysterycall_kaplan_meier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_kaplan_meier.md),
[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md)

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
n_doc         <- 30
bcbs_days     <- pmax(1, round(stats::rnorm(n_doc, mean = 12, sd = 4)))
medicaid_days <- pmax(1, round(stats::rnorm(n_doc, mean = 18, sd = 6)))

df <- data.frame(
  phone     = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
  insurance = rep(c("BCBS", "Medicaid"), each = n_doc),
  business_days_until_appointment = c(bcbs_days, medicaid_days)
)

result <- mysterycall_wait_time_crossover(df, min_pairs = 5L)
print(result)
#> -- mysterycall_wait_time_crossover --
#> 
#> No equalization point exists between BCBS and Medicaid: the regression slope (-0.188) is <= 0, indicating no consistent directional relationship. crossover_days is NA. 
#> 
#> Groups : BCBS (x-axis, group1) vs. Medicaid (y-axis, group2)
#> Pairs  : 30 physicians with data in both groups
#> Scale  : log (regression on log scale; crossover back-transformed)
#> 
#> Crossover point : NA (slope outside (0, 1); see sentence above)
#> Slope (m)       : -0.19
#> Intercept (b)   : 3.17
#> R-squared       : 0.037
#> 
#> Regression summary:
#> 
#> Call:
#> stats::lm(formula = y ~ x, data = fit_df)
#> 
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -2.6781 -0.1276  0.2091  0.3623  0.5725 
#> 
#> Coefficients:
#>             Estimate Std. Error t value Pr(>|t|)    
#> (Intercept)   3.1730     0.4439   7.147 8.88e-08 ***
#> x            -0.1875     0.1811  -1.035    0.309    
#> ---
#> Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
#> 
#> Residual standard error: 0.6476 on 28 degrees of freedom
#> Multiple R-squared:  0.03687,    Adjusted R-squared:  0.002472 
#> F-statistic: 1.072 on 1 and 28 DF,  p-value: 0.3094
#> 

## Access individual components
result$crossover_days
#> [1] NA
result$r_squared
#> [1] 0.03686976
head(result$plot_data)
#>   BCBS Medicaid
#> 1   17       21
#> 2   10       22
#> 3   13       24
#> 4   15       14
#> 5   14       21
#> 6   12        8
```
