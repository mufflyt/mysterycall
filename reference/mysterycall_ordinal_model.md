# Proportional-Odds Model for a Graded Ordinal Outcome

Fits an ordinal (cumulative-link) model to a graded outcome such as an
access tier, returning proportional-odds odds ratios with Wald
confidence intervals and p-values. Thin wrapper around
[`MASS::polr()`](https://rdrr.io/pkg/MASS/man/polr.html).

## Usage

``` r
mysterycall_ordinal_model(
  data,
  outcome_var,
  predictors,
  levels = NULL,
  conf_level = 0.95
)
```

## Arguments

- data:

  A data frame.

- outcome_var:

  Character scalar. The ordinal outcome column.

- predictors:

  Character vector. Predictor column names.

- levels:

  Character vector or `NULL`. The outcome's increasing level order.
  `NULL` uses the existing factor ordering or sorted unique values.

- conf_level:

  Numeric. Confidence level for the Wald intervals. Default `0.95`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `term`, `or`, `ci_lower`, `ci_upper`, `p_value` (one row
per predictor coefficient).

## See also

Other call-outcomes:
[`mysterycall_classify_call_outcome()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_call_outcome.md),
[`mysterycall_multiresponse_tabulate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multiresponse_tabulate.md),
[`mysterycall_outcome_gradient()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_outcome_gradient.md)

## Examples

``` r
if (requireNamespace("MASS", quietly = TRUE)) {
  set.seed(1)
  df <- data.frame(
    access = factor(sample(c("phone", "in_person", "must_establish"), 90, TRUE),
                    levels = c("phone", "in_person", "must_establish"),
                    ordered = TRUE),
    medicaid = sample(c(0, 1), 90, TRUE)
  )
  mysterycall_ordinal_model(df, "access", "medicaid")
}
#> # A tibble: 1 × 5
#>   term        or ci_lower ci_upper p_value
#>   <chr>    <dbl>    <dbl>    <dbl>   <dbl>
#> 1 medicaid  1.66    0.772     3.58   0.194
```
