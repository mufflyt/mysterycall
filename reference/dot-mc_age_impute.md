# Impute a fallback physician age from the reference age distribution

Returns the reference median `age_current` within each supplied state,
falling back to the national median when the state is missing or absent
from the reference. Used by
[`mysterycall_lookup_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lookup_age.md)
to give unmatched physicians a flagged fallback age.

## Usage

``` r
.mc_age_impute(state_abbr, reference)
```

## Arguments

- state_abbr:

  Character vector of two-letter state abbreviations (may be `NA`).

- reference:

  Reference data frame with `state` and `age_current`.

## Value

A list with `age` (numeric vector, same length as `state_abbr`) and
`source` (character vector: `"imputed_state_median"` or
`"imputed_national_median"`).

## See also

Other data integrity:
[`.mc_age_key()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_key.md),
[`.mc_check_acs_vintage()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_acs_vintage.md),
[`.mc_data()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_data.md),
[`.mc_geo_layer()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geo_layer.md),
[`.mc_geocode_point()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_point.md),
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
