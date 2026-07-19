# Truncate values to fixed bounds

Hard floor/ceiling clipping for visualization. Unlike
[`mysterycall_winsorize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_winsorize.md),
which uses data-driven quantiles, this forces exact bounds for clean
legend breaks (e.g., 0-100% for coverage maps). Use when the legend must
show round numbers regardless of the data range.

## Usage

``` r
mysterycall_truncate_for_viz(x, floor = 0, ceiling = 100)
```

## Arguments

- x:

  Numeric vector.

- floor:

  Numeric. Minimum value (default 0).

- ceiling:

  Numeric. Maximum value (default 100).

## Value

Numeric vector clipped to `[floor, ceiling]`.

## See also

[`mysterycall_winsorize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_winsorize.md)

Other green-journal-spatial:
[`mysterycall_compose_map_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compose_map_density.md),
[`mysterycall_crs_albers_conus()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_crs_albers_conus.md),
[`mysterycall_winsorize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_winsorize.md)

## Examples

``` r
mysterycall:::mysterycall_truncate_for_viz(c(-5, 0, 50, 105), floor = 0, ceiling = 100)
#> [1]   0   0  50 100
```
