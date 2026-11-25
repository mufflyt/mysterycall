# Exact or meaningful-substring organization agreement

Positive evidence only: returns `TRUE` when normalized names are exactly
equal, or when one is a substring of the other and both sides contribute
at least `min_meaningful_tokens` non-generic tokens. Generic-only
substring agreement (for example, two names sharing only UNIVERSITY
MEDICAL CENTER) is not enough. A blank or missing name returns `FALSE`
rather than erroring.

## Usage

``` r
mysterycall_org_names_agree(
  a,
  b,
  min_meaningful_tokens = 2L,
  generic_tokens = MYSTERYCALL_GENERIC_ORG_TOKENS
)
```

## Arguments

- a, b:

  Character vectors of organization names. Equal lengths or scalar
  broadcasting are accepted; other length mismatches error.

- min_meaningful_tokens:

  Integer scalar minimum count of unique non-generic tokens required on
  both sides of a substring match.

- generic_tokens:

  Character vector of tokens to treat as generic.

## Value

Logical vector.

## Examples

``` r
mysterycall_org_names_agree(
  "Rose Medical Center Denver",
  "Rose Medical Center Denver Hospital"
)
#> [1] TRUE
mysterycall_org_names_agree(
  "University Medical Center",
  "University Medical Center Hospital"
)
#> [1] FALSE
```
