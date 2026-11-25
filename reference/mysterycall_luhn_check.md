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
  stripping punctuation/whitespace) are immediately invalid.

## Value

Logical vector the same length as `npi`. `TRUE` means the NPI passes the
CMS Luhn checksum and leading-digit format; `FALSE` means it does not or
is malformed. `NA` inputs return `FALSE` (unlike
[`mysterynpi::npi_luhn_ok()`](https://mufflyt.github.io/mysterynpi/reference/npi_luhn_ok.html),
whose `NA`-in-`NA`-out contract serves a different caller – here absence
must not propagate into
[`filter()`](https://rdrr.io/r/stats/filter.html)).

## Details

THE LEADING DIGIT IS PART OF THE FORMAT. CMS has only ever issued NPIs
beginning with 1 (and reserves 2); roughly one in ten arbitrary 10-digit
strings passes the Luhn checksum by chance, so the checksum alone is a
weak gate – "0103000788" satisfies the checksum yet cannot be an NPI.
This mirrors
[`mysterynpi::npi_luhn_ok()`](https://mufflyt.github.io/mysterynpi/reference/npi_luhn_ok.html),
the ecosystem's canonical implementation; the two must never diverge,
because state provider numbers that happen to satisfy the checksum
otherwise join as phantom NPIs.

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
