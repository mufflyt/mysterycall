# Generate an overall summary table

Generate an overall table summarizing the demographics of the Table 1.

## Usage

``` r
mysterycall_table_overall(
  input_file_path,
  output_directory,
  title = "Overall Table Summary",
  selected_columns = NULL,
  label_translations = NULL
)
```

## Arguments

- input_file_path:

  The path to an RDS data file.

- output_directory:

  The directory where the output table file will be saved.

- title:

  The title for the overall table summary (default is "Overall Table
  Summary").

- selected_columns:

  Optional character vector of quoted column names to include in the
  summary. When `NULL` (default) all columns of the loaded data frame
  are used. Supplying a non-existent column name raises an error. Useful
  for focusing Table 1 on a curated set of demographic variables.

- label_translations:

  Optional named list mapping column names to display labels, passed to
  [`arsenal::summary.tableby()`](https://mayoverse.github.io/arsenal/reference/summary.tableby.html).

## Value

Invisibly returns the path to the generated PDF file.

## See also

[`mysterycall_write_table_pdf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table_pdf.md)

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
[`mysterycall_write_arsenal_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_arsenal_table.md),
[`mysterycall_write_table_pdf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table_pdf.md),
[`print.mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_table1.md)

## Examples

``` r
if (FALSE) { # interactive()
# Generate the overall table
mysterycall_table_overall("data/Table1.rds", "output_tables")
}
```
