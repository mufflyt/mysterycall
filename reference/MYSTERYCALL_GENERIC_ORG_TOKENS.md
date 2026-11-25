# Generic organization tokens used in weighted matching

These words are common in hospital and practice names and therefore
carry less identity evidence than distinctive proper nouns. The vector
is exported so callers can inspect the default, extend it for a local
vocabulary, or pass a replacement vector to the org-token helpers.

## Usage

``` r
MYSTERYCALL_GENERIC_ORG_TOKENS
```

## Format

A character vector of upper-case normalized tokens.
