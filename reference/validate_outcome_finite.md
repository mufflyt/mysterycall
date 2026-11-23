# Reject Non-Finite Values in a Count Outcome

`NA` is a declared missing outcome: the fitters remove those rows
through the complete-case filter and report the count. `NaN`, `Inf` and
`-Inf` are not declared missingness – they are the residue of an invalid
computation, and `is.na(NaN)` being `TRUE` means a `NaN` outcome would
otherwise be swept into the missing-data count and silently excluded.

## Usage

``` r
validate_outcome_finite(x, name)
```

## Arguments

- x:

  Numeric vector. The outcome values.

- name:

  Character scalar naming the outcome column.

## Value

`invisible(TRUE)`. Called for the error side effect.

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
[`validate_required_columns()`](https://mufflyt.github.io/mysterycall/reference/validate_required_columns.md),
[`validate_scalar_positive_numeric()`](https://mufflyt.github.io/mysterycall/reference/validate_scalar_positive_numeric.md),
[`warn_non_integer_counts()`](https://mufflyt.github.io/mysterycall/reference/warn_non_integer_counts.md)
