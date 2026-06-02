# Choropleth map of appointment acceptance rates by US state

Draws a choropleth map of appointment acceptance rates using base-R map
data (no external spatial packages required for state-level maps).

## Usage

``` r
mysterycall_map_acceptance_rate(
  data,
  region_col,
  rate_col,
  region_type = c("state", "hrr"),
  palette = "viridis",
  title = "Appointment Acceptance Rate (%)",
  legend_title = "Acceptance\nRate (%)",
  limits = NULL,
  na_color = "grey80",
  save_path = NULL,
  width = 10,
  height = 7,
  dpi = 300L
)
```

## Arguments

- data:

  A data frame with at least two columns: `region_col` and `rate_col`.

- region_col:

  Character scalar. Name of the column that identifies regions. For
  `region_type = "state"` this can be full state names (e.g.
  `"Colorado"`) or standard two-letter abbreviations (e.g. `"CO"`).

- rate_col:

  Character scalar. Name of a numeric column with acceptance rates
  between 0 and 1. Values are multiplied by 100 for display.

- region_type:

  Character scalar. Either `"state"` (default) or `"hrr"`. `"hrr"`
  immediately raises an error with instructions to use the sf-based
  workflow.

- palette:

  Character scalar. Viridis colour-scale option passed to
  [`ggplot2::scale_fill_viridis_c()`](https://ggplot2.tidyverse.org/reference/scale_viridis.html).
  Default `"viridis"`.

- title:

  Character scalar. Plot title. Default
  `"Appointment Acceptance Rate (%)"`.

- legend_title:

  Character scalar. Legend title. Default `"Acceptance\\nRate (%)"`.

- limits:

  Numeric vector of length 2 or `NULL`. Explicit limits for the fill
  scale. `NULL` (default) lets ggplot2 choose.

- na_color:

  Character scalar. Fill colour for states with no data. Default
  `"grey80"`.

- save_path:

  Character scalar or `NULL`. When not `NULL`, the plot is written to
  this path via
  [`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md).

- width:

  Numeric. Width in inches passed to
  [`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md).
  Default `10`.

- height:

  Numeric. Height in inches passed to
  [`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md).
  Default `7`.

- dpi:

  Integer. Resolution passed to
  [`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md).
  Default `300L`.

## Value

A `ggplot` object of class `c("gg", "ggplot")`, returned invisibly. When
`save_path` is not `NULL`, also writes the plot to disk via
[`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md).

## See also

[`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md)
to write the result to disk;
[`mysterycall_hrr_maps()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hrr_maps.md)
for HRR-level choropleth maps.

Other mapping:
[`mysterycall_clear_isochrone_cache()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clear_isochrone_cache.md),
[`mysterycall_create_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_isochrones.md),
[`mysterycall_hrr_maps()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hrr_maps.md),
[`mysterycall_isochrones_for_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_isochrones_for_df.md),
[`mysterycall_map_acog_districts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_acog_districts.md),
[`mysterycall_map_base()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_base.md),
[`mysterycall_map_block_group()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_block_group.md),
[`mysterycall_map_leaflet()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_leaflet.md),
[`mysterycall_map_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_physicians.md),
[`mysterycall_plot_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_density.md),
[`mysterycall_plot_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_isochrones.md),
[`mysterycall_plot_line()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_line.md),
[`mysterycall_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_scatter.md)

## Examples

``` r
set.seed(7)
df <- data.frame(
  state = c("Colorado", "California", "Texas", "New York", "Florida"),
  rate  = c(0.55, 0.72, 0.48, 0.63, 0.81)
)
mysterycall_map_acceptance_rate(df, region_col = "state", rate_col = "rate")
```
