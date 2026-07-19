# Recalibration Assessment for Fitted Models

Assesses the calibration of predicted values against observed outcomes
by fitting a calibration curve and returning the calibration intercept
and slope.

## Usage

``` r
mysterycall_recalibration_assessment(
  observed,
  predicted,
  family = "binomial",
  plot = TRUE
)
```

## Arguments

- observed:

  Numeric vector of actual observed outcomes.

- predicted:

  Numeric vector of predicted values/probabilities from the model.

- family:

  Character. Outcome distribution: `"binomial"` or `"poisson"`. Default
  is `"binomial"`.

- plot:

  Logical. If TRUE, returns a calibration plot. Default is TRUE.

## Value

A list containing the calibration intercept, slope, and optionally a
ggplot2 calibration curve.
