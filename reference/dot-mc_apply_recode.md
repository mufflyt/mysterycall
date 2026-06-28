# Apply a named character recode map to a vector

Replaces elements of `x` whose value matches `names(map)` with the
corresponding element of `map`. Non-matching values are left unchanged.

## Usage

``` r
.mc_apply_recode(x, map)
```

## Arguments

- x:

  Character (or factor) vector to recode.

- map:

  Named character vector: `c("old_val" = "new_val", ...)`.

## Value

    Character vector the same length as `x`.
