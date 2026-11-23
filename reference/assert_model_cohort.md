# Assert That a Fitted Model Used the Expected Number of Rows

Model fitting engines apply their own `na.action` to the model frame, so
a value that only becomes unusable inside the formula –
[`log()`](https://rdrr.io/r/base/Log.html) of a non-positive offset, for
instance – is dropped by the engine without passing through the caller's
complete-case filter. The returned object then reports a cohort size
that the model never used, which silently changes the denominator of
every downstream result.

## Usage

``` r
assert_model_cohort(model, n_expected, fn_name)
```

## Arguments

- model:

  A fitted model object supporting
  [`stats::nobs()`](https://rdrr.io/r/stats/nobs.html).

- n_expected:

  Integer scalar. Rows supplied to the fitting call.

- fn_name:

  Character scalar naming the calling function in the error.

## Value

`invisible(n_used)`, the row count the model reports using.

## See also

Other validation:
[`.audit_volatile_fields`](https://mufflyt.github.io/mysterycall/reference/dot-audit_volatile_fields.md),
[`.load_nanp_lookup()`](https://mufflyt.github.io/mysterycall/reference/dot-load_nanp_lookup.md),
[`.mc_check_coord_axis()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_coord_axis.md),
[`.mc_conv_warning_pattern()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_conv_warning_pattern.md),
[`summarise_fit_warnings()`](https://mufflyt.github.io/mysterycall/reference/summarise_fit_warnings.md),
[`validate_coordinates()`](https://mufflyt.github.io/mysterycall/reference/validate_coordinates.md),
[`validate_dataframe()`](https://mufflyt.github.io/mysterycall/reference/validate_dataframe.md),
[`validate_log_offset()`](https://mufflyt.github.io/mysterycall/reference/validate_log_offset.md),
[`validate_outcome_finite()`](https://mufflyt.github.io/mysterycall/reference/validate_outcome_finite.md),
[`validate_required_columns()`](https://mufflyt.github.io/mysterycall/reference/validate_required_columns.md),
[`validate_scalar_positive_numeric()`](https://mufflyt.github.io/mysterycall/reference/validate_scalar_positive_numeric.md),
[`warn_non_integer_counts()`](https://mufflyt.github.io/mysterycall/reference/warn_non_integer_counts.md)
