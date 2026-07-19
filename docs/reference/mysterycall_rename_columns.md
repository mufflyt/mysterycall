# Rename columns by substring match

For each `target_strings[i]`, finds the first column whose name contains
that substring and renames it to `new_names[i]`. When multiple columns
match, the first match is used and a warning is issued. When no column
matches, a message is emitted and that rename is skipped.

## Usage

``` r
mysterycall_rename_columns(data, target_strings, new_names)
```

## Arguments

- data:

  A data frame whose columns need renaming.

- target_strings:

  Character vector of substrings to search for within column names. Must
  be the same length as `new_names`.

- new_names:

  Character vector of replacement column names, aligned with
  `target_strings`.

## Value

A data frame with matched columns renamed. Unmatched targets are
silently skipped; a warning is issued when multiple columns match.

## See also

Other data management:
[`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md),
[`mysterycall_check_generalist_presence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_generalist_presence.md),
[`mysterycall_extract_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_zip5.md),
[`mysterycall_luhn_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_luhn_check.md),
[`mysterycall_merge_with_prefix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_merge_with_prefix.md),
[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md),
[`mysterycall_stratified_sample()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_stratified_sample.md)

## Examples

``` r
df <- data.frame(
  doctor_info = 1:5,
  patient_contact_data = 6:10
)
# Renaming 'doctor_info' to 'physician_info'
df <- mysterycall_rename_columns(df,
                                  target_strings = c("doctor"),
                                  new_names = c("physician_info"))
#> --- Starting to search and rename columns based on target substrings ---
#> Matched 1 column(s) by substring match for 'doctor': doctor_info
#> Renamed 'doctor_info' to 'physician_info'.
#> 
#> --- Column renaming complete. Final column set: physician_info, patient_contact_data ---
print(df)
#>   physician_info patient_contact_data
#> 1              1                    6
#> 2              2                    7
#> 3              3                    8
#> 4              4                    9
#> 5              5                   10

# More complex example with multiple renamings
df <- data.frame(
  doc_information = 1:5,
  patient_contact = 6:10,
  doctor_notes = 11:15
)
# Renaming 'doc_information' to 'doctor_info' and 'doctor_notes' to 'notes'
df <- mysterycall_rename_columns(df,
                                  target_strings = c("doc_information", "doctor_notes"),
                                  new_names = c("doctor_info", "notes"))
#> --- Starting to search and rename columns based on target substrings ---
#> Matched 1 column(s) by exact match for 'doc_information': doc_information
#> Renamed 'doc_information' to 'doctor_info'.
#> 
#> Matched 1 column(s) by exact match for 'doctor_notes': doctor_notes
#> Renamed 'doctor_notes' to 'notes'.
#> 
#> --- Column renaming complete. Final column set: doctor_info, patient_contact, notes ---
print(df)
#>   doctor_info patient_contact notes
#> 1           1               6    11
#> 2           2               7    12
#> 3           3               8    13
#> 4           4               9    14
#> 5           5              10    15
```
