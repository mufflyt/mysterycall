# HTTP request with retry and exponential backoff

HTTP request with retry and exponential backoff

## Usage

``` r
.mc_geocode_http_with_retry(
  request_fn,
  max_attempts = 3,
  initial_delay_ms = 1000,
  max_delay_ms = 30000,
  jitter_factor = 0.25
)
```

## Arguments

- request_fn:

  Function returning an httr response.

- max_attempts, initial_delay_ms, max_delay_ms, jitter_factor:

  Retry params.

## Value

httr response object, or the last error is re-thrown.

## See also

Other npi:
[`.mc_build_census_batch_request()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_build_census_batch_request.md),
[`.mc_census_batch()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_census_batch.md),
[`.mc_geocode_http_get()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_http_get.md),
[`.mc_geocode_http_post()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_http_post.md),
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
