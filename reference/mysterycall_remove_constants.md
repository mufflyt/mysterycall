# Remove Constant Variables from a Data Frame

This function takes a data frame and returns a new data frame with
constant variables removed.

## Usage

``` r
mysterycall_remove_constants(data_frame)
```

## Arguments

- data_frame:

  A data frame from which constant variables should be removed.

## Value

A data frame with the same row count as `data_frame` but with
zero-variance columns (all values identical after coercion to character)
removed. Returns `data_frame` unchanged when it is empty or has no
constant columns.

## See also

[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md)
to audit data quality before removal;
[`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md)
for missingness scoring.

Other data quality:
[`mysterycall_not_contacted_states()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_not_contacted_states.md),
[`mysterycall_remove_near_zero()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_remove_near_zero.md),
[`mysterycall_validate_phone()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_phone.md)

## Examples

``` r
df <- data.frame(a = 1:3, b = c(5, 5, 5), c = c("x", "y", "z"))
mysterycall_remove_constants(df)
#> Starting the function to remove constant variables.
#> Identifying constant variables...
#> Found 1 constant variables.
#> Removing constant variables...
#> Function completed.
#>   a c
#> 1 1 x
#> 2 2 y
#> 3 3 z
```
