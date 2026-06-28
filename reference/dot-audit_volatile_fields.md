# Volatile audit fields excluded from artifact_id computation

The canonical list of audit JSON fields that change between runs and are
therefore excluded when computing `artifact_id`. Any field that appears
here must NOT influence the content-addressable identity of an artifact.

## Usage

``` r
.audit_volatile_fields
```

## Format

An object of class `character` of length 7.

## Value

Character vector of field names.

## Details

Keeping this constant in one place ensures that
[`mysterycall_verify_artifact()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_verify_artifact.md)
and
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)
use identical canonicalization logic.

## See also

Other validation:
[`.load_nanp_lookup()`](https://mufflyt.github.io/mysterycall/reference/dot-load_nanp_lookup.md),
[`validate_dataframe()`](https://mufflyt.github.io/mysterycall/reference/validate_dataframe.md),
[`validate_required_columns()`](https://mufflyt.github.io/mysterycall/reference/validate_required_columns.md),
[`validate_scalar_positive_numeric()`](https://mufflyt.github.io/mysterycall/reference/validate_scalar_positive_numeric.md)
