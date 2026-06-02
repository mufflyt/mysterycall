# Calculate drive-time isochrones for a location

Computes drive-time isolines (isochrones) for a given point using the
HERE routing API via the `hereR` package. Results are memoized in memory
for the duration of the R session so repeated calls with the same inputs
are free. Use
[`mysterycall_clear_isochrone_cache()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clear_isochrone_cache.md)
to release memory after a batch.

## Usage

``` r
mysterycall_create_isochrones(
  location,
  range,
  posix_time = as.POSIXct("2023-10-20 08:00:00", format = "%Y-%m-%d %H:%M:%S"),
  api_key = Sys.getenv("HERE_API_KEY")
)
```

## Arguments

- location:

  An `sf` point object representing the origin location.

- range:

  Numeric vector of drive-time thresholds in **seconds** (e.g.
  `c(1800, 3600)` for 30- and 60-minute isochrones).

- posix_time:

  A `POSIXct` scalar giving the departure time used by the routing
  engine. Defaults to `"2023-10-20 08:00:00"` (a weekday morning).

- api_key:

  HERE API key. Defaults to the `HERE_API_KEY` environment variable.
  Obtain a free key at <https://www.here.com/developer>.

## Value

A named `list`. On success: one element per value in `range`, named by
the drive-time threshold in seconds (e.g., `"1800"`), each containing an
`sf` POLYGON object with the isochrone geometry. On API failure: a
`list` with a single `error` element (character scalar) containing the
error message. Detect failures with
`if (!is.null(result$error)) { ... }`.

## See also

[`mysterycall_clear_isochrone_cache()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clear_isochrone_cache.md)
to free session memory after batch processing;
[`mysterycall_geocode()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode.md)
to produce the input coordinates.

Other mapping:
[`mysterycall_clear_isochrone_cache()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clear_isochrone_cache.md),
[`mysterycall_hrr_maps()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hrr_maps.md),
[`mysterycall_isochrones_for_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_isochrones_for_df.md),
[`mysterycall_map_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_acceptance_rate.md),
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
if (FALSE) { # interactive()
location <- sf::st_sfc(sf::st_point(c(-73.987, 40.757)), crs = 4326)
isolines <- mysterycall_create_isochrones(
  location = location,
  range    = c(1800, 3600)
)
mysterycall_clear_isochrone_cache()
}
```
