# Census geocoder benchmark and vintage used package-wide

Pinned deliberately. `"Current_Current"` would track whatever the Census
Bureau currently serves, so a Bureau-side vintage roll would silently
change the geography behind every result while the bundled ZCTA-keyed
datasets
([`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md),
[`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md),
[`zcta_tract_xwalk`](https://mufflyt.github.io/mysterycall/reference/zcta_tract_xwalk.md))
stayed on 2020 boundaries. Pinning keeps geocoded keys and bundled data
on the same vintage. Change these two constants together, and only
alongside regenerated 2030-vintage datasets.

## Usage

``` r
.MC_CENSUS_BENCHMARK

.MC_CENSUS_VINTAGE
```

## Format

Character scalars.

An object of class `character` of length 1.

## See also

Other data integrity:
[`.mc_age_impute()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_impute.md),
[`.mc_age_key()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_key.md),
[`.mc_check_acs_vintage()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_acs_vintage.md),
[`.mc_data()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_data.md),
[`.mc_geo_layer()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geo_layer.md),
[`.mc_geocode_point()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_point.md),
[`.mc_healthgrades_ages()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_healthgrades_ages.md),
[`.mc_state_to_abbr()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_state_to_abbr.md),
[`mysterycall_assign_area_covariates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_area_covariates.md),
[`mysterycall_categorize_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_categorize_wait.md),
[`mysterycall_clean_zip()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_zip.md),
[`mysterycall_flag_near_duplicate_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_near_duplicate_keys.md),
[`mysterycall_link_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_link_physicians.md),
[`mysterycall_lookup_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lookup_age.md),
[`mysterycall_parse_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_duration.md)
