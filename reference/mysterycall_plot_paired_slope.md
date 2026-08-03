# Within-cluster paired slope plot across scenarios

The visual companion to
[`mysterycall_paired_wait_within_practice()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_wait_within_practice.md)
and
[`mysterycall_paired_acceptance_mcnemar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_acceptance_mcnemar.md):
one line per cluster (practice) connecting its outcome across the
scenarios it was called under, over the raw points. It shows the
within-cluster differencing that motivates the matched design – whether
the *same* practice tends to schedule one persona sooner than another –
rather than the between-practice comparison a boxplot implies. Only
clusters observed under at least two scenarios are drawn (a single point
has no slope to show). Returns a
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html).

## Usage

``` r
mysterycall_plot_paired_slope(
  data,
  value,
  group,
  id,
  title = NULL,
  x_lab = NULL,
  y_lab = value,
  line_alpha = 0.5
)
```

## Arguments

- data:

  A long data frame: one row per cluster x scenario call.

- value:

  Character scalar naming the numeric outcome column.

- group:

  Character scalar naming the grouping / scenario column (the x axis).

- id:

  Character scalar naming the cluster / practice id column (lines are
  grouped by this).

- title, x_lab, y_lab:

  Character scalars for the title and axis labels. `title` defaults to
  `NULL`; `x_lab` to `NULL`; `y_lab` to `value`.

- line_alpha:

  Numeric opacity for the connecting lines. Default `0.5`.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`mysterycall_paired_wait_within_practice()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_wait_within_practice.md),
[`mysterycall_plot_raincloud()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_raincloud.md)

Other visualization:
[`mysterycall_acceptance_waffle()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_waffle.md),
[`mysterycall_bw_theme()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bw_theme.md),
[`mysterycall_flowchart()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flowchart.md),
[`mysterycall_plot_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_density.md),
[`mysterycall_plot_line()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_line.md),
[`mysterycall_plot_raincloud()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_raincloud.md),
[`mysterycall_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_scatter.md)

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  d <- data.frame(
    practice = rep(1:15, each = 2),
    scenario = rep(c("Commercial", "Medicaid"), 15),
    wait     = c(rbind(rpois(15, 10), rpois(15, 22)))
  )
  mysterycall_plot_paired_slope(d, "wait", "scenario", "practice")
}
```
