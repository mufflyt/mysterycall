# Warn when an ACS year predates the boundary vintage of the bundled datasets

The 2020 Census redrew tracts, block groups, and ZCTAs. ACS releases
moved onto those boundaries over the 2021–2022 vintages, and the exact
switch differs by geography. The datasets bundled here
([`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md),
[`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md),
[`zcta_tract_xwalk`](https://mufflyt.github.io/mysterycall/reference/zcta_tract_xwalk.md))
are built on the 2018–2022 ACS and are therefore 2020-vintage
throughout.

## Usage

``` r
.mc_check_acs_vintage(year, geography, fn)
```

## Arguments

- year:

  Integer ACS end-year requested.

- geography:

  Character scalar geography passed to tidycensus.

- fn:

  Character scalar naming the calling function, for the message.

## Value

Invisibly `NULL`; called for the side effect.

## Details

Pulling an earlier ACS year at a boundary-sensitive geography and
joining the result to those datasets – or to geocoded keys, which are
also 2020-vintage – mismatches wherever a tract or ZCTA was split,
merged, or renumbered. The join does not error; it silently drops to
`NA`. This warns instead.

Silence with `options(mysterycall.quiet_vintage = TRUE)` when the
mismatch is intended (for example, a deliberately historical series).

## See also

Other data integrity:
[`.mc_age_impute()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_impute.md),
[`.mc_age_key()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_key.md),
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
