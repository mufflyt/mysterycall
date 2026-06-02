# Plot marginal effects for a single model term

Calls [`effects::effect()`](https://rdrr.io/pkg/effects/man/effect.html)
on a fitted model and returns a ggplot2 ribbon plot of the marginal
predicted values with 95% confidence bands. Works with any model class
supported by the **effects** package (lm, glm, glmerMod, lmerMod, ...).

## Usage

``` r
mysterycall_plot_effect(
  model,
  term,
  type = c("response", "link"),
  x_label = NULL,
  y_label = NULL
)
```

## Arguments

- model:

  A fitted model object.

- term:

  Character scalar. The term to visualise (must match a fixed effect in
  the model, e.g. `"insurance"`, `"age"`, or `"insurance:gender"` for an
  interaction).

- type:

  Character scalar. `"response"` (default) plots on the response scale
  (exponentiating for Poisson/logistic); `"link"` plots on the linear
  predictor scale.

- x_label:

  Character scalar. X-axis label. Defaults to `term`.

- y_label:

  Character scalar. Y-axis label. Defaults to `"Predicted response"` or
  `"Linear predictor"`.

## Value

A `ggplot` object.

## See also

Other outcomes:
[`.as_positive_logical()`](https://mufflyt.github.io/mysterycall/reference/dot-as_positive_logical.md),
[`.disp_rate_ci()`](https://mufflyt.github.io/mysterycall/reference/dot-disp_rate_ci.md),
[`.fmt_model_pval()`](https://mufflyt.github.io/mysterycall/reference/dot-fmt_model_pval.md),
[`.fmt_pvalue()`](https://mufflyt.github.io/mysterycall/reference/dot-fmt_pvalue.md),
[`.wait_stats()`](https://mufflyt.github.io/mysterycall/reference/dot-wait_stats.md),
[`.wilson_ci()`](https://mufflyt.github.io/mysterycall/reference/dot-wilson_ci.md),
[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md),
[`mysterycall_irr_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_plot.md),
[`mysterycall_marginal_effects()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_marginal_effects.md),
[`mysterycall_model_metrics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_metrics.md),
[`mysterycall_plot_distribution()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_distribution.md),
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
if (FALSE) { # interactive()
m <- glm(mpg ~ wt + hp, data = mtcars, family = gaussian())
mysterycall_plot_effect(m, "wt")
}
```
