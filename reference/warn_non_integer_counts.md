# Warn When a Count Outcome Is Not Integer-Valued

Poisson and negative binomial likelihoods are defined on non-negative
integers. A non-integer outcome still fits – the quasi-likelihood is
well defined – but it is almost always a unit error (hours recorded as
days, a mean carried forward from an aggregate), and left unchecked it
surfaces only as a flood of per-observation engine warnings that look
like a convergence failure.

## Usage

``` r
warn_non_integer_counts(x, name, strict = FALSE, tol = 1e-08)
```

## Arguments

- x:

  Numeric vector. The outcome values.

- name:

  Character scalar naming the outcome column.

- strict:

  Logical flag. When `TRUE`, a fractional value is an error rather than
  a warning.

- tol:

  Numeric scalar. Tolerance for the integer comparison.

## Value

`invisible(TRUE)`. Called for the warning or error side effect.

## Details

Whether a fractional outcome is an error depends on what the outcome
means, which only the analyst knows. A *count of days until an
appointment* is integer-valued by construction, so a fractional value is
a data error. *Elapsed time measured in days* can legitimately carry
decimals, but then a count distribution is the wrong model for it and a
continuous-time model should be considered instead. The default is
therefore a warning, with `strict = TRUE` available to refuse the fit.

Offending values are never rounded or truncated.

## See also

Other validation:
[`.audit_volatile_fields`](https://mufflyt.github.io/mysterycall/reference/dot-audit_volatile_fields.md),
[`.load_nanp_lookup()`](https://mufflyt.github.io/mysterycall/reference/dot-load_nanp_lookup.md),
[`.mc_check_coord_axis()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_coord_axis.md),
[`.mc_conv_warning_pattern()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_conv_warning_pattern.md),
[`assert_model_cohort()`](https://mufflyt.github.io/mysterycall/reference/assert_model_cohort.md),
[`summarise_fit_warnings()`](https://mufflyt.github.io/mysterycall/reference/summarise_fit_warnings.md),
[`validate_coordinates()`](https://mufflyt.github.io/mysterycall/reference/validate_coordinates.md),
[`validate_dataframe()`](https://mufflyt.github.io/mysterycall/reference/validate_dataframe.md),
[`validate_log_offset()`](https://mufflyt.github.io/mysterycall/reference/validate_log_offset.md),
[`validate_outcome_finite()`](https://mufflyt.github.io/mysterycall/reference/validate_outcome_finite.md),
[`validate_required_columns()`](https://mufflyt.github.io/mysterycall/reference/validate_required_columns.md),
[`validate_scalar_positive_numeric()`](https://mufflyt.github.io/mysterycall/reference/validate_scalar_positive_numeric.md)
