# Compare Count Mixed Model Families (Poisson, nbinom1, nbinom2)

Fits and compares three different generalized linear mixed-effects model
(GLMM) count families (Poisson, linear Negative Binomial, and quadratic
Negative Binomial) using AIC, BIC, and Log-Likelihood to identify the
best fit for overdispersed wait times.

## Usage

``` r
mysterycall_compare_count_families(data, formula)
```

## Arguments

- data:

  A data frame containing the call outcomes.

- formula:

  Formula. Formula for the mixed model (e.g.
  `Wait_Time ~ PE_or_Not * Payer + (1|Matched_Pair_ID)`).

## Value

A data frame containing fit metrics (AIC, BIC, logLik, deviance) for
each model.
