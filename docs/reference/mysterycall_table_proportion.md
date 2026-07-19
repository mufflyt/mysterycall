# Calculate the Proportion of Each Level in a Categorical Variable

This function calculates the proportion of each level in a specified
categorical variable within a data frame. It returns a data frame with
the counts and percentages of each level.

## Usage

``` r
mysterycall_table_proportion(data, variable_name)
```

## Arguments

- data:

  A data frame containing the categorical variable.

- variable_name:

  The name of the categorical variable for which proportions are
  calculated, passed as an unquoted expression.

## Value

A data frame with one row per unique non-missing level of
`variable_name`. Columns: the variable itself, `n` (count), and
`percent` (percentage of total, rounded to 2 decimal places).

## Details

`variable_name` uses tidy evaluation (`{{ }}`), so pass the column name
unquoted (e.g. `mysterycall_table_proportion(df, gender)`). Use
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md)
when you have the column name as a string.

## See also

[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md)
for the string-based equivalent;
[`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md),
[`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md)
for single-value mode/anti-mode queries.

Other table helpers:
[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md),
[`mysterycall_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_pct.md),
[`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md),
[`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md),
[`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md),
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md),
[`print.mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_disparities_table.md)

## Examples

``` r
# Example 1: Basic usage with a simple dataset
data <- data.frame(gender = c("Male", "Female", "Female", "Male", "Male", "Female"))
result <- mysterycall_table_proportion(data, gender)
print(result)
#>   gender n percent
#> 1 Female 3      50
#> 2   Male 3      50

# Example 2: Handling a dataset with missing values
df_na <- data.frame(gender = c("Male", NA, "Female", "Female", "Male", "Female", NA))
result <- mysterycall_table_proportion(df_na, gender)
print(result)
#>   gender n percent
#> 1 Female 3      60
#> 2   Male 2      40

# Example 3: Using a variable with multiple levels
df_multi <- data.frame(grade = c("A", "B", "A", "C", "B", "A", "C", "B"))
result <- mysterycall_table_proportion(df_multi, grade)
print(result)
#>   grade n percent
#> 1     A 3    37.5
#> 2     B 3    37.5
#> 3     C 2    25.0
```
