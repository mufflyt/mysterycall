# Type I error calibration check for a simulation-based test

A companion to the simulation power functions: given the number of null
rejections observed when a test is run with the effect set to zero,
report the observed type I error rate, an exact binomial confidence
interval, and a verdict on whether the nominal `alpha` is plausibly
attained. Use it to confirm a Monte Carlo power simulator is
well-calibrated before trusting its power numbers.

## Usage

``` r
mysterycall_type_i_check(rejections, n_sim, alpha = 0.05)
```

## Arguments

- rejections:

  Either the count of null replicates that rejected, or the observed
  rejection *rate* in `[0, 1]` (auto-detected: a value `<= 1` with a
  non-integer or `n_sim > 1` is treated as a rate).

- n_sim:

  Number of null replicates.

- alpha:

  Nominal significance level. Default `0.05`.

## Value

A one-row tibble: `rejection_rate`, `ci_low`, `ci_high`, `n_sim`,
`alpha_in_ci`, `verdict`.

## Examples

``` r
# 7 of 100 null replicates rejected at alpha = 0.05
mysterycall_type_i_check(7, n_sim = 100)
#> # A tibble: 1 × 6
#>   rejection_rate ci_low ci_high n_sim alpha_in_ci verdict                      
#>            <dbl>  <dbl>   <dbl> <dbl> <lgl>       <chr>                        
#> 1           0.07 0.0286   0.139   100 TRUE        consistent with nominal alpha
```
