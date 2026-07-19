# Locked Temporal Validation for Count/Binary Models

Evaluates model performance by training on historical data (before a
temporal threshold) and validating predictions on future data.

## Usage

``` r
mysterycall_temporal_validation(
  data,
  outcome,
  predictors,
  time_col,
  threshold,
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

- time_col:

  Character. Column name representing time (Date or numeric year).

- threshold:

  Value of time_col used to split train (\<= threshold) and test (\>
  threshold).

- family:

  Character. Model family: `"poisson"`, `"nbinom"`, or `"binomial"`.
  Default is `"nbinom"`.

## Value

A list containing the train model, test predictions, and out-of-sample
performance metrics (MSE, MAE).
