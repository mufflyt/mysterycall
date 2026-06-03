# Compute average marginal effects for a Poisson GLM or GLMER

Computes average marginal effects for each predictor in a fitted Poisson
GLM (`glm` with `family = poisson`) or Poisson GLMER (`glmerMod` from
lme4). Also accepts a `mysterycall_poisson_model` object, from which the
fitted model is extracted automatically.

## Usage

``` r
mysterycall_marginal_effects(
  model,
  term = NULL,
  data = NULL,
  type = c("response", "link"),
  eps = 0.0000001
)
```

## Arguments

- model:

  A fitted `glm` (with `family = poisson`), a `glmerMod` object from
  lme4, or a `mysterycall_poisson_model` object. For
  `mysterycall_poisson_model`, the `$model` component is extracted
  automatically.

- term:

  Character vector of predictor names for which to compute marginal
  effects. Pass the variable name (e.g. `"cyl"`), not the dummy-encoded
  column name (e.g. `"factor(cyl)6"`). If `NULL` (default), effects are
  computed for all predictors in the model frame.

- data:

  Optional data frame to use instead of the stored model data. Columns
  must use the original (un-transformed) variable names. If `NULL`
  (default), the data used to fit the model is retrieved automatically.

- type:

  Character scalar, either `"response"` (default) or `"link"`. Passed to
  [`stats::predict()`](https://rdrr.io/r/stats/predict.html). For lme4
  models, population-average predictions (`re.form = NA`) are always
  used.

- eps:

  Positive numeric scalar. Step size for numerical differentiation of
  continuous predictors. Default `1e-7`.

## Value

A `data.frame` with one row per term-level combination and columns:

- `term`:

  Character. The predictor name (as supplied in `term` or derived from
  the model frame). Continuous predictors yield one row; categorical
  predictors yield one row per non-reference level.

- `level`:

  Character or `NA_character_`. `NA_character_` for continuous
  predictors; the factor level name for categorical predictors. The
  reference level is omitted from the output.

- `ame`:

  Numeric. The average marginal effect. For continuous predictors, the
  mean finite-difference derivative across all observations. For
  categorical predictors, the mean difference in predicted values versus
  the reference level.

- `variable_type`:

  Character. Either `"continuous"` or `"categorical"`.

Row names are not set. No special class attributes are added.

## Details

For continuous predictors, the AME is estimated by numerical
differentiation: predicted values are computed at the predictor bumped
up and down by `eps`, and the average finite-difference derivative is
returned. For factor (categorical) predictors, the AME for each
non-reference level is the average difference in predicted values
between that level and the reference level, holding all other predictors
constant.

Standard errors and confidence intervals are NOT computed by this
function. Use
[`mysterycall_bootstrap_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bootstrap_ci.md)
for bootstrap-based confidence intervals.

## Standard errors

This function returns only the AME point estimate. Standard errors and
confidence intervals require a bootstrap procedure; see
[`mysterycall_bootstrap_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bootstrap_ci.md).

## lme4 models

For `glmerMod` objects, predictions use `re.form = NA` so that the
marginal effect is averaged over the population (not conditional on
estimated random effects). The lme4 package must be installed.

## Formulas with in-line transformations

When a formula contains in-line calls such as `factor(cyl)`, pass the
underlying variable name (`"cyl"`) to `term`, not the transformed name.
The function resolves the original column automatically.

## See also

[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_model_metrics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_metrics.md)

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
[`mysterycall_bootstrap_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bootstrap_ci.md),
[`mysterycall_irr_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_plot.md),
[`mysterycall_model_metrics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_metrics.md),
[`mysterycall_plot_distribution()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_distribution.md),
[`mysterycall_plot_effect()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_effect.md),
[`mysterycall_plot_emmeans_full()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans_full.md),
[`mysterycall_plot_emmeans_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans_interaction.md),
[`mysterycall_plot_inclexcl()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_inclexcl.md),
[`mysterycall_plot_residuals()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_residuals.md),
[`mysterycall_plot_sjplot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_sjplot_interaction.md),
[`mysterycall_plot_stacked_bar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_stacked_bar.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_screen_interactions()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_screen_interactions.md),
[`mysterycall_select_best_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_select_best_model.md),
[`mysterycall_wait_time_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_summary.md),
[`print.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_poisson_model.md)

## Examples

``` r
m <- glm(vs ~ wt + factor(cyl), data = mtcars, family = poisson())
mysterycall_marginal_effects(m)
#> Error in mysterycall_marginal_effects(m): could not find function "mysterycall_marginal_effects"
mysterycall_marginal_effects(m, term = "wt")
#> Error in mysterycall_marginal_effects(m, term = "wt"): could not find function "mysterycall_marginal_effects"
mysterycall_marginal_effects(m, term = "cyl")
#> Error in mysterycall_marginal_effects(m, term = "cyl"): could not find function "mysterycall_marginal_effects"
```
