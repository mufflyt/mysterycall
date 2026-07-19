# Run DHARMa Residual Diagnostics for GLMM Validation

Simulates randomized quantile residuals using DHARMa and performs
non-parametric dispersion and outlier tests to validate the model's
distributional assumptions.

## Usage

``` r
mysterycall_validate_residuals_dharma(model, plot_path = NULL, n_sim = 250)
```

## Arguments

- model:

  A fitted model object (e.g. from glmmTMB, lmer, or glm).

- plot_path:

  Character. If provided, saves the DHARMa residual plot as a PNG at
  this path.

- n_sim:

  Integer. Number of residual simulations. Default is 250.

## Value

A list containing the DHARMa residuals object and the dispersion/outlier
test results.
