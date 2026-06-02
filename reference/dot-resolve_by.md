# Resolve Join Keys

Resolves `by` to a list(left = char, right = char) for both named and
unnamed character vectors and dplyr::join_by() objects.

## Usage

``` r
.resolve_by(by)
```

## Arguments

- by:

  Character vector or dplyr::join_by object.

## Value

A named list with "left" and "right" character vectors.
