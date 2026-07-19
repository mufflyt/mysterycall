# Build Continuous Rows for Table 1

Build Continuous Rows for Table 1

## Usage

``` r
.t1_rows_continuous(
  x,
  label,
  group_vec,
  groups,
  group_col_names,
  include_overall,
  cont_stats,
  digits,
  emit_pvalue,
  min_cell
)
```

## Arguments

- x:

  Numeric vector.

- label:

  Variable label.

- group_vec:

  Grouping vector.

- groups:

  Unique groups.

- group_col_names:

  Column names for groups.

- include_overall:

  Logical; include overall column.

- cont_stats:

  Stats to include (median_iqr, mean_sd).

- digits:

  Number of digits.

- emit_pvalue:

  Logical; include p-value.

- min_cell:

  Minimum cell size.

## Value

A list of rows.

## See also

Other table:
[`.t1_cat_pvalue()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_cat_pvalue.md),
[`.t1_cont_pvalue()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_cont_pvalue.md),
[`.t1_fmt_mean_sd()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_fmt_mean_sd.md),
[`.t1_fmt_median_iqr()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_fmt_median_iqr.md),
[`.t1_fmt_pct()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_fmt_pct.md),
[`.t1_fmt_pval()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_fmt_pval.md),
[`.t1_rows_categorical()`](https://mufflyt.github.io/mysterycall/reference/dot-t1_rows_categorical.md),
[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md),
[`mysterycall_table1_gtsummary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1_gtsummary.md),
[`mysterycall_table_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_overall.md),
[`mysterycall_write_arsenal_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_arsenal_table.md),
[`mysterycall_write_table_pdf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table_pdf.md),
[`print.mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_table1.md)
