# Build a Census batch geocoding request (writes the upload CSV)

Build a Census batch geocoding request (writes the upload CSV)

## Usage

``` r
.mc_build_census_batch_request(
  addresses,
  benchmark = .MC_CENSUS_BENCHMARK,
  vintage = .MC_CENSUS_VINTAGE,
  request_geographies = TRUE
)
```

## Arguments

- addresses:

  Data frame with `address`,`city`,`state`,`zip`.

- benchmark, vintage:

  Census parameters.

- request_geographies:

  Request tract/block geographies (12-col response).

## Value

List with `url`, `temp_file`, `benchmark`, `vintage`.

## See also

Other npi:
[`.mc_census_batch()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_census_batch.md),
[`.mc_geocode_http_get()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_http_get.md),
[`.mc_geocode_http_post()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_http_post.md),
[`.mc_geocode_http_with_retry()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_http_with_retry.md),
[`.mc_geocode_one_fallback()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_one_fallback.md),
[`.mc_normalize_sex()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_normalize_sex.md),
[`.mc_nppes_sex_one()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_nppes_sex_one.md),
[`.mc_parse_census_batch_response()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_parse_census_batch_response.md),
[`mysterycall_enrich_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_enrich_npi.md),
[`mysterycall_geocode_address()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode_address.md),
[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md),
[`mysterycall_nppes_gender()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nppes_gender.md),
[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md),
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
