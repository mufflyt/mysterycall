# Raincloud plot of a numeric outcome by group

A raincloud layers a violin (the distribution), a boxplot (IQR and
median), and the jittered raw points (every observation) in one figure –
the canonical way to show a right-skewed audit outcome such as wait time
across caller scenarios without hiding the sample size or the spread.
Returns a
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
you can theme, facet, or save.

## Usage

``` r
mysterycall_plot_raincloud(
  data,
  value,
  group,
  add_median_labels = TRUE,
  title = NULL,
  x_lab = NULL,
  y_lab = value,
  point_alpha = 0.6
)
```

## Arguments

- data:

  A data frame.

- value:

  Character scalar naming the numeric outcome column (e.g. wait days).

- group:

  Character scalar naming the grouping / scenario column.

- add_median_labels:

  Logical; annotate each group with its median. Default `TRUE`.

- title, x_lab, y_lab:

  Character scalars for the plot title and axis labels. `title` defaults
  to `NULL` (none); `x_lab` defaults to `NULL`; `y_lab` defaults to
  `value`.

- point_alpha:

  Numeric opacity for the jittered points. Default `0.6`.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`mysterycall_plot_paired_slope()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_paired_slope.md),
[`mysterycall_plot_distribution()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_distribution.md)

Other visualization:
[`mysterycall_acceptance_waffle()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_waffle.md),
[`mysterycall_bw_theme()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bw_theme.md),
[`mysterycall_flowchart()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flowchart.md),
[`mysterycall_plot_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_density.md),
[`mysterycall_plot_line()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_line.md),
[`mysterycall_plot_paired_slope()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_paired_slope.md),
[`mysterycall_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_scatter.md)

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  d <- data.frame(
    wait     = c(rpois(40, 10), rpois(40, 25)),
    scenario = rep(c("Commercial", "Medicaid"), each = 40)
  )
  mysterycall_plot_raincloud(d, "wait", "scenario")
}
```
