# Normalize an organization / practice name for matching

Practice and organization names arrive spelled a dozen ways – mixed
case, curly apostrophes, `&` vs `and`, trailing `LLC`/`PC`/`PA`, stray
punctuation – which defeats exact joins when you try to match a caller
cohort against an external roster (CMS, NPPES, an ownership reference, a
prior wave). This collapses those variants to a single canonical form so
equal organizations compare equal: it upper-cases, replaces `&` with
`AND`, strips punctuation to single spaces, drops common legal-entity
suffixes, and squishes whitespace.

## Usage

``` r
mysterycall_normalize_org_name(
  x,
  drop_suffixes = c("THE", "LLC", "PLLC", "PC", "PA", "LP", "LLP", "INC", "CORP",
    "CORPORATION", "CO", "LTD", "MD", "DO"),
  expand_ampersand = TRUE
)
```

## Arguments

- x:

  A character vector (or coerced to one) of organization names. `NA`
  becomes `""`.

- drop_suffixes:

  Character vector of whole-word tokens to remove (legal entity types
  and credential suffixes). Matched case-insensitively as whole words
  after upper-casing. Defaults to the common US set. Pass `character(0)`
  to keep them.

- expand_ampersand:

  If `TRUE` (default) replace `&` with `AND`.

## Value

A character vector the length of `x` of normalized names.

## Details

It is deliberately conservative – it does not stem words or fuzzy-match,
so two genuinely different practices stay different. Use it to build a
join key, then match on that key (optionally with your own alias/regex
table on top).

## See also

[`mysterycall_normalize_address_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_address_df.md),
[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md)

## Examples

``` r
mysterycall_normalize_org_name(c(
  "Women's Health Specialists, LLC",
  "Womens Health Specialists PC",
  "Rocky Mountain OB & GYN, P.A."
))
#> [1] "WOMENS HEALTH SPECIALISTS" "WOMENS HEALTH SPECIALISTS"
#> [3] "ROCKY MOUNTAIN OB AND GYN"
# -> "WOMENS HEALTH SPECIALISTS", "WOMENS HEALTH SPECIALISTS",
#    "ROCKY MOUNTAIN OB AND GYN"
```
