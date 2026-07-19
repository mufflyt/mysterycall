# Normalize State Names to USPS Codes

Converts full state names to their two-letter USPS codes. If the input
is already a valid two-letter code, it is returned unchanged.

## Usage

``` r
mysterycall_normalize_state(state)
```

## Arguments

- state:

  Character vector of state names or abbreviations.

## Value

Character vector of two-letter USPS state codes.

## See also

Other address-normalization:
[`map_token()`](https://mufflyt.github.io/mysterycall/reference/map_token.md),
[`mysterycall_ascii_norm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ascii_norm.md),
[`mysterycall_caps()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caps.md),
[`mysterycall_has_street_number()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_has_street_number.md),
[`mysterycall_is_po_box()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_is_po_box.md),
[`mysterycall_normalize_address_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_address_df.md),
[`mysterycall_normalize_directionals()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_directionals.md),
[`mysterycall_normalize_suffix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_suffix.md),
[`mysterycall_normalize_units()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_units.md),
[`mysterycall_normalize_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_zip5.md),
[`mysterycall_strip_suite()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strip_suite.md)

## Examples

``` r
mysterycall:::mysterycall_normalize_state("California")
#> [1] "CA"
mysterycall:::mysterycall_normalize_state("NY")
#> [1] "NY"
```
