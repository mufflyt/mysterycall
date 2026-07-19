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
[`validate_required_columns()`](https://mufflyt.github.io/mysterycall/reference/validate_required_columns.md),
[`validate_scalar_positive_numeric()`](https://mufflyt.github.io/mysterycall/reference/validate_scalar_positive_numeric.md)
