# Minimum detectable effect by binary search over a power function

Finds the smallest effect size at which a (monotone) power function
reaches a target power, by bisection. Generic: `power_fn` can wrap any
of the package's simulation power calculators (or your own), so the same
solver serves wait times, offer rates, or rate ratios.

## Usage

``` r
mysterycall_find_mde(
  power_fn,
  lower,
  upper,
  target_power = 0.9,
  tol = 0.01,
  max_iter = 20
)
```

## Arguments

- power_fn:

  A function of one numeric argument (the effect size) returning
  estimated power in `[0, 1]`. Assumed non-decreasing in the effect over
  `[lower, upper]`.

- lower, upper:

  Effect-size bracket to search. `power_fn(upper)` should meet or exceed
  `target_power`; if it does not, the search returns `NA` with a
  warning.

- target_power:

  Target power. Default `0.90`.

- tol:

  Stop when the bracket is narrower than `tol`. Default `0.01`.

- max_iter:

  Maximum bisection steps. Default `20`.

## Value

A list with `mde` (the smallest effect meeting the target, or `NA`),
`power_at_mde`, `iterations`, and `history` (a tibble of evaluated
effect/power pairs).

## Examples

``` r
# \donttest{
# smallest wait-time gap (treatment mean) detectable at 90% power
pf <- function(wait_trt) {
  mysterycall_twopart_power(
    n_total = 400, offer_ref = 0.7, offer_trt = 0.7,
    wait_ref = 14, wait_trt = wait_trt, phi = 1.7,
    n_sim = 40, seed = 1
  )$table$pow_wait
}
mysterycall_find_mde(pf, lower = 14, upper = 28, target_power = 0.90)
#> $mde
#> [1] 19.21582
#> 
#> $power_at_mde
#> [1] 0.9
#> 
#> $iterations
#> [1] 12
#> 
#> $history
#> # A tibble: 13 × 2
#>    effect power
#>     <dbl> <dbl>
#>  1   28   1    
#>  2   21   0.975
#>  3   17.5 0.775
#>  4   19.2 0.925
#>  5   18.4 0.775
#>  6   18.8 0.825
#>  7   19.0 0.875
#>  8   19.1 0.85 
#>  9   19.2 0.825
#> 10   19.2 0.9  
#> 11   19.2 0.85 
#> 12   19.2 0.9  
#> 13   19.2 0.9  
#> 
# }
```
