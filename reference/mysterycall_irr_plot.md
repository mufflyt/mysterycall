# IRR forest plot for a Poisson GLMER result

Produces a publication-ready forest plot showing each fixed-effect term
as an incidence rate ratio (point) with its Wald confidence interval
(horizontal bar). The intercept row is excluded by default. A vertical
reference line marks IRR = 1 (no effect). Requires only `ggplot2`, which
is already in the package Imports.

## Usage

``` r
mysterycall_irr_plot(
  x,
  include_intercept = FALSE,
  reference_line = 1,
  point_size = 3,
  color_sig = "#C0392B",
  color_ns = "#2C3E50",
  x_label = "Incidence Rate Ratio (IRR)",
  title = NULL,
  x_log = FALSE
)
```

## Arguments

- x:

  A `mysterycall_poisson_model` object from
  [`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
  **or** a data frame with columns `term`, `irr`, `ci_lower`, `ci_upper`
  (and optionally `p_value`).

- include_intercept:

  Logical. When `FALSE` (default) the `(Intercept)` row is dropped
  before plotting.

- reference_line:

  Numeric. X-axis position for the null-effect vertical line. Default
  `1` (IRR = 1).

- point_size:

  Numeric. Size of the IRR point. Default `3`.

- color_sig:

  Character. Colour for terms with `p_value < 0.05`. Default `"#C0392B"`
  (red). Only applied when the `p_value` column is present.

- color_ns:

  Character. Colour for non-significant terms (or when `p_value` is
  absent). Default `"#2C3E50"` (dark navy).

- x_label:

  Character. X-axis label. Default `"Incidence Rate Ratio (IRR)"`.

- title:

  Character. Plot title. `NULL` (default) produces no title.

- x_log:

  Logical. When `TRUE` the X axis is log-transformed so that equal-ratio
  distances look equal. Default `FALSE`.

## Value

A `ggplot` object. Print it or save with
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## See also

[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)

Other outcomes:
[`.as_positive_logical()`](https://mufflyt.github.io/mysterycall/reference/dot-as_positive_logical.md),
[`.disp_rate_ci()`](https://mufflyt.github.io/mysterycall/reference/dot-disp_rate_ci.md),
[`.fmt_model_pval()`](https://mufflyt.github.io/mysterycall/reference/dot-fmt_model_pval.md),
[`.fmt_pvalue()`](https://mufflyt.github.io/mysterycall/reference/dot-fmt_pvalue.md),
[`.wait_stats()`](https://mufflyt.github.io/mysterycall/reference/dot-wait_stats.md),
[`.wilson_ci()`](https://mufflyt.github.io/mysterycall/reference/dot-wilson_ci.md),
[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md),
[`mysterycall_marginal_effects()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_marginal_effects.md),
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
if (requireNamespace("lme4", quietly = TRUE)) {
  set.seed(1978)
  df <- data.frame(
    wait_days = rpois(40, lambda = 18),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    gender    = sample(c("Male", "Female"), 40, replace = TRUE),
    physician = rep(paste0("Dr_", 1:8), each = 5),
    stringsAsFactors = FALSE
  )
  result <- suppressWarnings(mysterycall_poisson_model(
    df, "wait_days", c("insurance", "gender"), "physician"
  ))
  mysterycall_irr_plot(result)
}
#> Fitting Poisson GLMER: wait_days ~ insurance + gender + (1 | physician)
#> boundary (singular) fit: see help('isSingular')
#> Model fitted: n=40, physicians=8, AIC=230.8, overdispersion=0.90
#> `height` was translated to `width`.
```
