# Data of FIPS codes

This dataset maps state and county names to Federal Information
Processing Standards (FIPS) codes, which are essential for merging
spatial and census data in healthcare access research.

## Format

A tibble with 3142 rows and 10 variables containing Federal Information
Processing Standards (FIPS) codes for states and counties:

- state:

  Two-letter postal abbreviation.

- state_name:

  Full state name.

- state_fips:

  Two-digit state FIPS code.

- county_fips:

  Three-digit county FIPS code.

- fips:

  Combined five-digit state and county code.

- class:

  Geography class indicator.

- county:

  County name.

- county_ansi:

  County ANSI code.

- county_short:

  Simplified county name.

- state_ansi:

  State ANSI code.

## Source

<https://github.com/kjhealy/fips-codes/blob/master/state_and_county_fips_master.csv>

## See also

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md),
[`medicaid_expansion`](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md),
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
