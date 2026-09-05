# Flag physicians called more than the allowed number of times

Returns a subset of `data` containing only rows where the physician
identifier appears more than `max_calls` times, annotated with a
call-count column.

## Usage

``` r
mysterycall_check_duplicates(data, id_col, max_calls = 2L)
```

## Arguments

- data:

  A data frame.

- id_col:

  Character scalar naming the physician-identifier column.

- max_calls:

  Integer. Maximum allowed calls per physician. Physicians appearing
  more than this many times are flagged. Default `2L`.

## Value

A data frame (subset of `data`) with an additional `n_calls` column. An
attribute `"n_flagged"` records the number of unique physicians flagged.

## See also

Other data management:
[`mysterycall_check_generalist_presence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_generalist_presence.md),
[`mysterycall_extract_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_zip5.md),
[`mysterycall_luhn_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_luhn_check.md),
[`mysterycall_merge_with_prefix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_merge_with_prefix.md),
[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md),
[`mysterycall_rename_columns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_rename_columns.md),
[`mysterycall_stratified_sample()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_stratified_sample.md)

## Examples

``` r
df <- data.frame(
  physician_id = c("A", "A", "A", "B", "B", "C"),
  call_date    = Sys.Date() + 0:5
)
mysterycall_check_duplicates(df, id_col = "physician_id", max_calls = 2L)
#>   physician_id  call_date n_calls
#> 1            A 2026-09-05       3
#> 2            A 2026-09-06       3
#> 3            A 2026-09-07       3
```
