# Street-address keys and agreement verdicts

These functions turn a free-text US street address into the parts that
are safe to compare – a normalized string, a leading street number, and
the non-suffix street tokens – then compare two addresses without
treating a missing address as evidence. Unit designators are removed
before tokenization because physicians and facilities often record the
same street address with different suite, floor, room, or department
detail.

## Usage

``` r
mysterycall_street_address_key(address)
```

## Arguments

- address:

  Character scalar street address. `NA` and blank input return an empty
  key rather than erroring.

## Value

`mysterycall_street_address_key()` returns a named list with
`normalized`, `street_number`, `street_tokens`, `is_po_box`, and
`has_num`. `street_tokens` excludes roadway suffix tokens (ST, AVE, RD,
and the other USPS suffix abbreviations) so `"123 Main St"` cannot match
`"123 Oak St"` merely because both are streets.

## Details

`mysterycall_street_address_key()` is scalar because a key is the input
to one comparison.
[`mysterycall_street_address_agreement()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_street_address_agreement.md)
returns the shared three-verdict vocabulary (`corroborates`,
`conflicts`, `uninformative`) plus a named reason;
[`mysterycall_street_addresses_agree()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_street_address_agreement.md)
is the logical positive-evidence wrapper for callers that only need
"does this corroborate the same street address?".

## Examples

``` r
key <- mysterycall_street_address_key("123 North Main Street Suite 400")
key$street_number
#> [1] "123"
key$street_tokens
#> [1] "N"    "MAIN"
```
