# Multiple imputation by chained equations for missing call outcomes

Performs multiple imputation using
[`mice::mice()`](https://amices.org/mice/reference/mice.html) to handle
missing values in the binary outcome column, fits a multilevel logistic
GLMM
([`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md))
to each imputed dataset, and pools fixed-effect estimates across
imputations using Rubin's rules. Because
[`mice::pool()`](https://amices.org/mice/reference/pool.html) does not
support `glmerMod` objects, pooling is implemented manually.

## Usage

``` r
mysterycall_impute_calls(
  data,
  outcome_col,
  predictors,
  random_intercept,
  m = 20L,
  maxit = 5L,
  seed = 42L,
  conf_level = 0.95,
  verbose = FALSE
)
```

## Arguments

- data:

  A data frame containing at least `outcome_col`, all columns named in
  `predictors`, and `random_intercept`. Rows may have missing values in
  any column; MICE will impute them.

- outcome_col:

  Character scalar. Name of the binary 0/1 outcome column. Values must
  be in {0, 1} (integer or numeric) or logical.

- predictors:

  Character vector. Fixed-effect predictor column names passed to
  [`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md).

- random_intercept:

  Character scalar. Grouping column for the physician random intercept
  (e.g. `"physician"`). Passed directly to
  [`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md).

- m:

  Integer. Number of imputed datasets to generate. Default `20L`. Values
  below `5` are not recommended; values above `50` rarely add precision.

- maxit:

  Integer. Number of MICE iterations per imputation. Default `5L`.

- seed:

  Integer. Random seed for
  [`mice::mice()`](https://amices.org/mice/reference/mice.html)
  reproducibility. Default `42L`.

- conf_level:

  Numeric strictly between 0 and 1. Confidence level for pooled Wald
  intervals on the odds-ratio scale. Default `0.95`.

- verbose:

  Logical. If `TRUE`, MICE progress is printed to the console
  (`printFlag = TRUE`). Default `FALSE`.

## Value

A list of class `mysterycall_impute_calls` containing:

- `pooled_table`:

  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  with one row per fixed-effect term and columns: `term`,
  `estimate_logodds` (pooled log-OR), `pooled_se`, `or` (pooled odds
  ratio), `ci_lower`, `ci_upper`, `p_value`, `p_fmt`, `fmi` (fraction of
  missing information).

- `m`:

  Integer. Number of imputations used.

- `n_missing`:

  Integer. Count of `NA` values in `outcome_col`.

- `pct_missing`:

  Numeric. Percentage of rows with missing outcome.

- `individual_fits`:

  List of `m` `mysterycall_logistic_model` objects, one per imputed
  dataset.

- `sentence`:

  Character. Publication-ready summary sentence, e.g.
  `"Results were robust to multiple imputation (m=20): OR 0.61, 95% CI 0.40-0.93, p=0.021, FMI=0.08."`
  Uses the first non-intercept term.

## Details

**Rubin's rules (1987)**

1.  \\\bar{Q} = \frac{1}{m} \sum\_{i=1}^{m} \hat{\beta}\_i\\ (pooled
    estimate)

2.  \\\bar{U} = \frac{1}{m} \sum\_{i=1}^{m} \hat{\text{SE}}\_i^2\\
    (within-imputation variance)

3.  \\B = \frac{1}{m-1} \sum\_{i=1}^{m} (\hat{\beta}\_i - \bar{Q})^2\\
    (between-imputation variance)

4.  \\T = \bar{U} + \left(1 + \frac{1}{m}\right) B\\ (total variance)

5.  Degrees of freedom: \\\nu = (m-1) \left(1 + \frac{\bar{U}}{(1+1/m)
    B}\right)^2\\

6.  Fraction of missing information: \\\text{FMI} = \frac{B + B/m}{T}\\

## Missingness warning

If fewer than 1% of `outcome_col` values are missing, a
[`base::warning()`](https://rdrr.io/r/base/warning.html) is emitted
noting that imputation may be unnecessary. The function still proceeds
so you can confirm robustness.

## mice in Suggests

`mice` is listed under `Suggests`, not `Imports`. If it is not
installed, the function stops with an informative message. Install with
`install.packages("mice")`.

## See also

[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md)
which is called on each imputed dataset;
[`mice::mice()`](https://amices.org/mice/reference/mice.html) for
imputation engine documentation.

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
if (FALSE) { # \dontrun{
library(mice)
set.seed(1)
n_phys <- 20L
n_calls <- 4L
n <- n_phys * n_calls

df <- data.frame(
  offered   = rbinom(n, 1L, 0.70),
  insurance = rep(c("Medicaid", "BCBS"), n / 2L),
  physician = rep(paste0("Dr", seq_len(n_phys)), each = n_calls),
  stringsAsFactors = FALSE
)

# Introduce ~15% missingness in the outcome
miss_idx <- sample(seq_len(n), size = round(n * 0.15))
df$offered[miss_idx] <- NA_integer_

result <- mysterycall_impute_calls(
  data             = df,
  outcome_col      = "offered",
  predictors       = "insurance",
  random_intercept = "physician",
  m                = 10L,
  seed             = 2024L
)

print(result)
result$pooled_table
result$sentence
} # }
```
