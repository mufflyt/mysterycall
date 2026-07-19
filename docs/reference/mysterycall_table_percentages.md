# Most frequent level(s) of a categorical variable with percentage

Counts each level of a categorical variable, computes its share of all
rows (including `NA`), and returns **only the level(s) with the highest
count**. When multiple levels tie for the top count, all tied levels are
returned. `NA` values are counted as their own level and included in the
denominator.

## Usage

``` r
mysterycall_table_percentages(data_frame, variable)
```

## Arguments

- data_frame:

  A data frame containing the categorical variable.

- variable:

  A character string giving the column name of the categorical variable
  within `data_frame`.

## Value

A data frame with one row per level tied for the highest count. Columns:
the variable itself, `n` (count), and `percent` (exact percentage of
non-missing rows, not rounded).

## See also

[`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md),
[`mysterycall_most_common_gender()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_most_common_gender.md),
[`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md),
[`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md)

Other table helpers:
[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md),
[`mysterycall_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_pct.md),
[`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md),
[`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md),
[`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md),
[`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md),
[`print.mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_disparities_table.md)

## Examples

``` r
# "A" is most frequent: returns 1 row
data_frame <- data.frame(category = c("A", "B", "A", "C", "A", "B", "B", "A"))
mysterycall_table_percentages(data_frame, "category")
#>   category n percent
#> 1        A 4      50

# Three-way tie: all three returned
df_tie <- data.frame(category = c("A", "B", "A", "B", "C", "C", "C", "A", "B"))
mysterycall_table_percentages(df_tie, "category")
#>   category n  percent
#> 1        A 3 33.33333
#> 2        B 3 33.33333
#> 3        C 3 33.33333

# NAs are counted as their own level; denominator includes all rows
df_na <- data.frame(category = c("A", NA, "A", "C", "A", "B", "B", NA))
mysterycall_table_percentages(df_na, "category")
#>   category n percent
#> 1        A 3    37.5
```
