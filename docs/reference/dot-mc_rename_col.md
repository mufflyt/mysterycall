# Rename a single column in a data frame (base R, no side-effects)

Rename a single column in a data frame (base R, no side-effects)

## Usage

``` r
.mc_rename_col(data, old, new)
```

## Arguments

- data:

  A data frame.

- old:

  Current column name (character scalar).

- new:

  Desired column name (character scalar).

## Value

      The data frame with the column renamed, or unchanged if `old`

is `NULL`, `NA`, or not present.
