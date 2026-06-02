# Colorblind-safe publication palette (Okabe-Ito)

Returns the Okabe-Ito / Wong palette safe for deuteranopia, protanopia,
and tritanopia, and distinguishable in grayscale. Required by Green
Journal author guidelines.

## Usage

``` r
mysterycall_palette_green_journal(
  n = NULL,
  type = c("qualitative", "sequential", "diverging")
)

mysterycall_palette_publication(
  n = NULL,
  type = c("qualitative", "sequential", "diverging")
)
```

## Arguments

- n:

  Integer. Number of colors (max 8 for qualitative). `NULL` returns
  all 8. Warns if `n > 8` and recycles.

- type:

  Character. One of `"qualitative"` (default, Okabe-Ito), `"sequential"`
  (blue ramp), or `"diverging"` (blue-orange).

## Value

Character vector of hex color codes.

## References

Wong B (2011). Color blindness. *Nature Methods*, 8(6), 441.
[doi:10.1038/nmeth.1618](https://doi.org/10.1038/nmeth.1618)

## See also

[`mysterycall_scale_color_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scale_color_green_journal.md),
[`mysterycall_scale_fill_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scale_fill_green_journal.md)

Other green-journal-colors:
[`mysterycall_scale_color_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scale_color_green_journal.md),
[`mysterycall_scale_fill_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scale_fill_green_journal.md)

## Examples

``` r
mysterycall:::mysterycall_palette_green_journal(5)
#> [1] "#E69F00" "#56B4E9" "#009E73" "#F0E442" "#0072B2"
mysterycall:::mysterycall_palette_green_journal(10, type = "sequential")
#>  [1] "#DEEBF7" "#C6D9EC" "#AEC8E2" "#96B7D8" "#7EA6CE" "#6795C4" "#4F84BA"
#>  [8] "#3773B0" "#1F62A6" "#08519C"
```
