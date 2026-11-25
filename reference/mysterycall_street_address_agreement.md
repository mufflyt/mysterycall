# Compare two street addresses

`mysterycall_street_address_agreement()` compares two character scalars
or two keys from
[`mysterycall_street_address_key()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_street_address_key.md).
A missing, blank, PO-box, or numberless address is `uninformative`; it
neither corroborates nor vetoes a match. Different leading street
numbers conflict. Equal numbers corroborate only when the normalized
strings are identical or at least one non-suffix street token is shared.

## Usage

``` r
mysterycall_street_address_agreement(a, b)

mysterycall_street_addresses_agree(a, b)
```

## Arguments

- a, b:

  Character scalar street addresses, or keys produced by
  [`mysterycall_street_address_key()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_street_address_key.md).

## Value

`mysterycall_street_address_agreement()` returns a one-row data frame
with `verdict` and `reason`. `mysterycall_street_addresses_agree()`
returns `TRUE` only when the verdict is `corroborates`.

## Examples

``` r
mysterycall_street_address_agreement(
  "123 Main Street Suite 200",
  "123 N Main St"
)
#>        verdict                  reason
#> 1 corroborates street_number_and_token
mysterycall_street_addresses_agree("123 Main St", "123 Oak St")
#> [1] FALSE
```
