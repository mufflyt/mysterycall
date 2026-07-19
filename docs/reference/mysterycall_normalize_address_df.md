# Normalize All Address Fields in a Data Frame

Applies comprehensive USPS normalization to all address fields in a data
frame: ASCII normalization, directional standardization, suffix
standardization, unit normalization, state code conversion, and ZIP
extraction.

## Usage

``` r
mysterycall_normalize_address_df(
  df,
  addr1_col = "practice_address1",
  addr2_col = "practice_address2",
  city_col = "practice_city",
  state_col = "practice_state",
  zip_col = "practice_zip"
)
```

## Arguments

- df:

  Data frame containing address columns.

- addr1_col:

  Character name of the primary address column. Default:
  `"practice_address1"`.

- addr2_col:

  Character name of the secondary address column. Default:
  `"practice_address2"`.

- city_col:

  Character name of the city column. Default: `"practice_city"`.

- state_col:

  Character name of the state column. Default: `"practice_state"`.

- zip_col:

  Character name of the ZIP code column. Default: `"practice_zip"`.

## Value

The input data frame with the original address columns normalized
in-place plus five new derived columns:

- `address1_norm`:

  Character. Fully normalized primary address (ASCII, directionals,
  suffixes, and units standardized).

- `address2_norm`:

  Character or `NA_character_`. Normalized secondary address.

- `address1_no_unit`:

  Character. Primary address with all unit designators stripped.

- `is_po_box`:

  Logical. `TRUE` if the address matches a PO Box pattern.

- `has_num`:

  Logical. `TRUE` if the address begins with a street number.

## See also

Other address-normalization:
[`map_token()`](https://mufflyt.github.io/mysterycall/reference/map_token.md),
[`mysterycall_ascii_norm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ascii_norm.md),
[`mysterycall_caps()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caps.md),
[`mysterycall_has_street_number()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_has_street_number.md),
[`mysterycall_is_po_box()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_is_po_box.md),
[`mysterycall_normalize_directionals()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_directionals.md),
[`mysterycall_normalize_state()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_state.md),
[`mysterycall_normalize_suffix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_suffix.md),
[`mysterycall_normalize_units()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_units.md),
[`mysterycall_normalize_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_zip5.md),
[`mysterycall_strip_suite()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strip_suite.md)

## Examples

``` r
df <- data.frame(
  practice_address1 = c("123 North Main Street Suite 100", "456 Oak Avenue"),
  practice_address2 = c(NA, "Apartment 4B"),
  practice_city     = c("Denver", "Los Angeles"),
  practice_state    = c("Colorado", "CA"),
  practice_zip      = c("80111-1234", "90210"),
  stringsAsFactors  = FALSE
)
mysterycall:::mysterycall_normalize_address_df(df)
#> # A tibble: 2 × 10
#>   practice_address1  practice_address2 practice_city practice_state practice_zip
#>   <chr>              <chr>             <chr>         <chr>          <chr>       
#> 1 123 North Main St… NA                DENVER        CO             80111       
#> 2 456 Oak Avenue     Apartment 4B      LOS ANGELES   CA             90210       
#> # ℹ 5 more variables: address1_norm <chr>, address2_norm <chr>,
#> #   address1_no_unit <chr>, is_po_box <lgl>, has_num <lgl>
```
