# Look up latitude/longitude for city + state

A lightweight geocoder for the common case where a provider roster
carries a city and a two-letter state but no coordinates. It joins
against the package's bundled `city_state_to_lat_long` table (roughly
32,000 US places), so it needs no network and no API key – enough to
seed a distance caliper for matched sampling or to QC how far apart
matched practices sit. For rooftop-accurate geocoding of full street
addresses, use a dedicated geocoding service instead.

## Usage

``` r
mysterycall_geocode_city_state(city, state, overrides = NULL)
```

## Arguments

- city:

  Character vector of city names (case/space-insensitive).

- state:

  Character vector of two-letter state abbreviations, the same length as
  `city`.

- overrides:

  Optional data frame of manual coordinates for places the bundled table
  misses (townships, renamed municipalities). Must have columns `city`,
  `state`, `lat`, `lon`; matched case-insensitively and applied on top
  of the table lookup.

## Value

A tibble with columns `city`, `state` (both upper-cased/trimmed), `lat`,
`lon`. Unmatched rows get `NA` coordinates.

## Examples

``` r
mysterycall_geocode_city_state(c("Denver", "Boston"), c("CO", "MA"))
#> # A tibble: 2 × 4
#>   city   state   lat    lon
#>   <chr>  <chr> <dbl>  <dbl>
#> 1 DENVER CO     39.8 -105. 
#> 2 BOSTON MA     42.3  -71.0
```
