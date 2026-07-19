# Calculate the Maximum Value(s) and Corresponding Level(s) of a Factor Variable

This function returns the level(s) corresponding to the maximum value(s)
of a factor variable.

## Usage

``` r
mysterycall_max_table(InVec, mult = FALSE)
```

## Arguments

- InVec:

  Input vector, expected to be a factor variable or convertible to a
  factor.

- mult:

  Logical value indicating whether to return multiple maximum values or
  just the first one. Default is FALSE.

## Value

Character scalar (`mult = FALSE`) or character vector (`mult = TRUE`)
containing the factor level(s) with the maximum frequency. Returns
`character(0)` for a zero-length input.

## See also

[`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md)

Other table helpers:
[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md),
[`mysterycall_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_pct.md),
[`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md),
[`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md),
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md),
[`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md),
[`print.mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_disparities_table.md)

## Examples

``` r
vec <- factor(c("A", "B", "A", "C", "B", "B"))
mysterycall_max_table(vec)           # "B"
#> [1] "B"
mysterycall_max_table(vec, mult = TRUE)  # "B"
#> [1] "B"
```
