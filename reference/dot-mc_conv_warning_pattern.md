# Pattern Matching Convergence-Related Diagnostic Text

Used to tell an optimizer or numerical problem apart from a warning
about something else, such as a non-integer outcome. Singularity is
deliberately **not** in this pattern: a boundary-singular random-effect
variance is a property of the data, reported separately in
`$convergence$singular`, and a singular fit whose optimizer returned
code 0 has converged.

## Usage

``` r
.mc_conv_warning_pattern()
```

## Value

Character scalar regular expression.

## See also

Other validation:
[`.audit_volatile_fields`](https://mufflyt.github.io/mysterycall/reference/dot-audit_volatile_fields.md),
[`.load_nanp_lookup()`](https://mufflyt.github.io/mysterycall/reference/dot-load_nanp_lookup.md),
[`.mc_check_coord_axis()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_coord_axis.md),
[`assert_model_cohort()`](https://mufflyt.github.io/mysterycall/reference/assert_model_cohort.md),
[`summarise_fit_warnings()`](https://mufflyt.github.io/mysterycall/reference/summarise_fit_warnings.md),
[`validate_coordinates()`](https://mufflyt.github.io/mysterycall/reference/validate_coordinates.md),
[`validate_dataframe()`](https://mufflyt.github.io/mysterycall/reference/validate_dataframe.md),
[`validate_log_offset()`](https://mufflyt.github.io/mysterycall/reference/validate_log_offset.md),
[`validate_outcome_finite()`](https://mufflyt.github.io/mysterycall/reference/validate_outcome_finite.md),
[`validate_required_columns()`](https://mufflyt.github.io/mysterycall/reference/validate_required_columns.md),
[`validate_scalar_positive_numeric()`](https://mufflyt.github.io/mysterycall/reference/validate_scalar_positive_numeric.md),
[`warn_non_integer_counts()`](https://mufflyt.github.io/mysterycall/reference/warn_non_integer_counts.md)
