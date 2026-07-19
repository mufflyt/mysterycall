# Bootstrap Predictor-Retention Stability Analysis

Draws bootstrap resamples from the data, fits a model, and calculates
the percentage of times each predictor is retained as statistically
significant to assess model stability.

## Usage

``` r
mysterycall_bootstrap_predictor_stability(
  data,
  outcome,
  predictors,
  n_boot = 100,
  p_threshold = 0.05,
  family = "binomial"
)
```

## Arguments

- data:

  A data frame containing the call outcomes.

- outcome:

  Character. Column name of the dependent variable.

- predictors:

  Character vector of predictor candidates.

- n_boot:

  Integer. Number of bootstrap replicates. Default is 100.

- p_threshold:

  Numeric. Alpha level to define significance/retention (default is
  0.05).

- family:

  Character. Model family: `"poisson"`, `"nbinom"`, or `"binomial"`.
  Default is `"binomial"`.

## Value

A data frame containing the retention frequency (percentage) for each
predictor.
