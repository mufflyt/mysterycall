# Full emmeans interaction plot with optional file save

Extends
[`mysterycall_plot_emmeans_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans_interaction.md)
with three enhancements drawn from the
[`plot_and_save_emmeans()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
pattern in mystery-caller study code:

## Usage

``` r
mysterycall_plot_emmeans_full(
  model,
  specs,
  variable,
  group_col = NULL,
  type = "response",
  use_color = TRUE,
  save_path = NULL,
  width = 10,
  height = 6,
  dpi = 300L
)
```

## Arguments

- model:

  A fitted model accepted by
  [`emmeans::emmeans()`](https://rvlenth.github.io/emmeans/reference/emmeans.html).

- specs:

  Character vector of marginal mean specifications. The first element is
  the x-axis variable; the second (if present) becomes the grouping
  variable for colour / shape.

- variable:

  Character scalar used as the x-axis label (underscores are replaced
  with spaces and the first letter is capitalised).

- group_col:

  Optional character scalar naming the grouping column. Overrides the
  second element of `specs` when supplied.

- type:

  Character scalar passed to
  [`emmeans::emmeans()`](https://rvlenth.github.io/emmeans/reference/emmeans.html)
  as the `type` argument. Use `"response"` (default) for Poisson models
  so values are on the count/rate scale; use `"link"` for the log scale.

- use_color:

  Logical. `TRUE` (default) uses colour to distinguish groups; `FALSE`
  uses shapes and linetypes for greyscale output.

- save_path:

  Optional character scalar. Full file path (e.g.
  `"figures/emmeans_insurance.png"`). When non-`NULL`,
  [`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md)
  is called automatically.

- width, height:

  Numeric. Figure dimensions in inches passed to
  [`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md).
  Defaults `10` x `6`.

- dpi:

  Integer. Resolution for saved figure. Default `300L`.

## Value

Invisibly, a named list with elements:

- `data`:

  `data.frame` from
  [`emmeans::emmeans()`](https://rvlenth.github.io/emmeans/reference/emmeans.html)
  with columns for the x-axis variable, `emmean` (or `rate` for Poisson
  link), `SE`, `df`, `lower.CL`/`upper.CL` (or `asymp.LCL`/`asymp.UCL`
  for large samples), and any grouping variable from `specs`. Exact
  column names depend on the model family.

- `plot`:

  `ggplot` object. Print or pass to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

Capture with `res <- mysterycall_plot_emmeans_full(...)` to access
`res$data` and `res$plot`.

## Details

1.  Uses `type = "response"` by default so Poisson models are plotted on
    the count scale (rates) rather than the log scale.

2.  Detects CI column names automatically – handles both
    `asymp.LCL`/`asymp.UCL` (Poisson response scale) and
    `lower.CL`/`upper.CL` (Gaussian / identity scale).

3.  Accepts a `save_path` argument and calls
    [`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md)
    when supplied.

## See also

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
[`mysterycall_marginal_effects()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_marginal_effects.md),
[`mysterycall_model_metrics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_metrics.md),
[`mysterycall_plot_distribution()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_distribution.md),
[`mysterycall_plot_effect()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_effect.md),
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
res <- mysterycall_plot_emmeans_full(
  model    = fit,
  specs    = ~ insurance | gender,
  variable = "gender",
  use_color = TRUE,
  save_path = "figures/emmeans_gender.png"
)
res$plot
}
```
