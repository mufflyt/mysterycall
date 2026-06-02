# ACOG Presidents Data

This dataset contains information about past presidents of the American
College of Obstetricians and Gynecologists (ACOG).

## Usage

``` r
acog_presidents
```

## Format

A data frame with 71 rows and 6 columns:

- first:

  First name of the ACOG president.

- last:

  Last name of the ACOG president.

- middle:

  Middle name or initial of the ACOG president.

- President:

  Full name of the ACOG president.

- honorrific:

  Honorific or credential (e.g., MD).

- Presidency:

  Year of presidency.

## Source

American College of Obstetricians and Gynecologists (ACOG) historical
records.

## Value

A tibble listing ACOG presidents with their names and year of service.

## See also

Other datasets:
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md)

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
