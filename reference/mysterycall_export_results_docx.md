# Write a styled manuscript results table to a .docx file

Converts a results data frame (typically from
[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md))
into a formatted Word document using `flextable` and `officer`.
Significant rows (p \< 0.05) are bold when
`attr(table, "significant_rows")` is set.

## Usage

``` r
mysterycall_export_results_docx(
  table,
  paragraph = NULL,
  title = "Results",
  output_path = "results.docx",
  author = NULL,
  bold_significant = TRUE
)
```

## Arguments

- table:

  A data frame to render as a table. Typically the output of
  [`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md).

- paragraph:

  Character scalar. Optional results paragraph to insert before the
  table. Default `NULL` (omit).

- title:

  Character scalar. Document heading. Default `"Results"`. Pass `NULL`
  to omit the heading.

- output_path:

  Character scalar. Path to the output `.docx` file. Default
  `"results.docx"`.

- author:

  Character scalar. Optional author line inserted after the heading.
  Default `NULL`.

- bold_significant:

  Logical. Whether to bold rows where p \< 0.05 (determined from
  `attr(table, "significant_rows")`). Default `TRUE`.

## Value

`output_path`, returned invisibly after writing the file.

## Note

Both `flextable` and `officer` are in the package Suggests field.
Install them with `install.packages(c("flextable", "officer"))`.

## See also

[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md)
to build the input table;
[`mysterycall_results_report()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_report.md)
for a one-call wrapper.

Other manuscript:
[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md),
[`mysterycall_flow_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_diagram.md),
[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md),
[`mysterycall_literature_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_literature_table.md),
[`mysterycall_materials_methods()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_materials_methods.md),
[`mysterycall_methods_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_methods_paragraph.md),
[`mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_comparison_table.md),
[`mysterycall_multi_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_model_table.md),
[`mysterycall_results_report()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_report.md),
[`mysterycall_sampl_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sampl_checklist.md),
[`mysterycall_sample_size_text()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_size_text.md),
[`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md),
[`mysterycall_sensitivity_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_table.md),
[`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md),
[`mysterycall_strobe_flow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_flow.md),
[`mysterycall_subspecialist_infographic()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_infographic.md),
[`mysterycall_subspecialist_trend()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_trend.md),
[`mysterycall_summarize_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_demographics.md),
[`mysterycall_table2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table2.md),
[`print.mysterycall_materials_methods()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_materials_methods.md),
[`print.mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_comparison_table.md),
[`print.mysterycall_multi_model_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_multi_model_table.md),
[`print.mysterycall_results_report()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_results_report.md),
[`print.mysterycall_sampl_checklist()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_sampl_checklist.md),
[`print.mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_strobe_checklist.md),
[`print.mysterycall_table2()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_table2.md)

## Examples

``` r
if (FALSE) { # interactive()
tbl <- data.frame(
  Term = c("Medicaid", "Uninsured"),
  IRR  = c("1.28", "0.81"),
  `p-value` = c("0.014", "0.134"),
  check.names = FALSE
)
attr(tbl, "significant_rows") <- 1L
mysterycall_export_results_docx(tbl, title = "Table 2",
                                output_path = tempfile(fileext = ".docx"))
}
```
