# Format a Numeric Value as a Percentage

This function formats a numeric value as a percentage with a specified
number of decimal places.

## Usage

``` r
mysterycall_format_pct(x, digits = 1)
```

## Arguments

- x:

  A numeric value or vector that you want to format as a percentage.

- digits:

  An integer specifying the number of decimal places to include in the
  formatted percentage. The default is 1.

## Value

A character vector representing the formatted percentage(s) with the
specified number of decimal places.

## Details

Uses `formatC(format = "f")` so trailing zeros are always preserved,
ensuring values like `10.0%` align correctly in fixed-width output.

## See also

Other table helpers:
[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md),
[`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md),
[`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md),
[`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md),
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md),
[`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md),
[`print.mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_disparities_table.md)

## Examples

``` r
# Example 1: Format a single numeric value
result <- mysterycall_format_pct(0.12345)
print(result)  # Output: "12.3%"
#> [1] "12.3%"

# Example 2: Format a vector of numeric values with 2 decimal places
values <- c(0.12345, 0.6789, 0.54321)
formatted_values <- mysterycall_format_pct(values, digits = 2)
print(formatted_values)  # Output: "12.35%", "67.89%", "54.32%"
#> [1] "12.35%" "67.89%" "54.32%"

# Example 3: Format a value with no decimal places
no_decimal <- mysterycall_format_pct(0.5, digits = 0)
print(no_decimal)  # Output: "50%"
#> [1] "50%"
```
