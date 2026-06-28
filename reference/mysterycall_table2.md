# Build a two-panel manuscript Table 2

Combines appointment acceptance rates (Panel A) with model-based
incidence rate ratios and optional absolute day differences (Panel B)
into a single structured object ready for publication or export.

## Usage

``` r
mysterycall_table2(
  data,
  model_result,
  group_col,
  accepted_col = "contact_office",
  baseline_mean = NULL,
  exposure_col = NULL,
  ref_group = NULL,
  digits = 2L,
  include_intercept = FALSE
)
```

## Arguments

- data:

  A data frame containing raw study observations.

- model_result:

  A `mysterycall_poisson_model` or `mysterycall_nb_model` object.

- group_col:

  Character scalar. Column name defining the comparison groups (e.g.
  `"insurance"`). Must be in `names(data)`.

- accepted_col:

  Character scalar. Column name encoding whether the call resulted in an
  appointment offer. Default `"contact_office"`. Values recognised as
  accepted: `"Yes"`, `"yes"`, `TRUE`, `1`.

- baseline_mean:

  Numeric scalar or `NULL`. Reference-group mean wait days used to
  compute absolute day differences (passed to
  [`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md)).
  When `NULL`, the `Days` columns are omitted.

- exposure_col:

  Character scalar or `NULL`. Name of the exposure variable whose terms
  to extract from the model (e.g. `"insurance"`). Forwarded to
  [`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md).

- ref_group:

  Character scalar or `NULL`. Label of the reference group used in
  manuscript sentences. Forwarded to
  [`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md).

- digits:

  Integer. Decimal places for IRR and CI values. Default `2L`.

- include_intercept:

  Logical. Whether to include the intercept row in the model-estimates
  panel. Default `FALSE`.

## Value

A list of class `mysterycall_table2` with elements:

- `acceptance`:

  Data frame (Panel A). Columns: `Group`, `N`, `Accepted, n (%)`,
  `95% CI`.

- `estimates`:

  Data frame (Panel B). Columns: `Term`, `IRR`, `IRR 95% CI`, `p-value`,
  and (when `baseline_mean` is supplied) `Days Diff`, `Days 95% CI`.

- `notes`:

  Character vector of standard footnotes.

## See also

[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md)
for acceptance-rate computation;
[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md)
for IRR formatting;
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md)
for absolute day conversion.

Other manuscript:
[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md),
[`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md),
[`mysterycall_flow_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_diagram.md),
[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md),
[`mysterycall_literature_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_literature_table.md),
[`mysterycall_materials_methods()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_materials_methods.md),
[`mysterycall_methods_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_methods_paragraph.md),
[`mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_comparison_table.md),
[`mysterycall_multi_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_model_table.md),
[`mysterycall_results_report()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_report.md),
[`mysterycall_sample_size_text()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_size_text.md),
[`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md),
[`mysterycall_sensitivity_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_table.md),
[`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md),
[`mysterycall_strobe_flow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_flow.md),
[`mysterycall_summarize_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_demographics.md),
[`print.mysterycall_materials_methods()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_materials_methods.md),
[`print.mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_comparison_table.md),
[`print.mysterycall_multi_model_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_multi_model_table.md),
[`print.mysterycall_results_report()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_results_report.md),
[`print.mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_strobe_checklist.md),
[`print.mysterycall_table2()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_table2.md)

## Examples

``` r
if (FALSE) { # interactive()
tbl2 <- mysterycall_table2(
  data         = study_data,
  model_result = fitted_model,
  group_col    = "insurance",
  baseline_mean = 21,
  exposure_col  = "insurance",
  ref_group     = "BCBS"
)
print(tbl2)
}
```
