# ACOG Past Presidents

This dataset contains historical records of American College of
Obstetricians and Gynecologists (ACOG) past presidents.

## Format

A data frame with past presidents information:

- first:

  First name of the president.

- last:

  Last name of the president.

- middle:

  Middle name or initial.

- President:

  Full name as originally formatted.

- honorrific:

  Honorific titles (e.g., MD, FACOG).

- Presidency:

  Year their presidency began.

## Source

Scraped from the official ACOG website:
<https://www.acog.org/about/leadership-and-governance/board-of-directors/past-presidents>

## See also

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md),
[`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md),
[`kff_hhi`](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md),
[`medicaid_expansion`](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md),
[`medicaid_fee_index`](https://mufflyt.github.io/mysterycall/reference/medicaid_fee_index.md),
[`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md),
[`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md)

## Examples

``` r
data(acog_presidents)
head(acog_presidents)
#> # A tibble: 6 × 6
#>   first   last     middle President          honorrific Presidency
#>   <chr>   <chr>    <chr>  <chr>              <chr>           <dbl>
#> 1 J       Tucker   Martin J. Martin Tucker   MD               2021
#> 2 Eva     Chalas   NA     Eva Chalas         MD               2020
#> 3 Ted     Anderson L      Ted L. Anderson    MD               2019
#> 4 Lisa    Hollier  M      Lisa M. Hollier    MD               2018
#> 5 Haywood Brown    L      Haywood L. Brown   MD               2017
#> 6 Thomas  Gellhaus M      Thomas M. Gellhaus MD               2016
```
