# Medicaid Expansion Status by State

Adoption status of the Affordable Care Act (ACA) Medicaid expansion for
all 50 US states and the District of Columbia, including the date each
state expanded and edge-case notes for Wisconsin and Georgia.

## Format

A data frame with 51 rows (50 states + DC) and 6 columns:

- state:

  Full state name (character).

- state_abb:

  Two-letter USPS abbreviation (character).

- expanded:

  Logical. `TRUE` if the state adopted full ACA Medicaid expansion to
  138 percent FPL.

- expansion_date:

  Date the expansion took effect, or `NA` for non-expansion states.

- status:

  Character. `"Expanded"` or `"Not Expanded"`.

- notes:

  Character. Edge-case clarifications for Wisconsin (BadgerCare waiver,
  100 percent FPL) and Georgia (Pathways partial expansion). `NA` for
  all other states.

## Source

Kaiser Family Foundation (KFF), "Status of State Medicaid Expansion
Decisions: Interactive Map," verified June 2025.
<https://www.kff.org/medicaid/issue-brief/status-of-state-medicaid-expansion-decisions-interactive-map/>

## Details

The ACA permitted states to expand Medicaid eligibility to adults with
incomes up to 138% of the Federal Poverty Level (FPL). Expansion is
voluntary; as of June 2025, 40 states plus DC have adopted full
expansion. Ten states have not: Alabama, Florida, Georgia, Kansas,
Mississippi, South Carolina, Tennessee, Texas, Wisconsin, and Wyoming.

**Wisconsin** covers adults to 100 percent FPL through the BadgerCare
waiver programme but did not adopt the ACA Medicaid expansion to 138
percent FPL; `expanded` is `FALSE`.

**Georgia** launched "Georgia Pathways" in July 2023, a partial
work-requirement expansion programme, but did not adopt the full ACA
expansion; `expanded` is `FALSE`.

## See also

[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md)
for ACOG regional groupings that can be combined with expansion status
for subgroup analyses.

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md),
[`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md),
[`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md),
[`healthgrades_ages`](https://mufflyt.github.io/mysterycall/reference/healthgrades_ages.md),
[`kff_hhi`](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md),
[`medicaid_fee_index`](https://mufflyt.github.io/mysterycall/reference/medicaid_fee_index.md),
[`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md),
[`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md),
[`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md),
[`zcta_tract_xwalk`](https://mufflyt.github.io/mysterycall/reference/zcta_tract_xwalk.md)

## Examples

``` r
data(medicaid_expansion)

# Count expansion vs. non-expansion states
table(medicaid_expansion$status)
#> 
#>     Expanded Not Expanded 
#>           41           10 

# List non-expansion states
medicaid_expansion[!medicaid_expansion$expanded, c("state", "state_abb")]
#>             state state_abb
#> 1         Alabama        AL
#> 10        Florida        FL
#> 11        Georgia        GA
#> 17         Kansas        KS
#> 25    Mississippi        MS
#> 41 South Carolina        SC
#> 43      Tennessee        TN
#> 44          Texas        TX
#> 50      Wisconsin        WI
#> 51        Wyoming        WY

# Merge with study data by state abbreviation
# study_data <- merge(study_data, medicaid_expansion[, c("state_abb", "expanded", "status")],
#                     by = "state_abb", all.x = TRUE)
```
