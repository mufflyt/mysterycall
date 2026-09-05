# Draw a participant flow diagram for a mystery-caller study

Produces a CONSORT/STROBE-style flow diagram using ggplot2 (no
DiagrammeR dependency). Boxes show N at each stage; side branches
display exclusion counts and optional reasons. The returned ggplot2
object can be saved with
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
or embedded in R Markdown / Quarto reports.

## Usage

``` r
mysterycall_flow_diagram(
  n_identified,
  n_contacted = NULL,
  n_excluded_contact = NULL,
  n_completed = NULL,
  n_excluded_complete = NULL,
  n_analysed,
  exclusion_reasons = NULL,
  label_identified = "Physicians identified",
  label_contacted = "Physicians contacted",
  label_completed = "Calls completed",
  label_analysed = "Physicians analysed",
  label_excluded = "Excluded",
  title = "Study Flow Diagram",
  output_path = NULL,
  width = 8,
  height = 6
)
```

## Arguments

- n_identified:

  Integer. Physicians in the initial sampling frame (e.g. from NPI
  lookup).

- n_contacted:

  Integer or `NULL`. Physicians where a mystery call was attempted. If
  `NULL`, this box is omitted from the diagram.

- n_excluded_contact:

  Integer or `NULL`. Physicians excluded before contact (e.g. retired,
  wrong specialty, disconnected number). Shown as a right-side branch
  below the "identified" box.

- n_completed:

  Integer or `NULL`. Physicians for whom the call was completed (reached
  a live person). If `NULL`, this box is omitted.

- n_excluded_complete:

  Integer or `NULL`. Physicians excluded after contact but before
  analysis (e.g. unable to reach after 3 attempts, office refused to
  respond).

- n_analysed:

  Integer. Physicians included in the final analysis. Must be \> 0 and
  \<= `n_identified`.

- exclusion_reasons:

  Named character vector. Names `"contact"` and/or `"complete"` map to
  reason strings appended below the exclusion count (e.g.
  `c(contact = "Retired or wrong specialty", complete = "No answer")`).

- label_identified, label_contacted, label_completed, label_analysed:

  Character. Box headers for the four stages (the count is appended
  automatically). Override to repurpose the diagram for a
  non-mystery-caller pipeline (e.g.
  `label_completed = "Target subspecialists"`). Defaults are the
  mystery-caller wording.

- label_excluded:

  Character. Header for the right-side exclusion boxes. Default
  `"Excluded"`.

- title:

  Character. Plot title. Default `"Study Flow Diagram"`.

- output_path:

  Character or `NULL`. File path to save the plot via
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).
  Extension determines format (`.png`, `.pdf`, etc.). When `NULL`
  (default), no file is written.

- width:

  Numeric. Width in inches for `ggsave`. Default `8`.

- height:

  Numeric. Height in inches for `ggsave`. Default `6`.

## Value

A ggplot2 object (invisibly). When `output_path` is not `NULL`, the file
is saved and the path is messaged to the console.

## See also

[`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md)
which flags when a flow diagram is missing;
[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md)
for the baseline characteristics table.

Other manuscript:
[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md),
[`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md),
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
mysterycall_flow_diagram(
  n_identified        = 500,
  n_contacted         = 420,
  n_excluded_contact  = 80,
  n_completed         = 369,
  n_excluded_complete = 51,
  n_analysed          = 369,
  exclusion_reasons   = c(
    contact  = "Retired, wrong specialty, or disconnected",
    complete = "No answer after 3 attempts"
  )
)
```
