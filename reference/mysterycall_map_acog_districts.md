# Create `sf` Polygons for ACOG Districts

This helper reads the packaged ACOG district lookup table and joins it
with state geometries from Natural Earth to construct polygons for each
district. The resulting object can be used to add district boundaries to
Leaflet maps or for further spatial analysis.

## Usage

``` r
mysterycall_map_acog_districts(acog_districts_file = NULL)
```

## Arguments

- acog_districts_file:

  Optional path to a CSV containing the mapping of states to ACOG
  districts. Defaults to the packaged `inst/extdata/acog_districts.csv`.

## Value

An `sf` object with one row per ACOG district and columns:

- `ACOG_District`:

  Character. ACOG district identifier (e.g. `"District I"`).

- `Subregion`:

  Character. Regional grouping of states.

- `States`:

  Character. Comma-separated state names in the district.

- `State_Abbreviations`:

  Character. Comma-separated 2-letter postal codes.

- `geometry`:

  sfc_MULTIPOLYGON. District boundaries in EPSG:4326.

## See also

Other mapping:
[`mysterycall_clear_isochrone_cache()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clear_isochrone_cache.md),
[`mysterycall_create_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_isochrones.md),
[`mysterycall_hrr_maps()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hrr_maps.md),
[`mysterycall_isochrones_for_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_isochrones_for_df.md),
[`mysterycall_map_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_acceptance_rate.md),
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
if (FALSE) { # interactive()
mysterycall_map_acog_districts()
mysterycall_map_acog_districts("inst/extdata/acog_districts.csv")
}
```
