# Assign area-level covariates (ADI, SVI, HHI) from physician coordinates

Attaches neighbourhood and market context to physicians from their
practice latitude/longitude, maximising coverage of the three area-level
covariates used as sensitivity adjustments in mystery-caller access
studies:

- **ADI** – Area Deprivation Index
  ([`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md)),

- **SVI** – Social Vulnerability Index
  ([`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md)),

- **HHI** – hospital-market Herfindahl-Hirschman Index
  ([`kff_hhi`](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md)).

## Usage

``` r
mysterycall_assign_area_covariates(
  data,
  lat_col = "lat",
  long_col = "long",
  which = c("adi", "svi", "hhi"),
  verbose = TRUE
)
```

## Arguments

- data:

  A data frame of physicians with latitude and longitude columns.

- lat_col, long_col:

  Column names holding latitude and longitude in decimal degrees
  (WGS84). Defaults `"lat"` / `"long"`.

- which:

  Character vector naming which covariates to attach; any of `"adi"`,
  `"svi"`, `"hhi"`. Default all three.

- verbose:

  Logical; print a per-covariate coverage summary. Default `TRUE`.

## Value

`data` with geocoded keys (`zcta`, `tract`, `msa`) and the requested
covariate columns appended: `adi`, `svi`, `hhi` (and `hhi_cat`). A
`"coverage"` attribute holds the non-missing count for each covariate.

## Details

Each coordinate is resolved once through the US Census Bureau geocoder
(<https://geocoding.geo.census.gov>; no key required) to its 2020 ZIP
Code Tabulation Area, census tract, and Metropolitan Statistical Area.
ADI and SVI then join on ZCTA – which covers essentially every populated
location, so their coverage is limited only by whether a coordinate is
present and falls in a ZCTA. HHI joins on MSA and therefore remains
**structurally metro-only**: KFF publishes HHI for 387 metropolitan
markets, so physicians outside any MSA (rural/micropolitan) get `NA` HHI
by construction, not by a matching failure.

Geocoding is one network call per unique coordinate (duplicates are
resolved once and reused). Failed or out-of-US coordinates yield `NA`
keys and therefore `NA` covariates.

## See also

[`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md),
[`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md),
[`kff_hhi`](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md).

Other data integrity:
[`.mc_age_impute()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_impute.md),
[`.mc_age_key()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_key.md),
[`.mc_check_acs_vintage()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_acs_vintage.md),
[`.mc_data()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_data.md),
[`.mc_geo_layer()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geo_layer.md),
[`.mc_geocode_point()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_point.md),
[`.mc_healthgrades_ages()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_healthgrades_ages.md),
[`.mc_state_to_abbr()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_state_to_abbr.md),
[`mc-census-vintage`](https://mufflyt.github.io/mysterycall/reference/mc-census-vintage.md),
[`mysterycall_categorize_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_categorize_wait.md),
[`mysterycall_clean_zip()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_zip.md),
[`mysterycall_flag_near_duplicate_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_near_duplicate_keys.md),
[`mysterycall_link_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_link_physicians.md),
[`mysterycall_lookup_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lookup_age.md),
[`mysterycall_parse_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_duration.md)

## Examples

``` r
# \donttest{
df <- data.frame(lat = 39.7392, long = -104.9903)  # Denver
mysterycall_assign_area_covariates(df)
#> ADI coverage: 1/1 (100%)
#> SVI coverage: 1/1 (100%)
#> HHI coverage: 1/1 (100%)
#>       lat      long  zcta       tract                        msa      adi
#> 1 39.7392 -104.9903 80202 08031002000 Denver-Aurora-Lakewood, CO 72.74838
#>      svi      hhi hhi_cat
#> 1 0.5327 2231.737    high
# }
```
