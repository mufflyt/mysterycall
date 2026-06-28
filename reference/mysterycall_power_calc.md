# Clustered binary power and sample-size calculator (GLMM / VIF approach)

Computes the required sample size or achieved power for a two-group
binary outcome in a clustered mystery-caller study using the variance
inflation factor (VIF) approach for clustered binary data (Donner & Klar
2000). This is the appropriate correction when multiple calls are placed
to the same physician (cluster), inducing within-cluster correlation
that inflates effective sample-size requirements relative to an
independence assumption.

## Usage

``` r
mysterycall_power_calc(
  p1 = 0.7,
  p2 = NULL,
  n = NULL,
  icc = 0.05,
  m = 4,
  alpha = 0.05,
  power = 0.8
)
```

## Arguments

- p1:

  Numeric. Baseline acceptance probability for the reference group (e.g.
  commercial insurance). Must be in (0, 1). Default `0.70`.

- p2:

  Numeric or `NULL`. Expected acceptance probability for the comparison
  group (e.g. Medicaid). Must be in (0, 1) and differ from `p1`. If
  `NULL`, power is back-calculated from `n`; `n` must then be provided.
  Either `p2` or `n` must be non-`NULL`.

- n:

  Integer or `NULL`. Known simple (unclustered) sample size per group.
  If `NULL`, \\n\\ is solved from `p1`, `p2`, `alpha`, and `power`.
  Either `p2` or `n` must be non-`NULL`.

- icc:

  Numeric. Intraclass correlation coefficient capturing within-physician
  clustering. Must be in \\\[0, 1)\\. Default `0.05`.

- m:

  Numeric. Average number of mystery calls placed per physician (cluster
  size). Must be \\\geq 1\\. Default `4`.

- alpha:

  Numeric. Two-sided significance level. Must be in (0, 1). Default
  `0.05`.

- power:

  Numeric. Desired statistical power (1 - beta) when solving for `n`.
  Must be in (0, 1). Default `0.80`. Ignored when `n` is supplied;
  achieved power is returned in that case.

## Value

A named list with elements:

- `n_simple`:

  Unadjusted sample size per group from the two-proportion \\z\\-test
  (integer).

- `n_adjusted`:

  Clustering-adjusted sample size per group, \\\lceil n\_{\text{simple}}
  \times \text{VIF} \rceil\\ (integer).

- `vif`:

  Variance inflation factor \\1 + (m - 1)\\\rho\\.

- `p1`:

  Input baseline acceptance probability.

- `p2`:

  Input comparison acceptance probability (or `NULL`).

- `alpha`:

  Input significance level.

- `power`:

  Achieved power at the returned `n_simple`. When solving for `n`, this
  reflects the power at the ceiling-rounded `n_simple` and will be
  \\\geq\\ the requested power. When `n` is supplied directly, this is
  the back-calculated power.

- `icc`:

  Input intraclass correlation.

- `m`:

  Input average cluster size.

- `message`:

  A character string suitable for a manuscript methods section
  summarising the key design parameters and result.

## Details

## References

Donner A, Klar N (2000). *Design and Analysis of Cluster Randomization
Trials in Health Research*. Arnold: London.

## See also

[`mysterycall_cochran_n()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cochran_n.md),
[`mysterycall_poisson_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_power.md)

Other power analysis:
[`mysterycall_cochran_n()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cochran_n.md),
[`mysterycall_equation_figure()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_equation_figure.md),
[`mysterycall_poisson_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_power.md)

## Examples

``` r
# Solve for n: Medicaid acceptance (p2 = 0.50) vs commercial (p1 = 0.70)
mysterycall_power_calc(p1 = 0.70, p2 = 0.50)
#> mysterycall_power_calc: n_simple=91, n_adjusted=105, VIF=1.150, power=80.3%
#> $n_simple
#> [1] 91
#> 
#> $n_adjusted
#> [1] 105
#> 
#> $vif
#> [1] 1.15
#> 
#> $p1
#> [1] 0.7
#> 
#> $p2
#> [1] 0.5
#> 
#> $alpha
#> [1] 0.05
#> 
#> $power
#> [1] 0.803184
#> 
#> $icc
#> [1] 0.05
#> 
#> $m
#> [1] 4
#> 
#> $message
#> [1] "Assuming an acceptance probability of 70% in the reference group and 50% in the comparison group, with an intraclass correlation of 0.050 and an average of 4.0 calls per physician (VIF = 1.150), 91 participants per group are required before clustering adjustment and 105 per group after adjustment, yielding 80.3% power at a two-sided alpha of 0.050 (Donner & Klar 2000)."
#> 

# Larger ICC and more calls per physician inflate the adjusted n
mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 0.15, m = 6)
#> mysterycall_power_calc: n_simple=91, n_adjusted=160, VIF=1.750, power=80.3%
#> $n_simple
#> [1] 91
#> 
#> $n_adjusted
#> [1] 160
#> 
#> $vif
#> [1] 1.75
#> 
#> $p1
#> [1] 0.7
#> 
#> $p2
#> [1] 0.5
#> 
#> $alpha
#> [1] 0.05
#> 
#> $power
#> [1] 0.803184
#> 
#> $icc
#> [1] 0.15
#> 
#> $m
#> [1] 6
#> 
#> $message
#> [1] "Assuming an acceptance probability of 70% in the reference group and 50% in the comparison group, with an intraclass correlation of 0.150 and an average of 6.0 calls per physician (VIF = 1.750), 91 participants per group are required before clustering adjustment and 160 per group after adjustment, yielding 80.3% power at a two-sided alpha of 0.050 (Donner & Klar 2000)."
#> 

# 90% power and a smaller effect require a larger sample
mysterycall_power_calc(p1 = 0.70, p2 = 0.55, power = 0.90)
#> mysterycall_power_calc: n_simple=214, n_adjusted=247, VIF=1.150, power=90.0%
#> $n_simple
#> [1] 214
#> 
#> $n_adjusted
#> [1] 247
#> 
#> $vif
#> [1] 1.15
#> 
#> $p1
#> [1] 0.7
#> 
#> $p2
#> [1] 0.55
#> 
#> $alpha
#> [1] 0.05
#> 
#> $power
#> [1] 0.9004637
#> 
#> $icc
#> [1] 0.05
#> 
#> $m
#> [1] 4
#> 
#> $message
#> [1] "Assuming an acceptance probability of 70% in the reference group and 55% in the comparison group, with an intraclass correlation of 0.050 and an average of 4.0 calls per physician (VIF = 1.150), 214 participants per group are required before clustering adjustment and 247 per group after adjustment, yielding 90.0% power at a two-sided alpha of 0.050 (Donner & Klar 2000)."
#> 

# Back-calculate power for a fixed simple n of 100 per group
mysterycall_power_calc(p1 = 0.70, p2 = 0.50, n = 100)
#> mysterycall_power_calc: n_simple=100, n_adjusted=115, VIF=1.150, power=83.9%
#> $n_simple
#> [1] 100
#> 
#> $n_adjusted
#> [1] 115
#> 
#> $vif
#> [1] 1.15
#> 
#> $p1
#> [1] 0.7
#> 
#> $p2
#> [1] 0.5
#> 
#> $alpha
#> [1] 0.05
#> 
#> $power
#> [1] 0.8386379
#> 
#> $icc
#> [1] 0.05
#> 
#> $m
#> [1] 4
#> 
#> $message
#> [1] "Assuming an acceptance probability of 70% in the reference group and 50% in the comparison group, with an intraclass correlation of 0.050 and an average of 4.0 calls per physician (VIF = 1.150), 100 participants per group are required before clustering adjustment and 115 per group after adjustment, yielding 83.9% power at a two-sided alpha of 0.050 (Donner & Klar 2000)."
#> 
```
