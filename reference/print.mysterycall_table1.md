# Print a mysterycall_table1 object

Prints a formatted Table 1 with column sample sizes in the header and
the underlying tibble displayed via
[`print.tbl_df()`](https://tibble.tidyverse.org/reference/formatting.html).

## Usage

``` r
# S3 method for class 'mysterycall_table1'
print(x, ...)
```

## Arguments

- x:

  A `mysterycall_table1` object returned by
  [`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md).

- ...:

  Additional arguments passed to
  [`print.tbl_df()`](https://tibble.tidyverse.org/reference/formatting.html).

## Value

Invisibly returns `x`.

## See also

[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md)
which produces this object;
[`mysterycall_table1_gtsummary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1_gtsummary.md)
for a publication-ready `gtsummary` alternative.

Other table:
[`.t1_cat_pvalue()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_cat_pvalue.md),
[`.t1_cont_pvalue()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_cont_pvalue.md),
[`.t1_fmt_mean_sd()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_fmt_mean_sd.md),
[`.t1_fmt_median_iqr()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_fmt_median_iqr.md),
[`.t1_fmt_pct()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_fmt_pct.md),
[`.t1_fmt_pval()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_fmt_pval.md),
[`.t1_rows_categorical()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_rows_categorical.md),
[`.t1_rows_continuous()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_rows_continuous.md),
[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md),
[`mysterycall_table1_gtsummary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1_gtsummary.md),
[`mysterycall_table_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_overall.md),
[`mysterycall_write_arsenal_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_arsenal_table.md),
[`mysterycall_write_table_pdf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table_pdf.md)

## Examples

``` r
# \donttest{
df <- data.frame(
  age = c(25, 30, 35, 40),
  sex = c("M", "F", "F", "M")
)
t1 <- mysterycall_table1(df, covariates = c("age", "sex"))
print(t1)
#> Table 1 (Overall N=4)
#> 
#> # A tibble: 4 × 3
#>   variable level        Overall         
#>   <chr>    <chr>        <chr>           
#> 1 age      Median [IQR] 32.5 [28.8-36.2]
#> 2 age      Mean (SD)    32.5 (6.5)      
#> 3 sex      F            2 (50.0%)       
#> 4 sex      M            2 (50.0%)       
# }
```
