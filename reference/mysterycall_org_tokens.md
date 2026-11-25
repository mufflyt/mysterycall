# Tokenize organization names for evidence comparison

Normalizes names with
[`mysterycall_normalize_org_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_org_name.md),
drops function words and legal-entity suffixes, and returns unique
upper-case tokens. Generic institutional words are retained; they are
downweighted by
[`mysterycall_weighted_token_similarity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_weighted_token_similarity.md)
rather than deleted, because deleting them can make distinct health
systems collapse to the same key.

## Usage

``` r
mysterycall_org_tokens(x)
```

## Arguments

- x:

  Character vector of organization names.

## Value

A list of unique character-token vectors, one per input element.

## Examples

``` r
mysterycall_org_tokens("University of Colorado Hospital, LLC")
#> [[1]]
#> [1] "UNIVERSITY" "COLORADO"   "HOSPITAL"  
#> 
```
