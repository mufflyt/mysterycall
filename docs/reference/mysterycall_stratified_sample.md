# Draw a balanced stratified sample from a data frame

Samples exactly `n_per_group` rows from each level of `group_col`.
Groups with fewer than `n_per_group` rows are returned in full.

## Usage

``` r
mysterycall_stratified_sample(data, group_col, n_per_group, seed = NULL)
```

## Arguments

- data:

  A data frame.

- group_col:

  Character scalar naming the stratification column.

- n_per_group:

  Integer. Target sample size per group.

- seed:

  Optional integer random seed for reproducibility.

## Value

A data frame with rows in original row-number order.

## See also

Other data management:
[`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md),
[`mysterycall_check_generalist_presence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_generalist_presence.md),
[`mysterycall_extract_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_zip5.md),
[`mysterycall_luhn_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_luhn_check.md),
[`mysterycall_merge_with_prefix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_merge_with_prefix.md),
[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md),
[`mysterycall_rename_columns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_rename_columns.md)

## Examples

``` r
df <- data.frame(
  specialty = rep(c("Otolaryngology", "Urology", "Dermatology"), c(100, 80, 60)),
  x         = rnorm(240)
)
out <- mysterycall_stratified_sample(df, group_col = "specialty",
                                     n_per_group = 30L, seed = 42L)
table(out$specialty)
#> 
#>    Dermatology Otolaryngology        Urology 
#>             30             30             30 
```
