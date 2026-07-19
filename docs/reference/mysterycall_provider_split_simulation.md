# Site/Provider Split Simulation (Cluster Cross-Validation)

Performs k-fold cross-validation while splitting by a cluster variable
(e.g. site or provider ID) to ensure that observations from the same
cluster are never split across train and test sets.

## Usage

``` r
mysterycall_provider_split_simulation(
  data,
  outcome,
  predictors,
  cluster_col,
  k = 5,
  family = "nbinom"
)
```

## Arguments

- data:

  A data frame containing the call outcomes.

- outcome:

  Character. Column name of the dependent variable.

- predictors:

  Character vector of predictor column names.

- cluster_col:

  Character. Column name of the clustering/splitting variable.

- k:

  Integer. Number of folds. Default is 5.

- family:

  Character. Model family: `"poisson"`, `"nbinom"`, or `"binomial"`.
  Default is `"nbinom"`.

## Value

A data frame containing average performance metrics across all folds.
