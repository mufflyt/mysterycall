# Model Same-Day Appointments (Wait Time is Zero)

Fits a logistic regression model predicting the probability that an
appointment wait time is exactly zero (same-day appointment) versus a
positive wait time.

## Usage

``` r
mysterycall_model_zero_wait(data, formula, wait_col = "business_days")
```

## Arguments

- data:

  A data frame containing the call outcomes.

- formula:

  Formula. Formula for the logistic model (e.g.
  `appt_zero ~ PE_or_Not * Payer`).

- wait_col:

  Character. Column name representing the wait days.

## Value

A glm model object of family binomial.
