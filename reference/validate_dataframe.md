# Validate a Data Frame

Validate a Data Frame

## Usage

``` r
validate_dataframe(
  x,
  name = "data",
  allow_null = FALSE,
  allow_zero_rows = TRUE
)
```

## Arguments

- x:

  Object to validate.

- name:

  Character scalar naming the object for error messages.

- allow_null:

  Logical flag. When `TRUE`, `NULL` is accepted without error.

- allow_zero_rows:

  Logical flag. When `FALSE`, an error is thrown if `nrow(x) == 0`.

## Value

The validated object (invisibly).

## See also

Other validation:
[`.audit_volatile_fields`](https://mufflyt.github.io/mysterycall/reference/dot-audit_volatile_fields.md),
[`.load_nanp_lookup()`](https://mufflyt.github.io/mysterycall/reference/dot-load_nanp_lookup.md),
[`.mc_check_coord_axis()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_coord_axis.md),
[`.mc_conv_warning_pattern()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_conv_warning_pattern.md),
[`assert_model_cohort()`](https://mufflyt.github.io/mysterycall/reference/assert_model_cohort.md),
[`summarise_fit_warnings()`](https://mufflyt.github.io/mysterycall/reference/summarise_fit_warnings.md),
[`validate_coordinates()`](https://mufflyt.github.io/mysterycall/reference/validate_coordinates.md),
[`validate_log_offset()`](https://mufflyt.github.io/mysterycall/reference/validate_log_offset.md),
[`validate_outcome_finite()`](https://mufflyt.github.io/mysterycall/reference/validate_outcome_finite.md),
[`validate_required_columns()`](https://mufflyt.github.io/mysterycall/reference/validate_required_columns.md),
[`validate_scalar_positive_numeric()`](https://mufflyt.github.io/mysterycall/reference/validate_scalar_positive_numeric.md),
[`warn_non_integer_counts()`](https://mufflyt.github.io/mysterycall/reference/warn_non_integer_counts.md)
