# KFF Medicaid-to-Medicare Fee Index (All Services), 2024

State-level Kaiser Family Foundation (KFF) Medicaid-to-Medicare Fee
Index for 2024 (All Services) covering all 50 states plus the District
of Columbia. The index is the ratio of what a state's Medicaid program
pays to what Medicare pays for the same set of services: a value below 1
means Medicaid reimburses below Medicare, and above 1 means it
reimburses more. Because low Medicaid reimbursement is a leading reason
clinicians decline Medicaid patients, this index is a natural
state-level covariate for insurance-based access disparities in
mystery-caller studies.

## Format

A data frame with 51 rows (50 states + DC) and 5 columns:

- state:

  Character. Full state (or DC) name.

- state_abb:

  Character. Two-letter USPS abbreviation.

- fee_index:

  Numeric. 2024 All-Services Medicaid-to-Medicare fee index. `NA` for
  Tennessee, which has no comprehensive fee-for-service Medicaid fee
  schedule to index.

- year:

  Integer. Vintage of the estimate (2024).

- at_or_above_medicare:

  Logical. `TRUE` when `fee_index >= 1` (Medicaid pays at least as much
  as Medicare); `NA` for Tennessee.

The national All-Services average (0.75) is stored on the object as
`attr(medicaid_fee_index, "national_average")`.

## Source

Kaiser Family Foundation, "Medicaid-to-Medicare Fee Index" (All
Services), 2024.
<https://www.kff.org/medicaid/state-indicator/medicaid-to-medicare-fee-index/>

## Details

This is a newer, complete single-vintage source (2024, all 51
jurisdictions) that supersedes the partial hard-coded values inside
[`mysterycall_medicaid_fee_index()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_medicaid_fee_index.md).

## See also

[`mysterycall_medicaid_fee_index()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_medicaid_fee_index.md)
for the lookup-function form;
[medicaid_expansion](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md)
and
[kff_hhi](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md)
for other state/market policy covariates.

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md),
[`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md),
[`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md),
[`healthgrades_ages`](https://mufflyt.github.io/mysterycall/reference/healthgrades_ages.md),
[`kff_hhi`](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md),
[`medicaid_expansion`](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md),
[`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md),
[`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md),
[`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md),
[`zcta_tract_xwalk`](https://mufflyt.github.io/mysterycall/reference/zcta_tract_xwalk.md)

## Examples

``` r
data(medicaid_fee_index)

# States reimbursing at or above Medicare
medicaid_fee_index[which(medicaid_fee_index$at_or_above_medicare),
                   c("state", "fee_index")]
#> # A tibble: 6 × 2
#>   state        fee_index
#>   <chr>            <dbl>
#> 1 Alaska            1.3 
#> 2 Montana           1.32
#> 3 Nebraska          1.01
#> 4 New Mexico        1.21
#> 5 North Dakota      1.06
#> 6 Wyoming           1   

# Merge onto study data by state abbreviation
# study <- merge(study, medicaid_fee_index[, c("state_abb", "fee_index")],
#                by = "state_abb", all.x = TRUE)

attr(medicaid_fee_index, "national_average")
#> [1] 0.75
```
