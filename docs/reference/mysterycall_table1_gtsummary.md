# Publication-ready Table 1 via gtsummary

Wraps
[`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
with opinionated defaults suitable for mystery-caller study
demographics: no "Unknown" rows (use `missing = "ifany"` to re-enable),
bold row labels, an overall column and p-values when stratified.

## Usage

``` r
mysterycall_table1_gtsummary(
  data,
  vars,
  strata_col = NULL,
  label_list = NULL,
  missing = "no",
  percent = c("column", "row", "cell"),
  overall_last = FALSE,
  ...
)
```

## Arguments

- data:

  A data frame.

- vars:

  Non-empty character vector of column names to include as rows. All
  names must be present in `data`. If `strata_col` appears here it is
  silently removed with a warning.

- strata_col:

  Optional single character column name to stratify by (e.g.
  `"insurance"`). When provided, an Overall column and p-values are
  added automatically.

- label_list:

  Optional named list mapping column names to display labels, forwarded
  to
  [`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html).

- missing:

  One of `"no"` (default), `"ifany"`, or `"always"`. Controls
  missing-data reporting. Forwarded to
  [`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html).

- percent:

  One of `"column"` (default), `"row"`, or `"cell"`. Controls the
  denominator used for categorical-variable percentages.

- overall_last:

  Logical. When `strata_col` is provided, should the Overall column
  appear last (`TRUE`) or first (`FALSE`, default)?

- ...:

  Additional arguments forwarded to
  [`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html).

## Value

A `gtsummary` `tbl_summary` object. Chain additional modifiers (e.g.
[`gtsummary::modify_caption()`](https://www.danieldsjoberg.com/gtsummary/reference/modify_caption.html),
[`gtsummary::modify_spanning_header()`](https://www.danieldsjoberg.com/gtsummary/reference/modify.html))
before converting with
[`gtsummary::as_gt()`](https://www.danieldsjoberg.com/gtsummary/reference/as_gt.html)
or
[`gtsummary::as_flex_table()`](https://www.danieldsjoberg.com/gtsummary/reference/as_flex_table.html).

## See also

[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md),
[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md)

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
[`mysterycall_table_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_overall.md),
[`mysterycall_write_arsenal_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_arsenal_table.md),
[`mysterycall_write_table_pdf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table_pdf.md),
[`print.mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_table1.md)

## Examples

``` r
if (FALSE) { # interactive() && requireNamespace("gtsummary", quietly = TRUE)
df <- data.frame(
  gender    = sample(c("Male", "Female"), 100, replace = TRUE),
  setting   = sample(c("Academic", "Private"), 100, replace = TRUE),
  age_cat   = sample(c("30-39", "40-49", "50-59"), 100, replace = TRUE),
  insurance = sample(c("BCBS", "Medicaid"), 100, replace = TRUE)
)
tbl <- mysterycall_table1_gtsummary(
  df,
  vars       = c("gender", "setting", "age_cat"),
  strata_col = "insurance"
)
tbl
}
```
