# Remove Near-Zero Variance Variables from a Data Frame

This function takes a data frame and returns a new data frame with
near-zero variance variables removed.

## Usage

``` r
mysterycall_remove_near_zero(data_frame, freqCut = 19, uniqueCut = 10)
```

## Arguments

- data_frame:

  A data frame from which near-zero variance variables should be
  removed.

- freqCut:

  The ratio of the most common value to the second most common value.
  Defaults to 19.

- uniqueCut:

  The percentage of distinct values out of the number of total samples.
  Defaults to 10.

## Value

A data frame with the same row count as `data_frame`, but with near-zero
variance columns removed. Returns `data_frame` unchanged when it is
empty or no near-zero variance columns are found.

## See also

[`mysterycall_remove_constants()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_remove_constants.md)
to drop columns where every value is identical;
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md)
for pre-processing data quality checks.

Other data quality:
[`mysterycall_not_contacted_states()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_not_contacted_states.md),
[`mysterycall_remove_constants()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_remove_constants.md),
[`mysterycall_validate_phone()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_phone.md)

## Examples

``` r
if (FALSE) { # interactive()
df <- data.frame(a = 1:20, b = c(rep(1, 19), 2))
mysterycall_remove_near_zero(df)
}
```
