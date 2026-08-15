# Get Census data of all state block groups

This function retrieves Census data of all state block groups by looping
over the specified list of state FIPS codes.

## Usage

``` r
mysterycall_get_census_data(
  us_fips_list,
  vintage = 2022,
  api_key = Sys.getenv("CENSUS_API_KEY")
)
```

## Arguments

- us_fips_list:

  A vector of state FIPS codes which Census data is to be retrieved.

- vintage:

  The vintage year of Census data (default is 2022).

- api_key:

  Census API key to use for requests. Defaults to the `CENSUS_API_KEY`
  environment variable.

## Value

A tibble with one row per Census block group. Columns include:

- `statefp`:

  Character. Zero-padded 2-digit state FIPS code.

- `countyfp`:

  Character. Zero-padded 3-digit county FIPS code.

- `tractce`:

  Character. Zero-padded 6-digit Census tract code.

- `block_group`:

  Character. Single-digit block group identifier.

- `geoid`:

  Character. Full 12-digit block group GEOID
  (`statefp + countyfp + tractce + block_group`).

- `vintage`:

  Integer. The ACS vintage year supplied via `vintage`.

- Population columns:

  Numeric. ACS 5-year estimates for total population and sex-by-age
  detail (`B01001_*E` variables).

Returns an empty tibble when `us_fips_list` is length zero. States whose
API call fails emit a warning and are silently skipped.

## See also

Other census:
[`mysterycall_add_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_hhi.md),
[`mysterycall_add_medicaid_expansion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_medicaid_expansion.md),
[`mysterycall_census_female_population()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_census_female_population.md),
[`mysterycall_get_acs_adults_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_adults_18_90.md),
[`mysterycall_get_acs_female_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_female_insurance.md),
[`mysterycall_get_acs_women_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_women_18_90.md),
[`mysterycall_get_county_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_county_provider_counts.md),
[`mysterycall_get_payer_mix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_payer_mix.md),
[`mysterycall_plot_census_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_census_age.md),
[`mysterycall_read_kff_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_kff_hhi.md),
[`mysterycall_summarize_census()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_census.md),
[`mysterycall_summarize_county_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_county_enrollment.md),
[`print.mysterycall_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_provider_counts.md)

## Examples

``` r
if (FALSE) { # interactive()
us_fips_list <- c("01", "02")
census_df <- mysterycall_get_census_data(us_fips_list)
}
```
