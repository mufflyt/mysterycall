# Retrieve Clinician Data

Retrieves clinician data from the `provider` package for each valid NPI
in the input. Accepts either a data frame with an `npi` column or a path
to a CSV file. Invalid NPIs are filtered out via
[`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md)
before any API calls are made.

## Usage

``` r
mysterycall_get_clinician_data(input_data)
```

## Arguments

- input_data:

  A data frame with an `npi` column, or a character scalar path to a CSV
  file that contains an `npi` column.

## Value

A tibble with one row per valid NPI and columns from
`provider::clinicians()` (name, specialty, address, etc.), plus an
`npi_is_valid` column. Returns a zero-row tibble when no valid NPIs are
found. Returns `NULL` silently per NPI when the `provider` package is
not installed.

## Subspecialty source warning

The `taxonomies_desc` column in the returned tibble reflects NPPES
taxonomy codes (broad specialty groupings from the NPI registry). **Do
not use `taxonomies_desc` to assign subspecialty.** NPPES does not
reliably distinguish subspecialties such as Neurotology or Pediatric
Otolaryngology. Subspecialty must be derived exclusively from board
certification data using
[`mysterycall_parse_certification_subspecialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_certification_subspecialty.md)
and reconciled via
[`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md).

## See also

[`mysterycall_luhn_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_luhn_check.md)
to validate NPI checksums;
[`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md)
for row-level NPI filtering;
[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md)
to attach clinician data to a roster.

Other npi:
[`mysterycall_enrich_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_enrich_npi.md),
[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md),
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)

## Examples

``` r
if (FALSE) { # interactive()
clinician_df <- mysterycall_get_clinician_data("clinicians.csv")
}
```
