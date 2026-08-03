# HTTP POST seam for geocoding (single mock point)

HTTP POST seam for geocoding (single mock point)

## Usage

``` r
.mc_geocode_http_post(
  url,
  body = NULL,
  encode = "multipart",
  timeout = 120,
  user_agent = "mysterycall-geocoder"
)
```

## Arguments

- url, body, encode, timeout, user_agent:

  Request parameters.

## Value

httr response object.

## See also

Other npi:
[`.mc_build_census_batch_request()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_build_census_batch_request.md),
[`.mc_census_batch()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_census_batch.md),
[`.mc_geocode_http_get()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_http_get.md),
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
