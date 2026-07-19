# Cochran finite-population sample size

Calculates the number of providers to sample from a known directory of
`N` providers so that the estimated proportion (e.g. acceptance rate) is
within `margin_of_error` with 95% confidence. This is the standard
Cochran (1977) formula used in mystery caller audit studies to determine
how many physicians to call from a specialty directory.

## Usage

``` r
mysterycall_cochran_n(N, margin_of_error = 0.05)
```

## Arguments

- N:

  Integer or numeric. Total number of providers in the sampling frame
  (e.g. size of the specialty directory).

- margin_of_error:

  Numeric scalar in (0, 1). Desired margin of error for proportions.
  Default `0.05` (+/-5 percentage points).

## Value

A named list with elements:

- `n`:

  Required sample size (rounded up to the nearest integer).

- `N`:

  Input population size.

- `margin_of_error`:

  Input margin of error.

- `effective_margin`:

  Achieved margin of error at the returned `n`.

## Details

The formula is: `n = N / (1 + N * e^2)` where `e` is the margin of
error.

## References

Cochran, W. G. (1977). *Sampling Techniques* (3rd ed.). Wiley.

## See also

[`mysterycall_poisson_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_power.md)

Other power analysis:
[`mysterycall_equation_figure()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_equation_figure.md),
[`mysterycall_poisson_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_power.md),
[`mysterycall_power_calc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_power_calc.md)

## Examples

``` r
# 369 pediatric otolaryngologists in the directory
mysterycall_cochran_n(N = 369)   # ~= 192
#> $n
#> [1] 192
#> 
#> $N
#> [1] 369
#> 
#> $margin_of_error
#> [1] 0.05
#> 
#> $effective_margin
#> [1] 0.04998306
#> 

# 215 neurotologists in the directory
mysterycall_cochran_n(N = 215)   # ~= 140
#> $n
#> [1] 140
#> 
#> $N
#> [1] 215
#> 
#> $margin_of_error
#> [1] 0.05
#> 
#> $effective_margin
#> [1] 0.04991687
#> 
```
