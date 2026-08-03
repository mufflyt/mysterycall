# Extract a clean 5-digit ZIP code from a dirty string

Strips all non-digit characters, validates minimum length, takes the
first five digits, and left-pads with zeros if fewer than five digits
remain. Returns `NA_character_` for inputs that cannot be parsed into a
plausible ZIP code.

## Usage

``` r
mysterycall_extract_zip5(x)
```

## Arguments

- x:

  Character vector of raw ZIP/postal-code strings (e.g. `"80203"`,
  `"80203-1234"`, `" 80203 "`, `"8020"` -\> `"08020"`).

## Value

Character vector the same length as `x`. Each element is a 5-character
string of digits or `NA_character_`.

## See also

[`mysterycall_clean_zip()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_zip.md)
for the exported ZIP cleaner (also splits multi-ZIP cells);
[`mysterycall_normalize_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_zip5.md)
for the address-pipeline variant.

Other data management:
[`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md),
[`mysterycall_check_generalist_presence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_generalist_presence.md),
[`mysterycall_luhn_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_luhn_check.md),
[`mysterycall_merge_with_prefix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_merge_with_prefix.md),
[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md),
[`mysterycall_rename_columns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_rename_columns.md),
[`mysterycall_stratified_sample()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_stratified_sample.md)

## Examples

``` r
mysterycall:::mysterycall_extract_zip5(c("80203-1234", " 80203 ", "8020", "abc", NA))
#> [1] "80203" "80203" "08020" NA      NA     
```
