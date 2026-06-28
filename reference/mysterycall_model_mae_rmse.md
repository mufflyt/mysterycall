# Compute MAE, RMSE, Pearson R², and MAPE for a fitted model

Evaluates prediction accuracy for any fitted
[`mysterycall_lmm`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md),
[`mysterycall_poisson_model`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
or
[`mysterycall_nb_model`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md)
object by comparing actual outcome values against in-sample or
out-of-sample predictions. Optionally back-transforms predictions from a
log scale and produces an actual-vs-predicted scatter plot with a
45-degree reference line.

## Usage

``` r
mysterycall_model_mae_rmse(
  fit,
  newdata = NULL,
  actual_col = NULL,
  back_transform = NULL,
  conf_level = 0.95,
  plot = TRUE,
  plot_title = NULL
)
```

## Arguments

- fit:

  A `mysterycall_lmm`, `mysterycall_poisson_model`, or
  `mysterycall_nb_model` object returned by
  [`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md),
  [`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
  or
  [`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
  respectively.

- newdata:

  A `data.frame` or `NULL`. If `NULL` (default), in-sample predictions
  are computed using the training data stored in the model object. If a
  data frame is supplied, out-of-sample predictions are generated via
  `predict(fit$model, newdata = newdata, ...)`.

- actual_col:

  Character scalar or `NULL`. Name of the outcome column. If `NULL`
  (default), the column name is extracted automatically from the
  left-hand side of `fit$formula`. For a log-transformed LMM with
  `newdata` supplied, the column must be the *transformed* outcome
  column (e.g., `"log1p_wait_days"`) unless you pass `actual_col`
  explicitly.

- back_transform:

  Logical scalar or `NULL`. When `TRUE`, predictions and actual values
  are back-transformed via [`exp()`](https://rdrr.io/r/base/Log.html)
  before computing errors, which places MAE and RMSE on the original
  (untransformed) scale. When `NULL` (default), auto-detected: `TRUE` if
  `fit$log_transformed` is `TRUE` (LMM with log scale), `FALSE`
  otherwise. Setting this explicitly overrides the auto-detection.

- conf_level:

  Numeric. Reserved for future prediction-interval coverage
  calculations. Default `0.95`. Must be in `(0, 1)`.

- plot:

  Logical. If `TRUE` (default) and ggplot2 is available, an
  actual-vs-predicted scatter plot is created, printed to the active
  graphics device, and stored in `$plot`. If `ggplot2` is not installed
  a message is emitted and `$plot` is `NULL`.

- plot_title:

  Character scalar or `NULL`. Title for the plot. When `NULL` (default),
  a title is auto-generated from the model class.

## Value

A list of class `mysterycall_model_mae_rmse` with elements:

- `mae`:

  `numeric`. Mean absolute error on the (back-transformed) scale.

- `rmse`:

  `numeric`. Root mean squared error on the (back-transformed) scale.

- `r2_pearson`:

  `numeric`. Pearson \\R^2\\ = squared correlation between actual and
  predicted values.

- `mape`:

  `numeric`. Mean absolute percentage error (percent). Rows where
  `actual == 0` are excluded. `NA` when all actual values are zero.

- `n`:

  `integer`. Number of observations used (after removing `NA` pairs).

- `predictions`:

  `data.frame`. One row per observation with columns `actual`,
  `predicted`, and `residual` (= actual - predicted), all on the
  (back-transformed) scale.

- `plot`:

  `ggplot` or `NULL`. The actual-vs-predicted scatter plot, or `NULL`
  when `plot = FALSE` or ggplot2 is unavailable.

- `sentence`:

  `character`. Ready-to-paste summary sentence, e.g.:
  `"Model MAE = 3.2 days, RMSE = 4.5 days, R2 = 0.81, MAPE = 12.3% (N=80)."`

## Details

**When to use:** After fitting a model with
[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
or
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
call this function to quantify how closely the fitted values track the
observed outcomes. Useful for model comparison and for reporting
prediction accuracy in the methods section.

**Back-transformation for log-transformed LMM:** When the LMM was fitted
on a [`log1p()`](https://rdrr.io/r/base/Log.html)-transformed outcome
(`fit$log_transformed = TRUE`), `back_transform` is automatically set to
`TRUE`. Predictions from
[`predict()`](https://rdrr.io/r/stats/predict.html) are on the log
scale; [`exp()`](https://rdrr.io/r/base/Log.html) is applied before
computing errors, so MAE and RMSE are reported in the units of the
original outcome (days). Actual values stored in the model frame are
also on the log scale and receive the same
[`exp()`](https://rdrr.io/r/base/Log.html) back-transform for a
consistent comparison.

## Metrics

- MAE:

  `mean(|actual - predicted|)`. Scale-dependent; same units as the
  outcome.

- RMSE:

  `sqrt(mean((actual - predicted)^2))`. More sensitive to large errors
  than MAE.

- R2 (Pearson):

  `cor(actual, predicted)^2`. Measures linear agreement; does **not**
  equal the model's marginal R^2.

- MAPE:

  `mean(|actual - predicted| / |actual|) * 100`. Unit-free percentage;
  undefined when actual = 0.

## Out-of-sample use

Pass `newdata` for external validation. The grouping variable (random
intercept) should be present in `newdata` so that `lme4` / glmmTMB can
condition on estimated BLUPs; pass it as `re.form = NA` (via
[`predict()`](https://rdrr.io/r/stats/predict.html) directly) for pure
population-level predictions.

## See also

[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md)

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
# \donttest{
# Demonstrate the print method on a pre-built result object
# (no lme4 required).
fake_result <- structure(
  list(
    mae        = 3.2,
    rmse       = 4.5,
    r2_pearson = 0.81,
    mape       = 12.3,
    n          = 80L,
    predictions = data.frame(
      actual    = c(20.0, 25.0, 18.0),
      predicted = c(18.3, 27.1, 19.5),
      residual  = c( 1.7, -2.1, -1.5),
      stringsAsFactors = FALSE
    ),
    plot     = NULL,
    sentence = paste0(
      "Model MAE = 3.2 days, RMSE = 4.5 days, ",
      "R2 = 0.81, MAPE = 12.3% (N=80)."
    )
  ),
  class = "mysterycall_model_mae_rmse"
)
print(fake_result)
#> Model MAE = 3.2 days, RMSE = 4.5 days, R2 = 0.81, MAPE = 12.3% (N=80). 
#> 
#> N = 80 observations
#> MAPE = 12.3%
#> 
#> Predictions (actual, predicted, residual):
#>      actual       predicted        residual      
#>  Min.   :18.0   Min.   :18.30   Min.   :-2.1000  
#>  1st Qu.:19.0   1st Qu.:18.90   1st Qu.:-1.8000  
#>  Median :20.0   Median :19.50   Median :-1.5000  
#>  Mean   :21.0   Mean   :21.63   Mean   :-0.6333  
#>  3rd Qu.:22.5   3rd Qu.:23.30   3rd Qu.: 0.1000  
#>  Max.   :25.0   Max.   :27.10   Max.   : 1.7000  
# }
```
