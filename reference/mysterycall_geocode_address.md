# Geocode full street addresses (US Census batch, with fallbacks)

Geocodes complete practice addresses (street, city, state, ZIP) to
coordinates and 2020 census geography using the US Census Bureau
**batch** geocoder (<https://geocoding.geo.census.gov>; free, no key).
Addresses the Census cannot match optionally fall back to Nominatim
(OpenStreetMap) and then ArcGIS, one address at a time.

## Usage

``` r
mysterycall_geocode_address(
  data,
  street_col = "street",
  city_col = "city",
  state_col = "state",
  zip_col = "zip",
  batch_size = 1000L,
  fallback = TRUE,
  benchmark = .MC_CENSUS_BENCHMARK,
  vintage = .MC_CENSUS_VINTAGE,
  verbose = TRUE
)
```

## Arguments

- data:

  A data frame of addresses.

- street_col, city_col, state_col, zip_col:

  Column names holding the street line, city, state, and ZIP. Defaults
  `"street"`, `"city"`, `"state"`, `"zip"`.

- batch_size:

  Addresses per Census request (1-10000). Default 1000.

- fallback:

  Logical. When `TRUE` (default) unmatched addresses are retried one at
  a time via Nominatim then ArcGIS. Nominatim asks callers to stay under
  ~1 request/second, so this is slow for large unmatched sets.

- benchmark, vintage:

  Census geocoder benchmark and vintage. Default to the package-wide
  pinned pair (`.MC_CENSUS_BENCHMARK` / `.MC_CENSUS_VINTAGE`, currently
  `Public_AR_Current` / `Census2020_Current`), which is what makes the
  documented 2020 GEOIDs a guarantee rather than a coincidence. Passing
  `"Current_Current"` tracks whatever the Bureau serves as current and
  will silently change vintage under you; it also renames geography
  layers, which
  [`mysterycall_assign_area_covariates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_area_covariates.md)
  would then fail to join.

- verbose:

  Logical; print per-batch progress. Default `TRUE`.

## Value

`data` with six columns appended: `geo_lat`, `geo_long`, `geo_match`
(`"Match"`/`"No_Match"`/`"Tie"`), `geo_matched_address`, `geo_tract`
(11-digit 2020 GEOID, Census matches only), and `geo_source`
(`"census"`, `"nominatim"`, `"arcgis"`, or `NA`). Feed
`geo_lat`/`geo_long` to
[`mysterycall_assign_area_covariates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_area_covariates.md)
for ADI/SVI/HHI.

## Details

This is more precise than
[`mysterycall_geocode_city_state()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode_city_state.md),
which resolves only to a city centroid: a street match places the
physician in the correct census tract and ZCTA, which matters for
area-level covariates
([`mysterycall_assign_area_covariates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_area_covariates.md)).
The HTTP request/response machinery is ported from the `isochrones`
project's geocoding seams so it is unit testable without a network (see
the internal `.mc_build_*` / `.mc_parse_*` seams).

## See also

[`mysterycall_geocode_city_state()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode_city_state.md)
for the coarser city-centroid geocoder;
[`mysterycall_assign_area_covariates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_area_covariates.md)
to attach area covariates.

Other npi:
[`.mc_build_census_batch_request()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_build_census_batch_request.md),
[`.mc_census_batch()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_census_batch.md),
[`.mc_geocode_http_get()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_http_get.md),
[`.mc_geocode_http_post()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_http_post.md),
[`.mc_geocode_http_with_retry()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_http_with_retry.md),
[`.mc_geocode_one_fallback()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_one_fallback.md),
[`.mc_normalize_sex()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_normalize_sex.md),
[`.mc_nppes_sex_one()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_nppes_sex_one.md),
[`.mc_parse_census_batch_response()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_parse_census_batch_response.md),
[`mysterycall_enrich_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_enrich_npi.md),
[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md),
[`mysterycall_nppes_gender()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nppes_gender.md),
[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md),
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)

## Examples

``` r
if (FALSE) { # interactive()
addr <- data.frame(street = "12631 E 17th Ave", city = "Aurora",
                   state = "CO", zip = "80045")
mysterycall_geocode_address(addr)
}
```
