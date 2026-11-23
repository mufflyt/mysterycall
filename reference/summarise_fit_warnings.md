# Summarise Captured Model-Fitting Warnings

A single data problem can make a fitting engine emit one warning per
observation; a non-integer Poisson outcome produces one
`"non-integer x ="` warning per row. Storing every one of them on the
result object makes the diagnostic unreadable and the object large, so
keep the distinct warnings and count the rest.

## Usage

``` r
summarise_fit_warnings(x, max_shown = 10L)
```

## Arguments

- x:

  Character vector of captured warning messages.

- max_shown:

  Integer scalar. Distinct non-convergence messages to retain.
  Convergence-related messages are retained regardless.

## Value

Character vector: every distinct convergence-related message, then up to
`max_shown` other distinct messages, then a count of any remainder.

## Details

Convergence-related warnings are **never** discarded by the cap. A
single data problem can emit hundreds of per-observation warnings, and
if the cap were applied in arrival order the one warning that matters –
glmmTMB's "extreme or very small eigenvalues detected", which is the
only signal for a numerically singular covariance when the optimizer
code is 0 and the Hessian is nominally positive-definite – could be
dropped, leaving the object claiming the fit converged.

## See also

Other validation:
[`.audit_volatile_fields`](https://mufflyt.github.io/mysterycall/reference/dot-audit_volatile_fields.md),
[`.load_nanp_lookup()`](https://mufflyt.github.io/mysterycall/reference/dot-load_nanp_lookup.md),
[`.mc_check_coord_axis()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_coord_axis.md),
[`.mc_conv_warning_pattern()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_conv_warning_pattern.md),
[`assert_model_cohort()`](https://mufflyt.github.io/mysterycall/reference/assert_model_cohort.md),
[`validate_coordinates()`](https://mufflyt.github.io/mysterycall/reference/validate_coordinates.md),
[`validate_dataframe()`](https://mufflyt.github.io/mysterycall/reference/validate_dataframe.md),
[`validate_log_offset()`](https://mufflyt.github.io/mysterycall/reference/validate_log_offset.md),
[`validate_outcome_finite()`](https://mufflyt.github.io/mysterycall/reference/validate_outcome_finite.md),
[`validate_required_columns()`](https://mufflyt.github.io/mysterycall/reference/validate_required_columns.md),
[`validate_scalar_positive_numeric()`](https://mufflyt.github.io/mysterycall/reference/validate_scalar_positive_numeric.md),
[`warn_non_integer_counts()`](https://mufflyt.github.io/mysterycall/reference/warn_non_integer_counts.md)
