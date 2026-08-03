# Greene-journal-ready monochrome ggplot2 theme

Returns a list of ggplot2 theme and scale calls suitable for adding to
any ggplot2 object with `+`. Produces a black-and-white figure
compatible with journals (e.g. Greene) that require greyscale
submissions.

## Usage

``` r
mysterycall_bw_theme(base_size = 12, title_rel = 1.1)
```

## Arguments

- base_size:

  Numeric. Base font size in points. Default `12`.

- title_rel:

  Numeric. Title size as a multiple of `base_size` via
  [`ggplot2::rel()`](https://ggplot2.tidyverse.org/reference/element.html).
  Default `1.1`. (Tip from Rennie 2026 — use
  [`rel()`](https://ggplot2.tidyverse.org/reference/element.html) so
  resizing the chart only requires changing `base_size`.)

## Value

A list of ggplot2 objects that can be added to a ggplot with `+`.

## Note

Inspired by Nicola Rennie's blog posts on monochrome data visualisations
(<https://nrennie.rbind.io/blog/monochrome-data-visualisations/>) and
five ggplot2 functions
(<https://nrennie.rbind.io/blog/five-ggplot2-functions/>).

## See also

Other visualization:
[`mysterycall_acceptance_waffle()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_waffle.md),
[`mysterycall_flowchart()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flowchart.md),
[`mysterycall_plot_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_density.md),
[`mysterycall_plot_line()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_line.md),
[`mysterycall_plot_paired_slope()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_paired_slope.md),
[`mysterycall_plot_raincloud()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_raincloud.md),
[`mysterycall_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_scatter.md)

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  library(ggplot2)
  ggplot(mtcars, aes(x = mpg)) +
    geom_histogram(bins = 10) +
    mysterycall_bw_theme()
}
```
