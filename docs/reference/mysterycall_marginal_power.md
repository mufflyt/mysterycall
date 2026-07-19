# Monte Carlo power for a population-marginal, post-stratification-weighted effect in a paired-call design

Audit studies frequently oversample a rare stratum (rural practices,
minority-serving providers, a specific payer market) to get enough calls
there, yet want to report an effect that generalizes to the *population*
mix. The conditional model coefficient does not answer that question;
the population-marginal effect, obtained by post-stratification
weighting, does. This simulates a paired design – each subject (e.g. a
provider) is called under two `conditions` (e.g. two insurance types),
subjects belong to one of two strata sampled at `stratum_sampling` but
reweighted to `pop_stratum` – fits a negative-binomial (or Poisson) GLMM
with a subject random intercept, and reports power for three estimands:
the conditional condition x stratum interaction, the unweighted marginal
condition effect, and the population-weighted marginal condition effect.

## Usage

``` r
mysterycall_marginal_power(
  n_subject,
  cell_means,
  sigma_subject,
  phi,
  stratum_sampling,
  pop_stratum,
  condition_levels = c("A", "B"),
  family = c("negbin", "poisson", "auto"),
  disp_threshold = 1.5,
  alpha = 0.05,
  n_sim = 200,
  seed = NULL
)
```

## Arguments

- n_subject:

  Number of subjects (each contributes two calls). May be a vector to
  trace a power curve.

- cell_means:

  Numeric length-4 vector of the outcome mean in each condition x
  stratum cell, in the order
  `c(cond1_stratum0, cond2_stratum0, cond1_stratum1, cond2_stratum1)`
  (all `> 0`; counts).

- sigma_subject:

  Standard deviation of the subject random intercept on the log scale.

- phi:

  Negative-binomial dispersion (`size`).

- stratum_sampling:

  Probability a subject is in stratum 1 *in the sample*.

- pop_stratum:

  Target population probability of stratum 1 (drives the
  post-stratification weights).

- condition_levels:

  Length-2 labels for the within-subject condition. Default
  `c("A", "B")`.

- family:

  Working family for the fit: `"negbin"` (default), `"poisson"`, or
  `"auto"` (Poisson unless the Pearson dispersion exceeds
  `disp_threshold`).

- disp_threshold:

  Dispersion ratio above which `"auto"` switches to NB. Default `1.5`.

- alpha:

  Two-sided significance level. Default `0.05`.

- n_sim:

  Monte Carlo replicates per sample size. Default `200`.

- seed:

  Optional integer seed.

## Value

An object of class `"mysterycall_marginal_power"`: a list with `table`
(a tibble: `n_subject`, `n_calls`, `pow_cond_interaction`,
`pow_marg_unweighted`, `pow_marg_popweighted`, mean marginal estimates,
`convergence_rate`, `family_summary`, `n_sim`) and `truth` (the true
population-marginal condition effect in outcome units).
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the table. Requires the glmmTMB and marginaleffects packages.

## Examples

``` r
# \donttest{
mysterycall_marginal_power(
  n_subject = c(150, 300),
  cell_means = c(14, 18, 17, 24),   # BCBS/Medicaid x urban/rural wait days
  sigma_subject = 0.4, phi = 1.7,
  stratum_sampling = 0.5, pop_stratum = 0.15,
  n_sim = 40, seed = 1
)
#> <mysterycall marginal power: 2 sample size(s), 40 sims, true marginal effect 4.45>
#> # A tibble: 2 × 10
#>   n_subject n_calls pow_cond_interaction pow_marg_unweighted
#>       <dbl>   <dbl>                <dbl>               <dbl>
#> 1       150     300                0.075               0.825
#> 2       300     600                0.1                 1    
#> # ℹ 6 more variables: pow_marg_popweighted <dbl>, mean_marg_unw_est <dbl>,
#> #   mean_marg_pop_est <dbl>, convergence_rate <dbl>, family_summary <chr>,
#> #   n_sim <dbl>
# }
```
