# Physicians Dataset

This dataset contains information about physicians, including their NPI
numbers, names, subspecialties, and geographic coordinates for mapping
and analysis purposes.

## Usage

``` r
physicians
```

## Format

A data frame with 4659 rows and 5 columns:

- NPI:

  National Provider Identifier number.

- name:

  Full name of the physician.

- subspecialty:

  Subspecialty of the physician (e.g., Maternal-Fetal Medicine).

- lat:

  Latitude coordinate of the physician's practice location.

- long:

  Longitude coordinate of the physician's practice location.

## Source

National Provider Identifier (NPI) registry data.

## Value

A tibble of physician records with NPI numbers, names, subspecialties,
and geographic coordinates.

## See also

Other datasets:
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md)

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
