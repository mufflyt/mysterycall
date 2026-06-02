# Function to create and export a map showing block group overlap with isochrones

This function creates a map that displays block groups and their overlap
with isochrones. The map is exported as an HTML file and a PNG image.

## Usage

``` r
mysterycall_map_block_group(bg_data, isochrones_data, output_dir = "figures/")
```

## Arguments

- bg_data:

  A SpatialPolygonsDataFrame representing block group data.

- isochrones_data:

  A SpatialPolygonsDataFrame representing isochrone data.

- output_dir:

  Directory path for exporting the map files. Default is "figures/".

## Value

`invisible(NULL)`. Side effects: writes the block group overlap map as
an HTML file and a PNG image to `output_dir`.

## See also

Other mapping:
[`mysterycall_clear_isochrone_cache()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clear_isochrone_cache.md),
[`mysterycall_create_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_isochrones.md),
[`mysterycall_hrr_maps()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hrr_maps.md),
[`mysterycall_isochrones_for_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_isochrones_for_df.md),
[`mysterycall_map_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_acceptance_rate.md),
[`mysterycall_map_acog_districts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_acog_districts.md),
[`mysterycall_map_base()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_base.md),
[`mysterycall_map_leaflet()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_leaflet.md),
[`mysterycall_map_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_physicians.md),
[`mysterycall_plot_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_density.md),
[`mysterycall_plot_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_isochrones.md),
[`mysterycall_plot_line()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_line.md),
[`mysterycall_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_scatter.md)

## Examples

``` r
if (FALSE) { # interactive()
# Create and export the map with the default output directory
mysterycall_map_block_group(block_groups, isochrones_joined_map)

# Create and export the map with a custom output directory
mysterycall_map_block_group(block_groups, isochrones_joined_map, "custom_output/")
}
```
