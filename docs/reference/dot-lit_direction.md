# Determine disparity direction from OR and 95 % CI

Determine disparity direction from OR and 95 % CI

## Usage

``` r
.lit_direction(or, ci_low, ci_high)
```

## Arguments

- or:

  Numeric vector of odds ratios.

- ci_low:

  Numeric vector of lower CI bounds.

- ci_high:

  Numeric vector of upper CI bounds.

## Value

Character vector: "Disparity detected", "Favors equity", or "NS".
