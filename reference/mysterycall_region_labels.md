# Region Labels for a US State Choropleth

Returns one row per US state with its region label and an approximate
centroid, ready to overlay on a state choropleth as a
[`ggplot2::geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html)
layer – e.g. to label each state with its AAO-HNS district. Region
assignments come from
[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md);
centroids use base R
[`datasets::state.center`](https://rdrr.io/r/datasets/state.html), so no
spatial packages are needed.

## Usage

``` r
mysterycall_region_labels(
  system = c("aao_hns", "acog", "census"),
  label = c("region", "abbr")
)
```

## Arguments

- system:

  Region system passed to
  [`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md).
  One of `"aao_hns"` (default), `"acog"`, or `"census"`.

- label:

  Character. Which column is exposed as `label` for convenience:
  `"region"` (default) or `"abbr"` (the two-letter state code).

## Value

A data frame with one row per of the 50 US states and columns `state`,
`abbr`, `region`, `lon`, `lat`, and `label`. Because
[`datasets::state.center`](https://rdrr.io/r/datasets/state.html) covers
only the 50 states, the District of Columbia and territories are not
included; add their label positions manually if your map shows them.

## See also

[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md)

## Examples

``` r
labs <- mysterycall_region_labels(system = "aao_hns")
head(labs)
#>        state abbr     region       lon     lat      label
#> 1    Alabama   AL District 4  -86.7509 32.5901 District 4
#> 2     Alaska   AK District 8 -127.2500 49.2500 District 8
#> 3    Arizona   AZ District 7 -111.6250 34.2192 District 7
#> 4   Arkansas   AR District 6  -92.2992 34.7336 District 6
#> 5 California   CA District 8 -119.7730 36.5341 District 8
#> 6   Colorado   CO District 7 -105.5130 38.6777 District 7

# Overlay on a state choropleth (ggplot2):
if (FALSE) { # \dontrun{
ggplot2::ggplot() +
  ggplot2::geom_sf(data = states_sf, ggplot2::aes(fill = region)) +
  ggplot2::geom_text(
    data = mysterycall_region_labels(),
    ggplot2::aes(x = lon, y = lat, label = label), size = 3
  )
} # }
```
