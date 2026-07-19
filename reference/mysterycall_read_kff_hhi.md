# Read the KFF per-MSA HHI dataset and crosswalk it to CBSA

Loads KFF's published metropolitan-area HHI table and attaches a
Core-Based Statistical Area (CBSA) GEOID so the values can be joined
onto office data by market. MSA names are matched to CBSAs on a
`first-city|STATE` key that is robust to CBSA-name vintage differences.

## Usage

``` r
mysterycall_read_kff_hhi(
  path,
  sheet = "appendix",
  msa_col = "MSA",
  hhi_col = "HHI in 2024",
  crosswalk = NULL,
  year = 2021
)
```

## Arguments

- path:

  Path to the KFF HHI spreadsheet (`.xlsx`).

- sheet:

  Worksheet name or index. Default `"appendix"`.

- msa_col:

  Character. Column holding the MSA name. Default `"MSA"`.

- hhi_col:

  Character. Column holding the HHI value. Default `"HHI in 2024"`.

- crosswalk:

  Optional data frame with columns `cbsa` (GEOID) and either `msa`
  (name, matched on the city\|state key) or a pre-built `key`. Supply
  this to avoid the `tigris` dependency. When `NULL` (default), CBSA
  GEOIDs are pulled from
  [`tigris::core_based_statistical_areas()`](https://rdrr.io/pkg/tigris/man/core_based_statistical_areas.html)
  (year `year`).

- year:

  Integer CBSA vintage used when `crosswalk` is `NULL`. Default `2021`.

## Value

A tibble with columns `cbsa` (GEOID), `msa` (KFF name), and `hhi`
(numeric HHI). One row per matched CBSA.

## See also

[`mysterycall_add_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_hhi.md)
to join the result onto office data.

Other census:
[`mysterycall_add_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_hhi.md),
[`mysterycall_add_medicaid_expansion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_medicaid_expansion.md),
[`mysterycall_get_acs_adults_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_adults_18_90.md),
[`mysterycall_get_acs_female_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_female_insurance.md),
[`mysterycall_get_acs_women_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_women_18_90.md),
[`mysterycall_get_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_census_data.md),
[`mysterycall_get_county_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_county_provider_counts.md),
[`mysterycall_get_payer_mix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_payer_mix.md),
[`mysterycall_plot_census_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_census_age.md),
[`mysterycall_summarize_census()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_census.md),
[`mysterycall_summarize_county_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_county_enrollment.md),
[`print.mysterycall_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_provider_counts.md)

## Examples

``` r
if (FALSE) { # interactive()
kff <- mysterycall_read_kff_hhi("KFF HHI Dataset.xlsx")
head(kff)
}
```
