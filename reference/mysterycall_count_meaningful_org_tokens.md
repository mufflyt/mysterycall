# Count non-generic organization tokens

Count non-generic organization tokens

## Usage

``` r
mysterycall_count_meaningful_org_tokens(
  x,
  generic_tokens = MYSTERYCALL_GENERIC_ORG_TOKENS
)
```

## Arguments

- x:

  Character vector of organization names.

- generic_tokens:

  Character vector of tokens to treat as generic.

## Value

Integer vector of counts of unique non-generic tokens.

## Examples

``` r
mysterycall_count_meaningful_org_tokens("University Medical Center")
#> [1] 0
mysterycall_count_meaningful_org_tokens("Rose Medical Center")
#> [1] 1
```
