# Model Non-Linear Relationships with Splines or Polynomials

Fits a regression model incorporating natural cubic splines or
polynomial terms for a continuous predictor, and optionally plots the
predicted non-linear relationship.

## Usage

``` r
mysterycall_model_nonlinear(
  data,
  outcome_col,
  predictor_col,
  other_covariates = NULL,
  type = "spline",
  df_degree = 3,
  plot = TRUE
)
```

## Arguments

- data:

  A data frame containing the call outcomes.

- outcome_col:

  Character. Column name of the dependent variable.

- predictor_col:

  Character. Column name of the continuous predictor to model
  non-linearly.

- other_covariates:

  Character vector of other covariates to include in the model.

- type:

  Character. Type of non-linear model: `"spline"` (natural cubic spline)
  or `"poly"` (orthogonal polynomial). Default is `"spline"`.

- df_degree:

  Integer. Degrees of freedom for splines, or degree for polynomial.
  Default is 3.

- plot:

  Logical. If TRUE, plots the non-linear relationship. Default is TRUE.

## Value

A list containing the fitted model object and the ggplot2 object (if
plot is TRUE).
