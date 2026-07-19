# State-level FIPS codes

This dataset maps U.S. states (plus the District of Columbia) to their
Federal Information Processing Standards (FIPS) state codes, which are
essential for merging state-level spatial and census data in healthcare
access research. The object is **state-level only**; it does not contain
county rows, so county-level merges are not supported by this object.

## Format

A data frame with 51 rows (50 states plus the District of Columbia) and
3 variables:

- state:

  Two-letter postal abbreviation (e.g. `"AL"`).

- state_code:

  Two-digit state FIPS code, stored as character so leading zeros are
  preserved (e.g. `"01"`).

- state_name:

  Full state name (e.g. `"Alabama"`).

## Source

<https://github.com/kjhealy/fips-codes/blob/master/state_and_county_fips_master.csv>

## See also

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md),
[`kff_hhi`](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md),
[`medicaid_expansion`](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md),
[`medicaid_fee_index`](https://mufflyt.github.io/mysterycall/reference/medicaid_fee_index.md),
[`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md),
[`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md)

## Examples

``` r
data(fips)
head(fips)
#>     state state_code state_name
#> 1      AL         01    Alabama
#> 68     AK         02     Alaska
#> 97     AZ         04    Arizona
#> 112    AR         05   Arkansas
#> 187    CA         06 California
#> 245    CO         08   Colorado
```
