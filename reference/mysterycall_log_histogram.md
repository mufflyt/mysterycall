# Log-scale faceted histogram of a numeric variable by group

A thin wrapper around a self-contained histogram builder that applies a
log-scale transformation to the x-axis. Values `<= 0` are silently
removed before plotting (log of zero is `-Inf`). Mirrors the source
pattern from the analysis Rmd (lines 1152-1165).

## Usage

``` r
mysterycall_log_histogram(
  data,
  x_col,
  facet_col,
  binwidth = NULL,
  fill = "skyblue",
  color = "black",
  alpha = 0.7,
  x_label = NULL,
  y_label = "Count",
  title = NULL,
  base = 10,
  monochrome = FALSE,
  base_size = 12,
  dpi = 150,
  output_dir = NULL,
  filename = "log_histogram.png"
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

  Numeric or `NULL`. Histogram bin width on the log scale. `NULL`
  (default) lets ggplot2 choose; a fixed `binwidth` can be misleading on
  log scales.

- fill:

  Character. Bar fill colour. Default `"skyblue"`.

- color:

  Character. Bar border colour. Default `"black"`.

- alpha:

  Numeric. Bar transparency \[0, 1\]. Default `0.7`.

- x_label:

  Character or `NULL`. X-axis label. Defaults to
  `paste0("log10(", x_col, ")")`.

- y_label:

  Character. Y-axis label. Default `"Count"`.

- title:

  Character or `NULL`. Plot title. Defaults to
  `paste0("Distribution of log(", x_col, ") by ", facet_col)`.

- base:

  Numeric. Log base. Must be `10` (uses
  [`ggplot2::scale_x_log10()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html))
  or `2` (uses `scale_x_continuous(trans = "log2")`). Default `10`.

- monochrome:

  Logical. If `TRUE`, apply a greyscale fill and
  [`mysterycall_bw_theme()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bw_theme.md)
  for Greene-journal submissions. Overrides `fill`. Default `FALSE`.
  (Rennie 2025.)

- base_size:

  Numeric. Base font size in points. Default `12`. (Rennie 2026.)

- dpi:

  Integer. Resolution for the saved PNG. Default `150`.

- output_dir:

  Character, `NULL`, or `NA`. Directory for PNG output. `NULL` (default)
  writes to a session temp directory via
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).
  `NA` skips writing entirely.

- filename:

  Character. Output file name. Default `"log_histogram.png"`.

## Value

A `ggplot` object, returned invisibly. As a side effect, writes a PNG to
`output_dir` unless `output_dir` is `NA`.

## Note

Axis and theme improvements inspired by Nicola Rennie:
`guide_axis(check.overlap = TRUE)` on the log scale (Rennie 2026),
`plot.title.position = "plot"` (Rennie 2026), `bg = "white"` in `ggsave`
(Rennie 2026), monochrome palette and
[`mysterycall_bw_theme()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bw_theme.md)
(Rennie 2025).

## See also

Other descriptive helpers:
[`mysterycall_demographics_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_demographics_sentence.md),
[`mysterycall_descriptive_stats()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_descriptive_stats.md),
[`mysterycall_distribution_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_distribution_summary.md),
[`mysterycall_facet_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_facet_histogram.md),
[`mysterycall_physicians_with_detail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physicians_with_detail.md),
[`mysterycall_scenario_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md),
[`mysterycall_sensitivity_both_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)

## Examples

``` r
set.seed(2)
df <- data.frame(
  days      = c(rpois(60, 5) + 1L, rpois(60, 10) + 1L),
  insurance = rep(c("Medicaid", "BCBS"), each = 60)
)
mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                           output_dir = NA)
```
