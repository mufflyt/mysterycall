# Get ACS Female Population (Ages 18-90) by Census Tract

Downloads ACS B01001 (Sex by Age) data for women aged 18-89 years.
Automatically sums across age groups and propagates margins of error
using the Census Bureau sum-of-squares formula: \\MOE\_{sum} =
\sqrt{\sum MOE_i^2}\\.

## Usage

``` r
mysterycall_get_acs_women_18_90(year = 2022, states = NULL, verbose = TRUE)
```

## Arguments

- year:

  Integer. ACS 5-year survey year (2009-2023). Default: `2022`.

- states:

  Character vector of two-letter state abbreviations, or `NULL` to
  download all states (slow, ~30 min). Default: `NULL`.

- verbose:

  Logical. Print progress messages. Default: `TRUE`.

## Value

Tibble with columns:

- GEOID:

  Census tract ID (11-digit string).

- women_18_90:

  Sum of female population aged 18-89.

- women_18_90_moe:

  Margin of error (90% CI, propagated via sum-of-squares).

## Details

Age groups included: 18-19, 20, 21, 22-24, 25-29, 30-34, 35-39, 40-44,
45-49, 50-54, 55-59, 60-61, 62-64, 65-66, 67-69, 70-74, 75-79, 80-84,
85-89.

## Note

MOE propagation follows Census Bureau ACS Handbook Appendix 3. All MOE
values are at 90% confidence level (Census standard). For both sexes in
one call, use
[`mysterycall_get_acs_adults_18_90`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_adults_18_90.md).

## See also

Other census:
[`mysterycall_add_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_hhi.md),
[`mysterycall_add_medicaid_expansion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_medicaid_expansion.md),
[`mysterycall_get_acs_adults_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_adults_18_90.md),
[`mysterycall_get_acs_female_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_female_insurance.md),
[`mysterycall_get_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_census_data.md),
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
co_women <- mysterycall_get_acs_women_18_90(year = 2022, states = "CO")
west_coast <- mysterycall_get_acs_women_18_90(year = 2022, states = c("CA", "OR", "WA"))
}
```
