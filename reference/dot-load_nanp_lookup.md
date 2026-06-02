# Load NANP Area Code Lookup Table

Loads and caches the mapping between US area codes and states.

## Usage

``` r
.load_nanp_lookup(nanp_path = NULL)
```

## Arguments

- nanp_path:

  Optional path to custom NANP CSV.

## Value

Data frame with `area_code` and `state` columns.

## See also

Other validation:
[`.audit_volatile_fields`](https://mufflyt.github.io/mysterycall/reference/dot-audit_volatile_fields.md),
[`validate_dataframe()`](https://mufflyt.github.io/mysterycall/reference/validate_dataframe.md),
[`validate_required_columns()`](https://mufflyt.github.io/mysterycall/reference/validate_required_columns.md),
[`validate_scalar_positive_numeric()`](https://mufflyt.github.io/mysterycall/reference/validate_scalar_positive_numeric.md)
