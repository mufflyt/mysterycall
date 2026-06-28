# Fit a Linear Mixed Model (LMM) for wait-time analysis

Fits a multilevel linear mixed model
([`lme4::lmer`](https://rdrr.io/pkg/lme4/man/lmer.html)) treating
appointment wait days as a continuous, approximately normal outcome. The
physician identifier is modelled as a random intercept. Fixed-effect
coefficients are returned directly in **days** (not as incidence rate
ratios), making results straightforward to explain to clinical
audiences.

## Usage

``` r
mysterycall_lmm(
  data,
  outcome,
  predictors,
  random_intercept,
  conf_level = 0.95,
  REML = TRUE,
  auto_log = TRUE,
  sensitivity_poisson = "auto",
  ...
)
```

## Arguments

- data:

  A data frame. Rows with `NA` in any model column are dropped; the
  count is reported.

- outcome:

  Character scalar. Name of the continuous wait-day column (e.g.
  `"calendar_days"`). Must be numeric.

- predictors:

  Character vector of fixed-effect column names. Character and factor
  columns are dummy-coded; the reference level is the first level
  alphabetically (or `levels()[[1]]` for ordered factors).

- random_intercept:

  Character scalar. Grouping column for the physician random intercept
  (e.g. `"physician"`). A `(1 | column)` term is added automatically.

- conf_level:

  Numeric. Confidence level for Wald CIs. Default `0.95`.

- REML:

  Logical. Use Restricted Maximum Likelihood? Default `TRUE`
  (recommended for variance estimation). Set `FALSE` for AIC-based model
  comparison.

- auto_log:

  Logical. When `TRUE` (default), the function checks whether the
  outcome is right-skewed (sample skewness \> 1 on non-negative values)
  and automatically applies a
  [`log1p()`](https://rdrr.io/r/base/Log.html) transform before fitting.
  Coefficients are returned on both the log scale (`coef_table`) and
  back-transformed as geometric mean ratios (`gmr_table`). Set to
  `FALSE` to suppress this behaviour and model the raw outcome.

- sensitivity_poisson:

  One of `"auto"` (default), `TRUE`, or `FALSE`. Controls whether a
  Poisson GLMM sensitivity analysis is run on the **original
  untransformed** outcome alongside the LMM:

  `"auto"`

  :   Runs the Poisson model only when the Shapiro-Wilk test on LMM
      residuals returns p \< 0.05, indicating non-normal residuals.

  `TRUE`

  :   Always runs the Poisson sensitivity model.

  `FALSE`

  :   Never runs it.

  Results are stored in `$sensitivity` (a `mysterycall_poisson_model`
  object) and printed as a compact IRR table. Requires `lme4`.

- ...:

  Additional arguments forwarded to
  [`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html).

## Value

A list of class `mysterycall_lmm` with elements:

- `model`:

  `lmerMod` (or `lmerModLmerTest`). The fitted model.

- `coef_table`:

  `tibble`. One row per fixed-effect term: `term`, `estimate`, `se`,
  `t_value`, `df`, `p_value`, `p_value_fmt`, `ci_lower`, `ci_upper`.
  Units are days (raw outcome) or log1p(days) when `log_transformed` is
  `TRUE`.

- `gmr_table`:

  `tibble` or `NULL`. Present only when `log_transformed = TRUE`.
  Columns: `term`, `GMR` (geometric mean ratio of (days + 1) vs.
  reference level), `GMR_lo`, `GMR_hi`, `p_value_fmt`. A GMR \< 1 means
  shorter wait relative to the reference.

- `log_transformed`:

  `logical`. `TRUE` when `auto_log` triggered a
  [`log1p()`](https://rdrr.io/r/base/Log.html) transform.

- `outcome_original`:

  `character`. The column name as supplied by the caller.

- `outcome_used`:

  `character`. The column actually modelled (`log1p_<outcome>` when
  transformed, same as `outcome_original` otherwise).

- `random_effects`:

  `data.frame` from
  [`lme4::VarCorr()`](https://rdrr.io/pkg/nlme/man/VarCorr.html).

- `factor_refs`:

  `list`. Reference levels for character/factor predictors.

- `formula`:

  `formula`. The formula passed to lmer.

- `n`:

  `integer`. Complete-case rows used.

- `n_dropped`:

  `integer`. Rows excluded for missing values.

- `n_clusters`:

  `integer`. Unique values of `random_intercept`.

- `sigma`:

  `numeric`. Residual standard deviation.

- `r_squared`:

  `list`. `marginal` and `conditional` R^2 (Nakagawa & Schielzeth 2013).

- `normality`:

  `list`. Shapiro-Wilk test on model residuals: `statistic`, `p_value`,
  `interpretation`, `method`. Skipped when n \> 5000.

- `convergence`:

  `list`. `converged` (logical), `singular` (logical), `messages`
  (character vector).

- `aic`:

  `numeric`. AIC (valid only when `REML = FALSE`).

- `bic`:

  `numeric`. BIC (valid only when `REML = FALSE`).

- `sensitivity`:

  `mysterycall_poisson_model` or `NULL`. A Poisson GLMM fit on the
  original (untransformed) outcome using the same predictors and random
  intercept. Present when `sensitivity_poisson` triggers; `NULL`
  otherwise. Use `$sensitivity$irr_table` for IRR estimates. IRR \< 1 =
  shorter wait than reference.

- `sensitivity_note`:

  `character` or `NULL`. One-sentence explanation of why the sensitivity
  analysis was (or was not) run.

## Details

**When to use LMM vs. Poisson/NB GLMM:** Prefer LMM when the wait-day
distribution is approximately symmetric with no strong floor effect at
zero (check with a Q-Q plot via
[`plot.mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/plot.mysterycall_lmm.md)).
A Shapiro-Wilk normality test on the residuals is run automatically; a
warning is issued when p \< 0.05 (residuals depart from normality). If
the outcome is right-skewed or contains many zeroes, use
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
or
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md)
instead.

P-values use the Satterthwaite denominator-df approximation when the
`lmerTest` package is available (recommended), and fall back to a
conservative t-approximation with residual df otherwise.

## Interpreting coefficients

**Raw scale (`auto_log = FALSE` or skewness \<= 1):** An estimate of
`+5.2` for `insuranceMedicaid` means physicians called with Medicaid
had, on average, **5.2 more wait days** than the reference group.

**Log scale (`auto_log = TRUE`, skewness \> 1):** Coefficients are on
the `log1p(days)` scale. Use `gmr_table` for interpretation: a GMR of
`0.87` means the group waits ~13% fewer days (\* (days + 1)) than the
reference. Report as: "GMR = 0.87 (95% CI 0.49-1.54), p = 0.631."

## R-squared

Marginal R^2 reflects variance explained by fixed effects alone;
conditional R^2 includes the physician random intercept. Both are
computed from the variance-component decomposition (Nakagawa &
Schielzeth 2013) and do not require any additional packages.

## References

Nakagawa S, Schielzeth H (2013). A general and simple method for
obtaining R^2 from generalized linear mixed-effects models. *Methods in
Ecology and Evolution* 4(2):133-142.
[doi:10.1111/j.2041-210x.2012.00261.x](https://doi.org/10.1111/j.2041-210x.2012.00261.x)

## See also

[`plot.mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/plot.mysterycall_lmm.md)
for Q-Q and residual plots;
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
for count outcomes;
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md)
for overdispersed counts;
[`mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_comparison_table.md)
to compare models by AIC/BIC.

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
  wait_days = round(rnorm(80, mean = 21, sd = 8)),
  insurance = rep(c("Medicaid", "BCBS"), 40),
  physician = rep(paste0("Dr", 1:20), each = 4),
  stringsAsFactors = FALSE
)
fit <- mysterycall_lmm(df, "wait_days", "insurance", "physician")
#> Fitting LMM: wait_days ~ insurance + (1 | physician)
#> Model fitted: n=80, physicians=20, AIC=573.0, sigma=8.62, R2m=0.000, R2c=0.003
print(fit)
#> Linear Mixed Model (REML)  n = 80  physicians = 20
#>   AIC = 573.0   BIC = 582.5   Residual SD = 8.62 days
#>   R^2 marginal = 0.000   conditional = 0.003
#>   Normality: Residuals consistent with normality (p >= 0.05).
#>   Reference levels: insurance='BCBS'
#> 
#> Fixed effects (days):
#>               term estimate   se ci_lower ci_upper p-value
#>        (Intercept)    21.10 1.37    18.42    23.78 < 0.001
#>  insuranceMedicaid     0.15 1.93    -3.63     3.93   0.938
#> 
#> Random intercept (physician):  variance = 0.2004  SD = 0.4476 days
```
