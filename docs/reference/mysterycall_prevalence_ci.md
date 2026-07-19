# Category Prevalence with Wilson or Clopper-Pearson Intervals

Descriptive per-category proportions with interval estimates suited to
small audit samples – the appropriate output for "% of calls in each
category" when the GLMM machinery is unwarranted. Optionally computes
the intervals within a grouping variable.

## Usage

``` r
mysterycall_prevalence_ci(
  data,
  var,
  group_var = NULL,
  method = c("wilson", "clopper-pearson", "wald"),
  conf_level = 0.95
)
```

## Arguments

- data:

  A data frame.

- var:

  Character scalar. The categorical column to summarise.

- group_var:

  Character scalar or `NULL`. Optional grouping column; when supplied,
  prevalences are computed within each group.

- method:

  Character. `"wilson"` (default), `"clopper-pearson"`, or `"wald"`.

- conf_level:

  Numeric. Interval confidence level. Default `0.95`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns (optional `group`), `category`, `n`, `total`, `proportion`,
`ci_lower`, `ci_upper`, `method`.

## See also

Other categorical:
[`mysterycall_cmh_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cmh_test.md),
[`mysterycall_compare_ranks()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compare_ranks.md),
[`mysterycall_test_categorical()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_categorical.md)

## Examples

``` r
df <- data.frame(
  staff = c(rep("pharmacist", 55), rep("technician", 30), rep("other", 15))
)
mysterycall_prevalence_ci(df, "staff")
#> # A tibble: 3 × 7
#>   category       n total proportion ci_lower ci_upper method
#>   <chr>      <int> <int>      <dbl>    <dbl>    <dbl> <chr> 
#> 1 other         15   100       0.15    0.093    0.233 wilson
#> 2 pharmacist    55   100       0.55    0.452    0.644 wilson
#> 3 technician    30   100       0.3     0.219    0.396 wilson
```
