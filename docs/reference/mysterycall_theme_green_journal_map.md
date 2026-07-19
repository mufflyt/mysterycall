# Green Journal map theme

Variant of
[`mysterycall_theme_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal.md)
for choropleth maps, isochrone coverage maps, and other spatial figures.
Removes all axis elements, centers the title, and adds a framed legend.
Use with
[`ggplot2::coord_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
and
[`mysterycall_crs_albers_conus()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_crs_albers_conus.md)
for equal-area projection.

## Usage

``` r
mysterycall_theme_green_journal_map(base_size = 10, legend_position = "right")

mysterycall_theme_publication_map(base_size = 10, legend_position = "right")
```

## Arguments

- base_size:

  Numeric. Base font size (default 10).

- legend_position:

  Character. Legend position (default `"right"`; use `"bottom"` for
  narrow single-column maps).

## Value

A
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
object.

## See also

[`mysterycall_crs_albers_conus()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_crs_albers_conus.md),
[`mysterycall_compose_map_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compose_map_density.md)

Other green-journal-themes:
[`mysterycall_theme_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal.md),
[`mysterycall_theme_green_journal_faceted()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_faceted.md)

## Examples

``` r
if (FALSE) { # interactive()
library(ggplot2)
ggplot(counties_sf) +
  geom_sf(aes(fill = rate)) +
  coord_sf(crs = mysterycall_crs_albers_conus()) +
  mysterycall_theme_green_journal_map()
}
```
