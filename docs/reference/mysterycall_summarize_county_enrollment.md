# Summarize county Medicare/Medicaid enrollment and derive access ratio

Collapses a CMS enrollment extract to one row per county with total
Medicare and Medicaid enrollment, then derives the
**Medicaid-to-Medicare ratio** and an ordered access category. The ratio
is a compact marker of how welcoming a local market is to Medicaid
patients relative to Medicare: low ratios flag counties where Medicaid
beneficiaries are comparatively under-served. The category thresholds
match the `isochrones` study's convention.

## Usage

``` r
mysterycall_summarize_county_enrollment(
  data,
  county_col = "fips_county",
  medicare_col = "medicare_enrollment",
  medicaid_col = "medicaid_enrollment",
  dual_col = NULL
)
```

## Arguments

- data:

  A data frame with county FIPS and enrollment columns (one or more rows
  per county; rows are summed within county).

- county_col:

  Character. County FIPS column. Default `"fips_county"`.

- medicare_col:

  Character. Medicare enrollment column. Default
  `"medicare_enrollment"`.

- medicaid_col:

  Character. Medicaid enrollment column. Default
  `"medicaid_enrollment"`.

- dual_col:

  Character or `NULL`. Optional dual-eligible enrollment column, summed
  and returned when supplied. Default `NULL`.

## Value

A tibble with one row per county:

- `fips_county`:

  Zero-padded 5-digit county FIPS.

- `medicare_enrollment`, `medicaid_enrollment`:

  Summed enrollment.

- `dual_enrollment`:

  Summed dual-eligible enrollment (only when `dual_col` supplied).

- `medicaid_to_medicare_ratio`:

  `medicaid / medicare` (`NA` when Medicare enrollment is zero).

- `medicaid_access_category`:

  Ordered factor: `"Low (<0.50)"`, `"Medium (0.50-0.74)"`,
  `"High (0.75-0.99)"`, `"Very High (>=1.00)"`.

Rows with a missing county FIPS emit a warning and are dropped.

## Details

This is the multi-county aggregator/covariate builder; to pull the raw
single-county CMS monthly counts it consumes, see
[`mysterycall_get_cms_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_cms_enrollment.md).
Enrollment counts are CMS **beneficiary** enrollment (people), distinct
from ACS coverage estimates
([`mysterycall_get_payer_mix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_payer_mix.md))
and from provider counts
([`mysterycall_get_county_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_county_provider_counts.md)).

## See also

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
[`mysterycall_read_kff_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_kff_hhi.md),
[`mysterycall_summarize_census()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_census.md),
[`print.mysterycall_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_provider_counts.md)

## Examples

``` r
cms <- data.frame(
  fips_county         = c("08031", "48201", "48201"),
  medicare_enrollment = c(90000, 400000, 10000),
  medicaid_enrollment = c(70000, 600000, 20000),
  stringsAsFactors    = FALSE
)
mysterycall_summarize_county_enrollment(cms)
#> # A tibble: 2 × 5
#>   fips_county medicare_enrollment medicaid_enrollment medicaid_to_medicare_ratio
#>   <chr>                     <dbl>               <dbl>                      <dbl>
#> 1 08031                     90000               70000                      0.778
#> 2 48201                    410000              620000                      1.51 
#> # ℹ 1 more variable: medicaid_access_category <ord>
```
