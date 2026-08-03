# Extract 5-Digit ZIP Code

Extracts the first 5 digits from a ZIP code string, handling ZIP+4
formats and various input types.

## Usage

``` r
mysterycall_normalize_zip5(zip)
```

## Arguments

- zip:

  Character or numeric vector of ZIP code strings.

## Value

Character vector of 5-digit ZIP codes, or `NA_character_` for inputs
that contain no 5-digit sequence. Length-0 input returns `character(0)`.

## See also

[`mysterycall_clean_zip()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_zip.md)
and
[`mysterycall_extract_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_zip5.md)
for the general-purpose ZIP cleaners outside the address-normalization
pipeline.

Other address-normalization:
[`map_token()`](https://mufflyt.github.io/mysterycall/reference/map_token.md),
[`mysterycall_ascii_norm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ascii_norm.md),
[`mysterycall_caps()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caps.md),
[`mysterycall_has_street_number()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_has_street_number.md),
[`mysterycall_is_po_box()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_is_po_box.md),
[`mysterycall_normalize_address_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_address_df.md),
[`mysterycall_normalize_directionals()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_directionals.md),
[`mysterycall_normalize_state()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_state.md),
[`mysterycall_normalize_suffix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_suffix.md),
[`mysterycall_normalize_units()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_units.md),
[`mysterycall_strip_suite()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strip_suite.md)

## Examples

``` r
mysterycall:::mysterycall_normalize_zip5("80111-1234")
#> [1] "80111"
mysterycall:::mysterycall_normalize_zip5(90210)
#> [1] "90210"
```
