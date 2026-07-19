# Validate NPI numbers using the official CMS Luhn checksum

Implements the CMS-specified Luhn algorithm for 10-digit National
Provider Identifiers (NPI). The CMS prepends the constant "80840" to the
NPI before computing the checksum, so this is not a generic Luhn check.

## Usage

``` r
mysterycall_luhn_check(npi)
```

## Arguments

- npi:

  Character or numeric vector of NPI values. Non-10-digit values (after
  coercing to character) are immediately invalid.

## Value

Logical vector the same length as `npi`. `TRUE` means the NPI passes the
CMS Luhn checksum; `FALSE` means it does not or is malformed. `NA`
inputs return `FALSE`.

## See also

[`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md)
for row-level NPI validation with filtering;
[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md)
to retrieve clinician detail records for validated NPIs.

Other data management:
[`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md),
[`mysterycall_check_generalist_presence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_generalist_presence.md),
[`mysterycall_extract_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_zip5.md),
[`mysterycall_merge_with_prefix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_merge_with_prefix.md),
[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md),
[`mysterycall_rename_columns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_rename_columns.md),
[`mysterycall_stratified_sample()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_stratified_sample.md)

## Examples

``` r
mysterycall:::mysterycall_luhn_check(c("1234567893", "9999999999", NA))
#> [1]  TRUE FALSE FALSE
# Filter a data frame to valid NPIs:
# df[mysterycall_luhn_check(df$npi), ]
```
