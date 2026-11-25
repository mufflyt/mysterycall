# Weighted token similarity for organization names

Computes weighted overlap divided by the size of the unweighted token
union: distinctive shared tokens count `1`, generic institutional tokens
count `generic_weight`. The denominator is deliberately unweighted so
adding more generic words cannot make two sparse names look similar.
Missing or blank names score `0`; absence is not positive evidence.

## Usage

``` r
mysterycall_weighted_token_similarity(
  a,
  b,
  generic_tokens = MYSTERYCALL_GENERIC_ORG_TOKENS,
  generic_weight = 0.25
)
```

## Arguments

- a, b:

  Character vectors of organization names. Equal lengths or scalar
  broadcasting are accepted; other length mismatches error.

- generic_tokens:

  Character vector of tokens to downweight.

- generic_weight:

  Numeric scalar in `[0, 1]` for generic shared tokens.

## Value

Numeric vector of similarities in `[0, 1]`.

## Examples

``` r
mysterycall_weighted_token_similarity(
  "Rose Medical Center",
  "Rose Medical Center Denver"
)
#> [1] 0.375
```
