# Simulation power for a covariate-adjusted NB GLMM with a cluster ICC

The existing power tools cluster on the *physician* (paired calls). A
geographic access study instead adjusts for confounders and clusters
callers within a higher-level unit – states, markets – whose correlation
is expressed as an intraclass correlation coefficient (ICC), not a
random-slope design. Analysts usually paper over this with a "+20% for
clustering" rule of thumb. This instead simulates power for the *actual
adjusted analysis*: a negative-binomial GLMM for the wait outcome with a
rural (exposure) fixed effect, a subspecialty fixed effect, a
configurable number of nuisance adjustment covariates, and a
**state-level random intercept whose SD is derived from a target ICC**
via `sigma = sqrt(ICC/(1 - ICC) * (trigamma(1/phi) + pi^2/3))` – the
same latent-scale decomposition
[`mysterycall_icc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_icc.md)
uses. It reports the power to detect the rural effect along with the
mean estimated effect, its standard error, and the model convergence
rate.

## Usage

``` r
mysterycall_adjusted_power(
  n_total,
  rural_frac,
  wait_urban,
  wait_rural,
  phi,
  state_icc = 0.05,
  n_states = 51,
  n_subspecs = 7,
  n_extra_covars = 6,
  alpha = 0.05,
  n_sim = 100,
  seed = NULL
)
```

## Arguments

- n_total:

  Integer total sample size (calls).

- rural_frac:

  Fraction of calls in the rural (exposure) group, in `(0, 1)`.

- wait_urban, wait_rural:

  Mean wait (days) in the urban and rural groups; their ratio is the
  true effect on the log scale.

- phi:

  Negative-binomial dispersion (`size`); smaller is more overdispersed.

- state_icc:

  Target intraclass correlation for the cluster random intercept, in
  `[0, 0.9)`. Default `0.05`.

- n_states:

  Number of clusters (random-intercept levels). Default `51`.

- n_subspecs:

  Number of subspecialty fixed-effect levels (`1` drops the term).
  Default `7`.

- n_extra_covars:

  Number of nuisance adjustment covariates. Default `6`.

- alpha:

  Two-sided significance level. Default `0.05`.

- n_sim:

  Number of Monte Carlo replicates. Default `100`.

- seed:

  Optional integer seed for reproducibility. Default `NULL`.

## Value

A one-row
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html):
`n_total`, `n_rural`, `n_urban`, `power` (rural-effect rejection rate),
`mean_log_effect`, `mean_se`, `median_se`, `convergence_rate`,
`state_icc`, `sigma_state`, `n_states`, `n_subspecs`, `n_extra_covars`,
`n_sim`. Pair with
[`mysterycall_find_mde()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_find_mde.md)
to solve for a detectable effect, or call across an `n_total` grid for a
power curve.

## Details

Requires the glmmTMB package.

## See also

[`mysterycall_marginal_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_marginal_power.md),
[`mysterycall_twopart_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_twopart_power.md),
[`mysterycall_find_mde()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_find_mde.md)

Other power:
[`mysterycall_lm_interaction_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lm_interaction_power.md),
[`mysterycall_ttest_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ttest_power.md)

## Examples

``` r
# \donttest{
if (requireNamespace("glmmTMB", quietly = TRUE)) {
  mysterycall_adjusted_power(
    n_total = 400, rural_frac = 0.15,
    wait_urban = 20, wait_rural = 28, phi = 1.7,
    state_icc = 0.05, n_sim = 20, seed = 1
  )
}
#> # A tibble: 1 × 14
#>   n_total n_rural n_urban power mean_log_effect mean_se median_se
#>     <dbl>   <dbl>   <dbl> <dbl>           <dbl>   <dbl>     <dbl>
#> 1     400      60     340   0.8           0.343   0.122     0.123
#> # ℹ 7 more variables: convergence_rate <dbl>, state_icc <dbl>,
#> #   sigma_state <dbl>, n_states <dbl>, n_subspecs <dbl>, n_extra_covars <dbl>,
#> #   n_sim <dbl>
# }
```
