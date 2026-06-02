# Build a Table 1 for mystery caller studies

Produces a publication-ready summary table describing physician and
study characteristics, optionally stratified by a grouping variable
(typically `"insurance"`). Continuous variables are summarised with
median \[IQR\] and/or mean (SD); categorical variables with n (%).
Statistical tests are chosen automatically: Wilcoxon rank-sum or
Kruskal-Wallis for continuous variables, chi-square or Fisher's exact
for categorical.

## Usage

``` r
mysterycall_table1(
  data,
  covariates,
  stratify_by = NULL,
  include_overall = TRUE,
  cont_stats = c("median_iqr", "mean_sd"),
  digits = 1L,
  p_value = TRUE,
  min_cell = 5L,
  variable_labels = NULL
)
```

## Arguments

- data:

  A data frame, typically the output of
  [`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)
  merged with genderize results.

- covariates:

  Character vector of column names to include as rows. Numeric columns
  are treated as continuous; all others are categorical.

- stratify_by:

  Optional single column name used as the stratifying variable (e.g.
  `"insurance"`). When `NULL` (default) a single Overall column is
  produced with no hypothesis tests.

- include_overall:

  Logical. When `TRUE` (default) an Overall column is included even when
  `stratify_by` is set.

- cont_stats:

  Character vector controlling which statistics are shown for numeric
  variables. Valid choices are `"median_iqr"` (default, first) and
  `"mean_sd"`. Both can be supplied to show two rows per variable.

- digits:

  Number of decimal places for continuous statistics and percentages.
  Default `1`.

- p_value:

  Logical. When `TRUE` (default) and `stratify_by` is set, a `p_value`
  column is appended (Wilcoxon/Kruskal-Wallis for continuous,
  chi-square/Fisher's exact for categorical).

- min_cell:

  Minimum expected cell count below which Fisher's exact test is used
  instead of chi-square (2-group categorical only). Default `5`.

- variable_labels:

  Optional named character vector mapping column names to display
  labels, e.g. `c(wait_days = "Wait time (days)")`. Unlabelled columns
  use their column name.

## Value

A list of class `mysterycall_table1` with:

- `table`:

  Tibble with columns `variable`, `level`, `Overall` (if
  `include_overall`), one column per stratum, and `p_value` (if
  `p_value = TRUE` and stratified). Each row is one statistic or one
  category level.

- `column_ns`:

  Named integer vector of sample sizes per column.

- `stratify_by`:

  The name of the stratifying column, or `NULL`.

- `n`:

  Total rows in `data`.

## See also

[`mysterycall_table1_gtsummary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1_gtsummary.md),
[`mysterycall_wait_time_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_summary.md),
[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md)

Other table:
[`.t1_cat_pvalue()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_cat_pvalue.md),
[`.t1_cont_pvalue()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_cont_pvalue.md),
[`.t1_fmt_mean_sd()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_fmt_mean_sd.md),
[`.t1_fmt_median_iqr()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_fmt_median_iqr.md),
[`.t1_fmt_pct()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_fmt_pct.md),
[`.t1_fmt_pval()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_fmt_pval.md),
[`.t1_rows_categorical()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_rows_categorical.md),
[`.t1_rows_continuous()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_rows_continuous.md),
[`mysterycall_table1_gtsummary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1_gtsummary.md),
[`mysterycall_table_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_overall.md),
[`mysterycall_write_arsenal_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_arsenal_table.md),
[`mysterycall_write_table_pdf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table_pdf.md),
[`print.mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_table1.md)

## Examples

``` r
df <- data.frame(
  gender    = c("Male", "Female", "Female", "Male", "Male", "Female"),
  academic  = c("University", "Private Practice", "Private Practice",
                "University", "Private Practice", "University"),
  wait_days = c(10, 25, 14, 30, 7, 21),
  insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS", "Medicaid", "BCBS")
)
result <- mysterycall_table1(
  df,
  covariates   = c("gender", "academic", "wait_days"),
  stratify_by  = "insurance"
)
result$table
#> # A tibble: 6 × 6
#>   variable  level            Overall       `BCBS (N=3)` `Medicaid (N=3)` p_value
#>   <chr>     <chr>            <chr>         <chr>        <chr>            <chr>  
#> 1 gender    Female           3 (50.0%)     2 (66.7%)    1 (33.3%)        1.000  
#> 2 gender    Male             3 (50.0%)     1 (33.3%)    2 (66.7%)        NA     
#> 3 academic  Private Practice 3 (50.0%)     1 (33.3%)    2 (66.7%)        1.000  
#> 4 academic  University       3 (50.0%)     2 (66.7%)    1 (33.3%)        NA     
#> 5 wait_days Median [IQR]     17.5 [11.0-2… 25.0 [23.0-… 10.0 [8.5-12.0]  0.081  
#> 6 wait_days Mean (SD)        17.8 (9.0)    25.3 (4.5)   10.3 (3.5)       NA     
```
