# City/state latitude and longitude reference data

Latitude/longitude lookup table assembled from a public GitHub gist for
aligning caller workbooks with geospatial tooling.

## Usage

``` r
city_state_to_lat_long
```

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
