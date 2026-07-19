# Physician Location and Specialty Data

This dataset contains a sample of physicians with their National
Provider Identifier (NPI), name, subspecialty, and geographic
coordinates.

## Format

A data frame with 4659 observations and 5 variables:

- NPI:

  National Provider Identifier (numeric).

- name:

  Full name of the physician.

- subspecialty:

  Physician's subspecialty.

- lat:

  Latitude coordinate of the physician's location.

- long:

  Longitude coordinate of the physician's location.

## See also

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md),
[`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md),
[`kff_hhi`](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md),
[`medicaid_expansion`](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md),
[`medicaid_fee_index`](https://mufflyt.github.io/mysterycall/reference/medicaid_fee_index.md),
[`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md)

## Examples

``` r
data(physicians)
head(physicians)
#> # A tibble: 6 × 5
#>          NPI name            subspecialty                             lat   long
#>        <dbl> <chr>           <chr>                                  <dbl>  <dbl>
#> 1 1922051358 Katherine Boyd  Female Pelvic Medicine and Reconstruc…  42.6  -82.9
#> 2 1750344388 Thomas Byrne    Maternal-Fetal Medicine                 35.2 -102. 
#> 3 1548520133 Bobby Garcia    Female Pelvic Medicine and Reconstruc…  40.8  -73.9
#> 4 1770674004 Peter McGovern  Reproductive Endocrinology and Infert…  40.9  -73.9
#> 5 1760408512 John Koulos     Gynecologic Oncology                    40.8  -73.9
#> 6 1508976226 Mostafa Abuzeid Reproductive Endocrinology and Infert…  43.0  -83.7
```
