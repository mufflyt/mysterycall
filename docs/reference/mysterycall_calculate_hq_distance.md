# Calculate Haversine Distance to Platform Headquarters

Computes the geographic distance (in miles) between a clinic's
coordinates and its corresponding private equity platform's regional
headquarters. For control practices, the function uses the headquarters
of the platform to which its matched PE pair belongs.

## Usage

``` r
mysterycall_calculate_hq_distance(lats, lons, platforms, matched_pairs)
```

## Arguments

- lats:

  Numeric vector of clinic latitudes.

- lons:

  Numeric vector of clinic longitudes.

- platforms:

  Character vector of platform/practice names.

- matched_pairs:

  Character vector of matched pair group IDs.

## Value

A numeric vector of distances in miles.
