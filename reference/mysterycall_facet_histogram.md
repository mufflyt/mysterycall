# Faceted histogram of a numeric variable by group

Produces a faceted histogram (one panel per level of `facet_col`) with
an optional density-curve overlay, per-group mean line, and per-facet
annotation of descriptive statistics. Mirrors the source pattern from
the analysis Rmd (lines 1094-1150).

## Usage

``` r
mysterycall_facet_histogram(
  data,
  x_col,
  facet_col,
  binwidth = 1,
  fill = "skyblue",
  color = "black",
  alpha = 0.7,
  show_mean_line = TRUE,
  show_stats_text = TRUE,
  x_label = NULL,
  y_label = "Count",
  title = NULL,
  monochrome = FALSE,
  base_size = 12,
  reorder_facets = FALSE,
  dpi = 150,
  output_dir = NULL,
  filename = "facet_histogram.png"
)
```

## Arguments

- data:

  A data frame.

- x_col:

  Character scalar. Name of the numeric column to plot on the x-axis.

- facet_col:

  Character scalar. Name of the grouping column used for the facet
  panels.

- binwidth:

  Numeric. Histogram bin width. Default `1`.

- fill:

  Character. Bar fill colour. Default `"skyblue"`.

- color:

  Character. Bar border colour. Default `"black"`.

- alpha:

  Numeric. Bar transparency \[0, 1\]. Default `0.7`.

- show_mean_line:

  Logical. Add a vertical dashed red line at the group mean? Default
  `TRUE`.

- show_stats_text:

  Logical. Annotate each facet with Mean, SD, Median, 25th percentile,
  and 75th percentile? Default `TRUE`.

- x_label:

  Character or `NULL`. X-axis label. Defaults to `x_col`.

- y_label:

  Character. Y-axis label. Default `"Count"`.

- title:

  Character or `NULL`. Plot title. Defaults to
  `"Distribution of [x_col] by [facet_col] (N = [n])"`.

- monochrome:

  Logical. If `TRUE`, apply a greyscale fill and
  [`mysterycall_bw_theme()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bw_theme.md)
  suitable for Greene-journal submissions. Overrides `fill` and the
  mean-line colour. Default `FALSE`. (Inspired by Nicola Rennie, 2025.)

- base_size:

  Numeric. Base font size in points passed to
  [`theme_light()`](https://ggplot2.tidyverse.org/reference/ggtheme.html).
  Default `12`. (Rennie 2026.)

- reorder_facets:

  Logical. If `TRUE`, facet panels are reordered from highest to lowest
  median of `x_col` rather than alphabetically. (Rennie 2024 — order
  groups by a summary statistic.) Default `FALSE`.

- dpi:

  Integer. Resolution for the saved PNG. Default `150`.

- output_dir:

  Character, `NULL`, or `NA`. Directory for PNG output. `NULL` (default)
  writes to a session temp directory via
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).
  `NA` skips writing entirely.

- filename:

  Character. Output file name. Default `"facet_histogram.png"`.

## Value

A `ggplot` object, returned invisibly. As a side effect, writes a PNG to
`output_dir` unless `output_dir` is `NA`.

## Note

Several axis and theme improvements are inspired by Nicola Rennie:
`guide_axis(check.overlap = TRUE)` (Rennie 2026), `size.unit = "pt"` for
consistent text sizing (Rennie 2026), `plot.title.position = "plot"`
(Rennie 2026), `bg = "white"` in `ggsave` (Rennie 2026), monochrome
palette and
[`mysterycall_bw_theme()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bw_theme.md)
(Rennie 2025), facet reordering by median (Rennie 2024).

## See also

Other descriptive helpers:
[`mysterycall_demographics_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_demographics_sentence.md),
[`mysterycall_descriptive_stats()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_descriptive_stats.md),
[`mysterycall_distribution_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_distribution_summary.md),
[`mysterycall_log_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_histogram.md),
[`mysterycall_physicians_with_detail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physicians_with_detail.md),
[`mysterycall_scenario_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md),
[`mysterycall_sensitivity_both_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)

## Examples

``` r
set.seed(1)
df <- data.frame(
  days      = c(rpois(60, 5), rpois(60, 10)),
  insurance = rep(c("Medicaid", "BCBS"), each = 60)
)
mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                             output_dir = NA)
```
