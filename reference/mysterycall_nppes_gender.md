# Physician gender from the NPPES registry

Returns the **registry-reported** sex for each NPI, read straight from
the NPPES `basic_sex` field via the npi package. This is the
authoritative self-/registrant-reported value and is the preferred
gender source for mystery-caller studies – unlike first-name inference
(Genderize.io), it does not guess, has no per-name error, and needs no
external quota.

## Usage

``` r
mysterycall_nppes_gender(npi, verbose = FALSE)
```

## Arguments

- npi:

  Character or numeric vector of 10-digit NPIs.

- verbose:

  Logical; print a one-line coverage summary. Default `FALSE`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per **unique** input NPI:

- npi:

  The NPI, as character.

- gender:

  `"Male"`, `"Female"`, or `NA`.

- gender_source:

  `"NPPES"` when found, else `NA`.

## Details

NPPES covers essentially every US clinician with an NPI, so coverage is
near-complete; a small number of records leave `basic_sex` blank and
return `NA`.

One NPPES query per unique NPI (the npi package has no bulk-by-number
endpoint). Invalid NPIs, lookup failures, and records without a sex code
all yield `NA` gender rather than an error.

## See also

[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md),
which attaches DAC gender and can fall back to this function;
[`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md),
the name-inference approach this is designed to replace.

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
[`mysterycall_geocode_address()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode_address.md),
[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md),
[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md),
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)

## Examples

``` r
if (FALSE) { # interactive()
mysterycall_nppes_gender(c("1710933130", "1033299938"))
}
```
