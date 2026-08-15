# Join ACA Medicaid-expansion status onto study data (optionally as of the call date)

Left-joins the packaged
[medicaid_expansion](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md)
crosswalk onto a caller/office data frame by state, adding each state's
ACA Medicaid-expansion status. The state column may hold either full
state names (e.g. `"Texas"`) or two-letter USPS abbreviations (e.g.
`"TX"`); the format is auto-detected.

## Usage

``` r
mysterycall_add_medicaid_expansion(
  data,
  state_col = "state",
  date_col = NULL,
  prefix = ""
)
```

## Arguments

- data:

  A data frame with one row per call/office.

- state_col:

  Character scalar. Name of the column in `data` holding the state (full
  name or two-letter abbreviation). Default `"state"`.

- date_col:

  Character scalar or `NULL`. Name of a `Date` (or date-coercible)
  column holding the call date. When supplied, the as-of-date
  `expanded_at_date` flag is added. Default `NULL`.

- prefix:

  Character scalar prepended to the added column names to avoid
  collisions. Default `""` (no prefix).

## Value

`data` with these columns added (each optionally prefixed):

- `expanded`:

  Logical. Current ACA full-expansion status of the state.

- `expansion_date`:

  Date the expansion took effect (`NA` for non-expansion states).

- `expansion_status`:

  Character `"Expanded"` / `"Not Expanded"`.

- `expanded_at_date`:

  Logical, **only when `date_col` is supplied**. `TRUE` iff the state
  had expanded *and* `expansion_date <= date_col` for that row. `NA`
  when the date is missing or the state did not match.

Rows whose state does not match the crosswalk (e.g. territories, typos)
receive `NA` in every added column and trigger a warning.

## Details

When a date column is supplied via `date_col`, the function additionally
computes a **per-row, as-of-the-call-date** expansion flag
(`expanded_at_date`). This matters for states that adopted expansion
*during* a study window: North Carolina implemented on 2023-12-01 and
South Dakota on 2023-07-01, so calls placed to those states earlier in
2023 were made while the state had **not yet** expanded and are
correctly classified as non-expansion at the call date. The static
`expanded` column (current status) would misclassify them. This logic is
ported from the `consolidation` study's `R/18_medicaid_expansion.R`.

US territories (Puerto Rico, Guam, U.S. Virgin Islands, American Samoa,
Northern Mariana Islands) sit outside the ACA state-expansion decision —
they receive capped Medicaid block grants rather than the state
expansion choice — so they never match the crosswalk and their added
columns are `NA` (a warning lists them).

## See also

[medicaid_expansion](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md)
for the underlying dataset;
[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md)
for ACOG-district groupings that pair well with expansion status in
subgroup analyses.

Other census:
[`mysterycall_add_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_hhi.md),
[`mysterycall_census_female_population()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_census_female_population.md),
[`mysterycall_get_acs_adults_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_adults_18_90.md),
[`mysterycall_get_acs_female_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_female_insurance.md),
[`mysterycall_get_acs_women_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_women_18_90.md),
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
calls <- data.frame(
  office    = c("A", "B", "C", "D"),
  state     = c("TX", "North Carolina", "CA", "SD"),
  call_date = as.Date(c("2023-05-01", "2023-05-01",
                        "2023-05-01", "2023-09-01")),
  stringsAsFactors = FALSE
)

# Current (static) expansion status only
mysterycall_add_medicaid_expansion(calls)
#>   office          state  call_date expanded expansion_date expansion_status
#> 1      A             TX 2023-05-01    FALSE           <NA>     Not Expanded
#> 2      B North Carolina 2023-05-01     TRUE     2023-12-01         Expanded
#> 3      C             CA 2023-05-01     TRUE     2014-01-01         Expanded
#> 4      D             SD 2023-09-01     TRUE     2023-07-01         Expanded

# As-of-call-date status: NC on 2023-05-01 had NOT yet expanded (impl.
# 2023-12-01); SD on 2023-09-01 HAD (impl. 2023-07-01).
mysterycall_add_medicaid_expansion(calls, date_col = "call_date")
#>   office          state  call_date expanded expansion_date expansion_status
#> 1      A             TX 2023-05-01    FALSE           <NA>     Not Expanded
#> 2      B North Carolina 2023-05-01     TRUE     2023-12-01         Expanded
#> 3      C             CA 2023-05-01     TRUE     2014-01-01         Expanded
#> 4      D             SD 2023-09-01     TRUE     2023-07-01         Expanded
#>   expanded_at_date
#> 1            FALSE
#> 2            FALSE
#> 3             TRUE
#> 4             TRUE
```
