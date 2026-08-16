# Fill a column downward with the last non-NA value

Uses [`tidyr::fill()`](https://tidyr.tidyverse.org/reference/fill.html)
when available, falls back to
[`zoo::na.locf()`](https://rdrr.io/pkg/zoo/man/na.locf.html), then a
pure-base-R forward-fill loop.

## Usage

``` r
.mc_fill_col(data, col)
```

## Arguments

- data:

  A data frame.

- col:

  Column name to fill.

## Value

     `data` with `col` forward-filled.
