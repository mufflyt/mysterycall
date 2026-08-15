# Join a market HHI covariate onto office data

Left-joins market HHI values onto caller/office data by a market key
(CBSA) and derives modelling-ready companions: `hhi_k` (HHI / `scale`)
and `hhi_cat` (DOJ/FTC concentration category).

## Usage

``` r
mysterycall_add_hhi(
  data,
  hhi_table,
  market_col = "cbsa",
  table_market_col = "cbsa",
  hhi_col = "hhi",
  scale = 1000,
  prefix = ""
)
```

## Arguments

- data:

  A data frame with one row per call/office and a market-key column.

- hhi_table:

  A data frame of market HHI values, e.g. from
  [`mysterycall_read_kff_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_kff_hhi.md).

- market_col:

  Character. Market-key column in `data`. Default `"cbsa"`.

- table_market_col:

  Character. Market-key column in `hhi_table`. Default `"cbsa"`.

- hhi_col:

  Character. HHI value column in `hhi_table`. Default `"hhi"`.

- scale:

  Numeric divisor for `hhi_k`. Default `1000` (coefficient reads "per
  1000 HHI points").

- prefix:

  Character prepended to added column names. Default `""`.

## Value

`data` with added columns (optionally prefixed): `hhi` (numeric),
`hhi_k` (`hhi / scale`), and `hhi_cat` (ordered factor
`"un-concentrated"` \< `"moderate"` \< `"high"`). Offices whose market
is not in `hhi_table` receive `NA` and trigger a warning listing how
many.

## See also

[`mysterycall_read_kff_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_kff_hhi.md)
for building `hhi_table`.

Other census:
[`mysterycall_add_medicaid_expansion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_medicaid_expansion.md),
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
offices <- data.frame(office = c("A", "B", "C"),
                      cbsa   = c("19740", "12060", "99999"),
                      stringsAsFactors = FALSE)
hhi_tbl <- data.frame(cbsa = c("19740", "12060"),
                      hhi  = c(1450, 2600))
suppressWarnings(mysterycall_add_hhi(offices, hhi_tbl))
#>   office  cbsa  hhi hhi_k  hhi_cat
#> 1      A 19740 1450  1.45 moderate
#> 2      B 12060 2600  2.60     high
#> 3      C 99999   NA    NA     <NA>
```
