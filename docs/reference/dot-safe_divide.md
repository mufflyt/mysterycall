# Safe Division

Avoids division-by-zero; returns `default` when denominator is 0 or NA.

## Usage

``` r
.safe_divide(numerator, denominator, default = NA_real_)
```

## Arguments

- numerator:

  Numeric vector.

- denominator:

  Numeric vector.

- default:

  Numeric scalar to return if denominator is 0 or NA.

## Value

Numeric vector.
