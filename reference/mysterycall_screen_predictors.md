# Screen candidate predictors for a GLMM outcome

Fits one mixed-effects model per candidate column and returns a ranked
table of incidence rate ratios (Poisson / negative binomial) or odds
ratios (logistic), confidence intervals, and p-values. This answers the
reviewer question "how did you choose predictors?" by providing a
pre-specified, reproducible univariable screening step prior to the main
multivariable model.

## Usage

``` r
mysterycall_screen_predictors(
  data,
  outcome_col,
  random_intercept,
  candidate_cols = NULL,
  exclude_cols = character(0L),
  family = c("poisson", "nb", "logistic"),
  alpha_screen = 0.2,
  conf_level = 0.95,
  min_levels = 2L,
  verbose = FALSE,
  max_predictors = 100L
)
```

## Arguments

- data:

  A data frame containing all columns referenced by `outcome_col`,
  `random_intercept`, and `candidate_cols`.

- outcome_col:

  Character scalar. Name of the outcome column. For `family = "poisson"`
  or `"nb"` this must be a non-negative integer count; for
  `family = "logistic"` it must be 0/1 or a two-level factor.

- random_intercept:

  Character scalar. Name of the grouping column for the physician-level
  random intercept (e.g. `"physician"` or `"last"`).

- candidate_cols:

  Character vector or `NULL`. Columns to screen. When `NULL`, all
  columns in `data` are used except `outcome_col`, `random_intercept`,
  and any columns listed in `exclude_cols`.

- exclude_cols:

  Character vector. Columns to always skip, regardless of
  `candidate_cols`. Default `character(0)`.

- family:

  Character scalar. Model family: `"poisson"` (default), `"nb"`
  (negative binomial via glmmTMB), or `"logistic"` (binomial logit).

- alpha_screen:

  Numeric scalar. Liberal p-value threshold used only to flag
  "significant" predictors in the output table. Default `0.20`
  (appropriate for variable selection, not confirmatory inference).

- conf_level:

  Numeric scalar in (0, 1). Confidence level for Wald intervals. Default
  `0.95`.

- min_levels:

  Integer scalar. Predictors with fewer than `min_levels` unique non-NA
  values are skipped. Default `2L`.

- verbose:

  Logical. When `TRUE`, prints a one-line progress message before
  fitting each predictor. Default `FALSE`.

- max_predictors:

  Integer scalar. Maximum number of predictors to fit; screening stops
  after this many attempts (skipped predictors count toward the limit).
  Default `100L`.

## Value

A list of class `"mysterycall_screen_predictors"` with elements:

- `table`:

  A
  [`tibble::tibble`](https://tibble.tidyverse.org/reference/tibble.html)
  with one row per candidate column and columns:

  `predictor`

  :   Character. Column name.

  `estimate`

  :   Numeric. IRR (Poisson/NB) or OR (logistic). `NA` when fitting
      failed or predictor was skipped.

  `ci_lower`

  :   Numeric. Lower confidence bound (exponentiated).

  `ci_upper`

  :   Numeric. Upper confidence bound (exponentiated).

  `p_value`

  :   Numeric. Two-sided Wald p-value.

  `p_fmt`

  :   Character. Formatted p-value (`"< 0.001"` or `"0.XXX"`).

  `n_levels`

  :   Integer. Number of unique non-NA values observed in that column.

  `significant`

  :   Logical. `TRUE` when `p_value < alpha_screen`.

  `skipped`

  :   Logical. `TRUE` when the predictor was not fitted (too few levels,
      or error during fitting).

  `skip_reason`

  :   Character. Explanation when `skipped = TRUE`; `NA_character_`
      otherwise.

  Rows are sorted by `p_value` ascending (skipped rows last).

- `n_screened`:

  Integer. Number of predictors actually fitted (not skipped).

- `n_significant`:

  Integer. Number of fitted predictors with `p_value < alpha_screen`.

- `family`:

  Character. The `family` argument used.

- `sentence`:

  Character. A plain-language summary suitable for a Methods or Results
  section.

- `significant_predictors`:

  Character vector of predictor names with `p_value < alpha_screen`.

## Details

For each variable in `candidate_cols` the function:

1.  Skips the variable when it has fewer than `min_levels` unique non-NA
    values.

2.  Builds the formula `outcome ~ predictor + (1 | random_intercept)`.

3.  Fits with [`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html)
    (Poisson or binomial) or
    [`glmmTMB::glmmTMB()`](https://rdrr.io/pkg/glmmTMB/man/glmmTMB.html)
    (negative binomial), wrapped in
    [`tryCatch()`](https://rdrr.io/r/base/conditions.html).

4.  Extracts the coefficient for the first non-intercept term, then
    exponentiates to obtain the IRR or OR and its Wald confidence
    interval.

5.  Labels the result "significant" when `p < alpha_screen`.

## Interpretation note

`alpha_screen = 0.20` is deliberately liberal. This is standard practice
for predictor pre-selection (Hosmer & Lemeshow recommend 0.15-0.25); it
is **not** a significance threshold for the final model.

## Negative binomial

When `family = "nb"`, the `glmmTMB` package is required.
[`glmmTMB::glmmTMB()`](https://rdrr.io/pkg/glmmTMB/man/glmmTMB.html) is
called with `family = glmmTMB::nbinom2(link = "log")`.

## See also

[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_select_best_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_select_best_model.md),
[`mysterycall_screen_interactions()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_screen_interactions.md)

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
if (requireNamespace("lme4", quietly = TRUE)) {
  set.seed(42)
  n <- 120
  df <- data.frame(
    wait_days   = rpois(n, lambda = 14),
    insurance   = sample(c("Medicaid", "BCBS"), n, replace = TRUE),
    gender      = sample(c("M", "F"), n, replace = TRUE),
    region      = sample(c("NE", "SE", "MW", "W"), n, replace = TRUE),
    practice_sz = sample(1:5, n, replace = TRUE),
    physician   = rep(paste0("Dr_", 1:12), each = 10),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_screen_predictors(
    data             = df,
    outcome_col      = "wait_days",
    random_intercept = "physician",
    family           = "poisson",
    alpha_screen     = 0.20,
    verbose          = TRUE
  )
  print(result$table)
  cat(result$sentence, "\n")
}
#> [screen_predictors] (1/4) Fitting: insurance  (n_levels = 2)
#> boundary (singular) fit: see help('isSingular')
#> [screen_predictors] (2/4) Fitting: gender  (n_levels = 2)
#> boundary (singular) fit: see help('isSingular')
#> [screen_predictors] (3/4) Fitting: region  (n_levels = 4)
#> boundary (singular) fit: see help('isSingular')
#> [screen_predictors] (4/4) Fitting: practice_sz  (n_levels = 5)
#> boundary (singular) fit: see help('isSingular')
#> # A tibble: 4 × 10
#>   predictor   estimate ci_lower ci_upper p_value p_fmt n_levels significant
#>   <chr>          <dbl>    <dbl>    <dbl>   <dbl> <chr>    <int> <lgl>      
#> 1 insurance      0.924    0.840     1.02   0.102 0.102        2 TRUE       
#> 2 practice_sz    1.02     0.986     1.06   0.244 0.244        5 FALSE      
#> 3 gender         1.01     0.918     1.11   0.855 0.855        2 FALSE      
#> 4 region         1.00     0.876     1.15   0.981 0.981        4 FALSE      
#> # ℹ 2 more variables: skipped <lgl>, skip_reason <chr>
#> Variable screening (N = 4 candidate predictors) fitted univariable Poisson GLMM models (IRR = exp(beta), Wald 95% CI); 1 variable met the liberal p < 0.20 screening threshold: insurance. 
# }
```
