# Albers Equal-Area CRS for the continental United States

Returns EPSG:5070 (NAD83 / Conus Albers), the standard equal-area
projection used by USGS and the US Census Bureau. Use with
`coord_sf(crs = mysterycall_crs_albers_conus())` to avoid the area
distortion of the default plate carree projection on national
choropleths.

## Usage

``` r
mysterycall_crs_albers_conus()
```

## Value

An [`sf::st_crs`](https://r-spatial.github.io/sf/reference/st_crs.html)
object (EPSG:5070).

## See also

[`mysterycall_theme_green_journal_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_map.md)

Other green-journal-spatial:
[`mysterycall_compose_map_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compose_map_density.md),
[`mysterycall_truncate_for_viz()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_truncate_for_viz.md),
[`mysterycall_winsorize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_winsorize.md)

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
