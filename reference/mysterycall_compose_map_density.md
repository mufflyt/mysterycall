# Composite map + density figure

Arranges a choropleth map above a marginal density/histogram plot in a
7:2 height ratio. Returns a grob suitable for
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
or
[`mysterycall_save_green_journal_figure()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_green_journal_figure.md).

## Usage

``` r
mysterycall_compose_map_density(
  map_plot,
  density_plot,
  map_weight = 7L,
  density_weight = 2L
)
```

## Arguments

- map_plot:

  A `ggplot` object. The choropleth / spatial map (upper panel).

- density_plot:

  A `ggplot` object. The density or histogram (lower panel).

- map_weight:

  Integer. Relative height for the map panel (default 7).

- density_weight:

  Integer. Relative height for the density panel (default 2).

## Value

A `gridExtra` grob (gtable). Pass to `ggsave(plot = result)` or
[`mysterycall_save_green_journal_figure()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_green_journal_figure.md).

## See also

[`mysterycall_save_green_journal_figure()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_green_journal_figure.md),
[`mysterycall_theme_green_journal_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_map.md)

Other green-journal-spatial:
[`mysterycall_crs_albers_conus()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_crs_albers_conus.md),
[`mysterycall_truncate_for_viz()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_truncate_for_viz.md),
[`mysterycall_winsorize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_winsorize.md)

## Examples

``` r
if (FALSE) { # interactive()
library(ggplot2)
p_map <- ggplot(tracts) + geom_sf(aes(fill = access)) +
  mysterycall_theme_green_journal_map()
p_den <- ggplot(tracts, aes(access)) +
  geom_density(fill = "#56B4E9", alpha = 0.6) +
  mysterycall_theme_green_journal()
composite <- mysterycall_compose_map_density(p_map, p_den)
mysterycall_save_green_journal_figure(composite, "figures/fig3")
}
```
