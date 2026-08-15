# Extract Female Insurance Shares from ACS Sex-by-Coverage-Type Tables

Computes tract-level female health-insurance shares from the ACS 5-year
detailed coverage tables that are genuinely split by sex: private
(**B27002**), public (**B27003**), Medicare (**C27006**), Medicaid
(**C27007**), and insured/uninsured (**B27001**). Each share is the
female population with that coverage divided by the female civilian
noninstitutionalized population (the B27001 female universe,
`B27001_030`).

## Usage

``` r
mysterycall_get_acs_female_insurance(
  api_key,
  state_fips,
  county_fips,
  year = 2022
)
```

## Arguments

- api_key:

  Character. US Census API key (passed to
  [`tidycensus::get_acs()`](https://walker-data.com/tidycensus/reference/get_acs.html)).

- state_fips:

  Character. Two-digit State FIPS code.

- county_fips:

  Character. Three-digit County FIPS code.

- year:

  Integer. ACS 5-year survey end-year. Default `2022`.

## Value

A data frame with one row per Census tract: geography identifiers, the
female population denominator (`Total_Females`), the female counts with
each coverage type (`N_Female_*`) with propagated MOEs (`*_moe`), and
the corresponding shares of the female population (`Pct_Female_*`,
0-100).

## Details

Coverage-type leaves are selected by matching the "With ..." label text
inside the *Female* branch of each table, so the function self-corrects
across ACS vintages instead of depending on hard-coded cell numbers.
This replaces an earlier implementation that mislabelled ACS Subject
table **S2701** cells: S2701 has no coverage-type breakdown and its
`_010` row is the "75 years and older" age band for both sexes, so the
old private/public/Medicaid/Medicare columns did not measure what their
names claimed.

Because a person may hold more than one coverage type (e.g. dual
Medicare + Medicaid), the Private/Public/Medicaid/Medicare shares
**overlap** and do not sum to 100; only insured + uninsured partition
the population. Margins of error are propagated with the Census
sum-of-squares rule, \\MOE\_{sum} = \sqrt{\sum MOE_i^2}\\ (90\\

## See also

[`mysterycall_get_payer_mix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_payer_mix.md)
for the all-persons, multi-geography generalisation of this builder.

Other census:
[`mysterycall_add_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_hhi.md),
[`mysterycall_add_medicaid_expansion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_medicaid_expansion.md),
[`mysterycall_census_female_population()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_census_female_population.md),
[`mysterycall_get_acs_adults_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_adults_18_90.md),
[`mysterycall_get_acs_women_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_women_18_90.md),
[`mysterycall_get_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_census_data.md),
[`mysterycall_get_county_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_county_provider_counts.md),
[`mysterycall_get_payer_mix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_payer_mix.md),
[`mysterycall_plot_census_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_census_age.md),
[`mysterycall_read_kff_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_kff_hhi.md),
[`mysterycall_summarize_census()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_census.md),
[`mysterycall_summarize_county_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_county_enrollment.md),
[`print.mysterycall_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_provider_counts.md)
