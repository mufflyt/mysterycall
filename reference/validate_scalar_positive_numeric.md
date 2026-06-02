# Validate a Scalar Positive Numeric Value

Validate a Scalar Positive Numeric Value

## Usage

``` r
validate_scalar_positive_numeric(x, name, allow_null = TRUE)
```

## Arguments

- x:

  Numeric scalar to validate.

- name:

  Character scalar naming the object for error messages.

- allow_null:

  Logical flag. When `TRUE`, `NULL` is accepted without error.

## Value

The validated object (invisibly).

## See also

Other validation:
[`.audit_volatile_fields`](https://mufflyt.github.io/mysterycall/reference/dot-audit_volatile_fields.md),
[`.load_nanp_lookup()`](https://mufflyt.github.io/mysterycall/reference/dot-load_nanp_lookup.md),
[`validate_dataframe()`](https://mufflyt.github.io/mysterycall/reference/validate_dataframe.md),
[`validate_required_columns()`](https://mufflyt.github.io/mysterycall/reference/validate_required_columns.md)
