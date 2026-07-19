# Calculate the Minimum Value(s) and Corresponding Level(s) of a Factor Variable

This function returns the level(s) corresponding to the minimum value(s)
of a factor variable.

## Usage

``` r
mysterycall_min_table(InVec, mult = FALSE)
```

## Arguments

- InVec:

  A vector or factor. Non-factor inputs are coerced to factor via
  [`factor()`](https://rdrr.io/r/base/factor.html). The function counts
  occurrences of each resulting level.

- mult:

  Logical scalar. If `TRUE`, all levels tied for the minimum count are
  returned. If `FALSE` (default), only the first such level is returned
  (via [`which.min()`](https://rdrr.io/r/base/which.min.html)).

## Value

Character scalar (`mult = FALSE`) or character vector (`mult = TRUE`) of
the factor level(s) with the minimum frequency. Returns `character(0)`
for a zero-length input.

## See also

[`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md)

Other table helpers:
[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md),
[`mysterycall_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_pct.md),
[`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md),
[`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md),
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md),
[`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md),
[`print.mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_disparities_table.md)

## Examples

``` r
vec <- factor(c("A", "B", "A", "C", "B", "B"))
mysterycall_min_table(vec)           # "C"
#> [1] "C"
mysterycall_min_table(vec, mult = TRUE)  # "C"
#> [1] "C"
```
