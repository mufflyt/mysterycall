# Validate Geographic Coordinates

Checks that latitude and longitude are numeric, equal in length, free of
`NaN` and infinite values, and inside the geographic domain (latitude
`[-90, 90]`, longitude `[-180, 180]`).

## Usage

``` r
validate_coordinates(
  lat,
  lon,
  lat_name = "lats",
  lon_name = "lons",
  allow_missing = TRUE
)
```

## Arguments

- lat:

  Numeric vector of latitudes in decimal degrees (WGS84).

- lon:

  Numeric vector of longitudes in decimal degrees (WGS84).

- lat_name:

  Character scalar naming the latitude argument in errors.

- lon_name:

  Character scalar naming the longitude argument in errors.

- allow_missing:

  Logical flag. When `FALSE`, `NA` values are rejected.

## Value

`invisible(TRUE)`. Called for the error side effect.

## Details

Out-of-domain values are a hard error rather than a warning because they
do not fail loudly downstream: a latitude of 500 still yields a finite
haversine distance, so an unchecked coordinate produces a
plausible-looking but wrong result. Values inside the domain are *not*
thereby valid provider locations – plausibility of the location itself
(right country, right state) is a separate check this function does not
make, and no coordinate pair is ever silently reordered.

Missing (`NA`) values are permitted by default and must be handled
explicitly by the caller.

## See also

Other validation:
[`.audit_volatile_fields`](https://mufflyt.github.io/mysterycall/reference/dot-audit_volatile_fields.md),
[`.load_nanp_lookup()`](https://mufflyt.github.io/mysterycall/reference/dot-load_nanp_lookup.md),
[`.mc_check_coord_axis()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_coord_axis.md),
[`.mc_conv_warning_pattern()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_conv_warning_pattern.md),
[`assert_model_cohort()`](https://mufflyt.github.io/mysterycall/reference/assert_model_cohort.md),
[`summarise_fit_warnings()`](https://mufflyt.github.io/mysterycall/reference/summarise_fit_warnings.md),
[`validate_dataframe()`](https://mufflyt.github.io/mysterycall/reference/validate_dataframe.md),
[`validate_log_offset()`](https://mufflyt.github.io/mysterycall/reference/validate_log_offset.md),
[`validate_outcome_finite()`](https://mufflyt.github.io/mysterycall/reference/validate_outcome_finite.md),
[`validate_required_columns()`](https://mufflyt.github.io/mysterycall/reference/validate_required_columns.md),
[`validate_scalar_positive_numeric()`](https://mufflyt.github.io/mysterycall/reference/validate_scalar_positive_numeric.md),
[`warn_non_integer_counts()`](https://mufflyt.github.io/mysterycall/reference/warn_non_integer_counts.md)
