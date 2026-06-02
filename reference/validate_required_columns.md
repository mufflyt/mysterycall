# Validate Required Columns in a Data Frame

Validate Required Columns in a Data Frame

## Usage

``` r
validate_required_columns(x, required, name = "data")
```

## Arguments

- x:

  Data frame to check.

- required:

  Character vector of required column names.

- name:

  Character scalar naming the data frame for error messages.

## Value

The validated data frame (invisibly).

## See also

Other validation:
[`.audit_volatile_fields`](https://mufflyt.github.io/mysterycall/reference/dot-audit_volatile_fields.md),
[`.load_nanp_lookup()`](https://mufflyt.github.io/mysterycall/reference/dot-load_nanp_lookup.md),
[`validate_dataframe()`](https://mufflyt.github.io/mysterycall/reference/validate_dataframe.md),
[`validate_scalar_positive_numeric()`](https://mufflyt.github.io/mysterycall/reference/validate_scalar_positive_numeric.md)
