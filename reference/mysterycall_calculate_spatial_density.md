# Calculate Spatial Density of Clinics (Local Concentration Index)

Computes the number of other locations within a specified radius (in
miles) for each coordinate pair in a set of latitudes and longitudes.
Uses the Haversine formula for spherical distance.

## Usage

``` r
mysterycall_calculate_spatial_density(
  lats,
  lons,
  target_lats = NULL,
  target_lons = NULL,
  radius = 15
)
```

## Arguments

- lats:

  Numeric vector of latitudes.

- lons:

  Numeric vector of longitudes.

- target_lats:

  Numeric vector of latitudes for the target group to count (e.g. PE
  clinics). If NULL, defaults to the set of lats.

- target_lons:

  Numeric vector of longitudes for the target group to count. If NULL,
  defaults to the set of lons.

- radius:

  Numeric. The search radius in miles. Default is 15.

## Value

An integer vector containing the count of target locations within the
radius for each input point.

## Examples

``` r
lats <- c(42.59, 25.62, 40.26)
lons <- c(-83.49, -80.32, -74.52)
mysterycall_calculate_spatial_density(lats, lons, radius = 15)
#> [1] 0 0 0
```
