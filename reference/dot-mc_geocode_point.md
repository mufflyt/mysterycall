# Reverse-geocode one coordinate to ZCTA / tract / MSA

Calls the US Census Bureau coordinate geocoder at the pinned vintage
(`.MC_CENSUS_VINTAGE`) and extracts the ZCTA, census tract, and
Metropolitan Statistical Area. Returns `NA` keys on any network error,
non-US point, or missing input.

## Usage

``` r
.mc_geocode_point(long, lat)
```

## Arguments

- long, lat:

  Longitude and latitude in decimal degrees.

## Value

A list with character scalars `zcta`, `tract`, `msa`, plus logical `ok`
recording whether the geocoder returned a parseable geography set.
`ok = TRUE` with an `NA` key means the layer was missing or the point
fell outside it – distinguishable from a network failure, which yields
`ok = FALSE`.

## See also

Other data integrity:
[`.mc_age_impute()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_impute.md),
[`.mc_age_key()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_key.md),
[`.mc_check_acs_vintage()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_acs_vintage.md),
[`.mc_data()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_data.md),
[`.mc_geo_layer()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geo_layer.md),
[`.mc_healthgrades_ages()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_healthgrades_ages.md),
[`.mc_state_to_abbr()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_state_to_abbr.md),
[`mc-census-vintage`](https://mufflyt.github.io/mysterycall/reference/mc-census-vintage.md),
[`mysterycall_assign_area_covariates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_area_covariates.md),
[`mysterycall_categorize_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_categorize_wait.md),
[`mysterycall_clean_zip()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_zip.md),
[`mysterycall_flag_near_duplicate_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_near_duplicate_keys.md),
[`mysterycall_link_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_link_physicians.md),
[`mysterycall_lookup_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lookup_age.md),
[`mysterycall_parse_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_duration.md)
