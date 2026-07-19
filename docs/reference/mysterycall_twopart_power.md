# Monte Carlo power for a two-part (offer + conditional wait) design

Mystery-caller access studies almost always have a two-part outcome: a
binary "was any appointment offered?" measured on every call, and a wait
time (count of business days) defined **only** for the calls that
received an offer. Powering such a study means powering both parts
jointly – a single-outcome calculator understates the sample needed
because the wait model runs on the offered subset, not the full sample.

## Usage

``` r
mysterycall_twopart_power(
  n_total,
  offer_ref,
  offer_trt,
  wait_ref,
  wait_trt,
  phi,
  group_frac = 0.5,
  alpha = 0.05,
  n_sim = 500,
  seed = NULL
)
```

## Arguments

- n_total:

  Total calls. May be a vector to trace a power curve (one row per
  value).

- offer_ref, offer_trt:

  Probability of an offer in the reference / treatment group.

- wait_ref, wait_trt:

  Mean wait days (given an offer) in the reference / treatment group.

- phi:

  Negative-binomial dispersion (the `size`; variance is
  `mu + mu^2 / phi`).

- group_frac:

  Fraction of calls in the treatment group. Default `0.5`.

- alpha:

  Two-sided significance level. Default `0.05`.

- n_sim:

  Monte Carlo replicates per sample size. Default `500`.

- seed:

  Optional integer seed for reproducibility.

## Value

An object of class `"mysterycall_twopart_power"`: a list with `table` (a
tibble: `n_total`, `n_ref`, `n_trt`, `pow_offer`, `pow_wait`,
`mean_offered`, `convergence_rate`, `n_sim`) and the call inputs.
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the table.

## Details

This simulates a two-group single-contact design: each call is drawn
from a reference or treatment group, an offer is generated from a
group-specific probability (Bernoulli), and – for offered calls only – a
wait time is drawn from a group-specific negative-binomial. It fits a
logistic model for the offer on the full sample and a negative-binomial
model ([`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html)) for
the wait on the offered subset, and reports the power for the group
effect in each part.

## Examples

``` r
# \donttest{
mysterycall_twopart_power(
  n_total = c(200, 400), offer_ref = 0.70, offer_trt = 0.55,
  wait_ref = 14, wait_trt = 21, phi = 1.7, n_sim = 50, seed = 1
)
#> <mysterycall two-part power: 2 sample size(s), 50 sims, alpha 0.050>
#> # A tibble: 2 × 8
#>   n_total n_ref n_trt pow_offer pow_wait mean_offered convergence_rate n_sim
#>     <dbl> <dbl> <dbl>     <dbl>    <dbl>        <dbl>            <dbl> <dbl>
#> 1     200   100   100      0.56     0.78         125.                1    50
#> 2     400   200   200      0.9      0.96         252.                1    50
# }
```
