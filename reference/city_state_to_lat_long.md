# City/state latitude and longitude reference data

Latitude/longitude lookup table assembled from a public GitHub gist for
aligning caller workbooks with geospatial tooling.

## Format

A tibble with four variables:

- city:

  City name.

- state:

  Two-letter postal state abbreviation.

- lat:

  Latitude in decimal degrees.

- long:

  Longitude in decimal degrees.

## Source

<https://gist.githubusercontent.com/steinbring/e5417af6d1bb95742555866c84e3f91d/raw/186b532887c9738687860aeae5de7a7b2a0ed233/cityStateToLatLong.csv>

## Value

A tibble mapping U.S. cities and states to their latitude and longitude
coordinates.

## See also

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md),
[`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md),
[`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md)

## Examples

``` r
data(city_state_to_lat_long)
head(city_state_to_lat_long)
#> # A tibble: 6 × 4
#>   state   city       latitude longitude
#>   <chr>   <chr>         <dbl>     <dbl>
#> 1 Alabama Abanda         33.1     -85.5
#> 2 Alabama Abbeville      31.6     -85.3
#> 3 Alabama Adamsville     33.6     -87.0
#> 4 Alabama Addison        34.2     -87.2
#> 5 Alabama Akron          32.9     -87.7
#> 6 Alabama Alabaster      33.2     -86.8
```
