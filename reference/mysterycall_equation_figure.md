# Poisson power curve: required sample size across a range of IRRs

Calls
[`mysterycall_poisson_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_power.md)
across a range of incidence rate ratios and returns a ggplot2 line chart
showing how the required sample size per arm changes with effect size.
Useful as Figure 1 in a mystery-caller manuscript.

## Usage

``` r
mysterycall_equation_figure(
  lambda0 = 14,
  irr_seq = seq(1.1, 2, by = 0.05),
  alpha = 0.05,
  power = 0.8,
  both_arms = TRUE
)
```

## Arguments

- lambda0:

  Numeric. Baseline expected count in the reference arm (e.g. mean
  business days for the reference insurance). Default `14`.

- irr_seq:

  Numeric vector of IRR values to evaluate. Default
  `seq(1.10, 2.0, by = 0.05)`.

- alpha:

  Numeric. Two-sided type I error rate. Default `0.05`.

- power:

  Numeric. Desired statistical power. Default `0.80`.

- both_arms:

  Logical. If `TRUE` (default), each arm receives `n` patients; the
  total study size is `2n`.

## Value

A `ggplot` object. The x-axis is IRR, the y-axis is required sample size
per arm, and a vertical dashed line marks IRR = 1 (no effect).

## See also

Other power analysis:
[`mysterycall_cochran_n()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cochran_n.md),
[`mysterycall_poisson_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_power.md),
[`mysterycall_power_calc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_power_calc.md)

## Examples

``` r
mysterycall_equation_figure(lambda0 = 14, irr_seq = seq(1.1, 1.8, 0.1))
#> Poisson power: IRR=1.10, lambda_ref=14.0, lambda_trt=15.4 | n_per_arm=118, n_total=118, calls=236
#> Poisson power: IRR=1.20, lambda_ref=14.0, lambda_trt=16.8 | n_per_arm=31, n_total=31, calls=62
#> Poisson power: IRR=1.30, lambda_ref=14.0, lambda_trt=18.2 | n_per_arm=15, n_total=15, calls=30
#> Poisson power: IRR=1.40, lambda_ref=14.0, lambda_trt=19.6 | n_per_arm=9, n_total=9, calls=18
#> Poisson power: IRR=1.50, lambda_ref=14.0, lambda_trt=21.0 | n_per_arm=6, n_total=6, calls=12
#> Poisson power: IRR=1.60, lambda_ref=14.0, lambda_trt=22.4 | n_per_arm=5, n_total=5, calls=10
#> Poisson power: IRR=1.70, lambda_ref=14.0, lambda_trt=23.8 | n_per_arm=4, n_total=4, calls=8
#> Poisson power: IRR=1.80, lambda_ref=14.0, lambda_trt=25.2 | n_per_arm=3, n_total=3, calls=6
```
