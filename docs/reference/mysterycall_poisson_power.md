# Sample-size calculation for a Poisson mystery caller study

Computes the number of providers per insurance arm needed to detect a
specified Incidence Rate Ratio (IRR) in a mystery caller study with a
Poisson count outcome (e.g. business days until appointment). Each
provider is called once per insurance arm.

## Usage

``` r
mysterycall_poisson_power(
  irr,
  lambda_ref,
  alpha = 0.05,
  power = 0.8,
  both_arms = TRUE,
  icc = 0,
  calls_per_cluster = 2L
)
```

## Arguments

- irr:

  Numeric. The minimum detectable incidence rate ratio. Must be positive
  and not equal to 1.

- lambda_ref:

  Numeric. Expected mean wait time (days) for the reference insurance
  group (e.g. BCBS). Must be positive.

- alpha:

  Numeric. Two-sided type I error rate. Default `0.05`.

- power:

  Numeric. Desired statistical power (1 - beta). Default `0.80`.

- both_arms:

  Logical. When `TRUE`, each provider is called with **both** insurance
  types (paired design), halving the total providers needed. Default
  `TRUE`.

- icc:

  Numeric in \[0, 1). Intra-cluster correlation if providers are
  clustered (e.g. same practice). Applied as a design-effect inflation:
  `n * (1 + (m - 1) * icc)` where `m` is `calls_per_cluster`. Default
  `0` (no clustering adjustment).

- calls_per_cluster:

  Integer. Average calls per cluster, used only when `icc > 0`. Default
  `2L`.

## Value

A named list with elements:

- `n_per_arm`:

  Providers needed per insurance arm.

- `n_total`:

  Total providers needed.

- `n_total_calls`:

  Total calls placed (= `n_per_arm * 2` or `n_total * 2` for paired
  design).

- `irr`, `lambda_ref`, `lambda_trt`:

  Input parameters plus derived treatment-arm mean.

- `alpha`, `power`:

  Input parameters.

- `design_effect`:

  Inflation factor when `icc > 0`.

## Details

The sample-size formula is derived from the score test for comparing two
independent Poisson rates \\\lambda_0\\ (reference arm, e.g. BCBS) and
\\\lambda_1 = \text{IRR} \times \lambda_0\\ (treatment arm, e.g.
Medicaid):

\$\$n = \frac{(z\_{\alpha/2} + z\_\beta)^2 \left(\frac{1}{\lambda_0} +
\frac{1}{\lambda_1}\right)}{(\log \text{IRR})^2}\$\$

This gives providers per arm. Total providers = `n * 2`. When each
provider is called with both insurance types (`both_arms = TRUE`), only
`n` providers are needed in total.

## See also

[`mysterycall_cochran_n()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cochran_n.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)

Other power analysis:
[`mysterycall_cochran_n()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cochran_n.md),
[`mysterycall_equation_figure()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_equation_figure.md),
[`mysterycall_power_calc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_power_calc.md)

## Examples

``` r
# Detect IRR = 1.40 (Medicaid 40% longer waits) vs BCBS mean of 14 days
mysterycall_poisson_power(irr = 1.40, lambda_ref = 14)
#> Poisson power: IRR=1.40, lambda_ref=14.0, lambda_trt=19.6 | n_per_arm=9, n_total=9, calls=18
#> $n_per_arm
#> [1] 9
#> 
#> $n_total
#> [1] 9
#> 
#> $n_total_calls
#> [1] 18
#> 
#> $irr
#> [1] 1.4
#> 
#> $lambda_ref
#> [1] 14
#> 
#> $lambda_trt
#> [1] 19.6
#> 
#> $alpha
#> [1] 0.05
#> 
#> $power
#> [1] 0.8
#> 
#> $design_effect
#> [1] 1
#> 

# Higher power
mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, power = 0.90)
#> Poisson power: IRR=1.40, lambda_ref=14.0, lambda_trt=19.6 | n_per_arm=12, n_total=12, calls=24
#> $n_per_arm
#> [1] 12
#> 
#> $n_total
#> [1] 12
#> 
#> $n_total_calls
#> [1] 24
#> 
#> $irr
#> [1] 1.4
#> 
#> $lambda_ref
#> [1] 14
#> 
#> $lambda_trt
#> [1] 19.6
#> 
#> $alpha
#> [1] 0.05
#> 
#> $power
#> [1] 0.9
#> 
#> $design_effect
#> [1] 1
#> 

# Smaller effect (IRR = 1.20)
mysterycall_poisson_power(irr = 1.20, lambda_ref = 14)
#> Poisson power: IRR=1.20, lambda_ref=14.0, lambda_trt=16.8 | n_per_arm=31, n_total=31, calls=62
#> $n_per_arm
#> [1] 31
#> 
#> $n_total
#> [1] 31
#> 
#> $n_total_calls
#> [1] 62
#> 
#> $irr
#> [1] 1.2
#> 
#> $lambda_ref
#> [1] 14
#> 
#> $lambda_trt
#> [1] 16.8
#> 
#> $alpha
#> [1] 0.05
#> 
#> $power
#> [1] 0.8
#> 
#> $design_effect
#> [1] 1
#> 
```
