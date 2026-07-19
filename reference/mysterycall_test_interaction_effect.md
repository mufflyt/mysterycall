# Test for Interaction Effect in Wait-Time GLMM

Fits a full glmmTMB Negative Binomial model with an interaction term and
compares it to a reduced model without the interaction term using a
Likelihood Ratio Test (ANOVA).

## Usage

``` r
mysterycall_test_interaction_effect(
  data,
  formula_full,
  formula_reduced,
  family = "nbinom2"
)
```

## Arguments

- data:

  A data frame containing the call outcomes.

- formula_full:

  Formula. Formula for the model with the interaction term.

- formula_reduced:

  Formula. Formula for the model without the interaction term.

- family:

  Character or function. Family function for glmmTMB (default is
  "nbinom2").

## Value

An anova table object containing the Likelihood Ratio Test results.
