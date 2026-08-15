# Merge IRR results and absolute day differences into one publication table

Builds a single data frame suitable for a manuscript Table 2 by
combining incidence rate ratios (and their Wald CIs) with clinically
interpretable absolute day differences derived from
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md).

## Usage

``` r
mysterycall_combined_results_table(
  model_result,
  baseline_mean = NULL,
  exposure_col = NULL,
  ref_group = NULL,
  digits = 2L,
  include_intercept = FALSE
)
```

## Arguments

- model_result:

  A `mysterycall_poisson_model` or `mysterycall_nb_model` object, or a
  data frame with columns `term`, `irr`, `ci_lower`, `ci_upper`, and
  `p_value`.

- baseline_mean:

  Numeric scalar. Reference-group mean wait days used to convert IRRs to
  day differences. Pass `NULL` (default) to omit the day columns
  entirely.

- exposure_col:

  Character scalar. Name of the exposure variable (e.g. `"insurance"`).
  Passed to
  [`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md)
  to limit day rows. `NULL` includes all non-intercept terms.

- ref_group:

  Character scalar. Reference-group label for day sentences (e.g.
  `"BCBS"`). `NULL` omits the "compared with X" clause.

- digits:

  Integer. Decimal places for IRR and CI columns. Default `2L`.

- include_intercept:

  Logical. Include the intercept row? Default `FALSE`.

## Value

A data frame with columns (in order):

- `Term`:

  Model term name.

- `IRR`:

  Formatted IRR string.

- `IRR 95% CI`:

  en-dash separated CI string, e.g. `"1.05-1.56"`.

- `p-value`:

  Formatted p-value string.

- `Days Diff`:

  Signed absolute day difference (`"+4.3"`), or `NA` when
  `baseline_mean` is `NULL`.

- `Days 95% CI`:

  `"lower to upper"` in days, or `NA`.

- `Significance`:

  `"*"` when p \< 0.05, `""` otherwise.

The data frame carries two attributes:

- `significant_rows`:

  Integer vector of row indices where p \< 0.05.

- `has_days`:

  Logical. `TRUE` when `baseline_mean` was supplied.

## See also

[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md)

Other manuscript:
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
[`mysterycall_subspecialist_infographic()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_infographic.md),
[`mysterycall_subspecialist_trend()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_trend.md),
[`mysterycall_summarize_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_demographics.md),
[`mysterycall_table2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table2.md),
[`print.mysterycall_materials_methods()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_materials_methods.md),
[`print.mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_comparison_table.md),
[`print.mysterycall_multi_model_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_multi_model_table.md),
[`print.mysterycall_results_report()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_results_report.md),
[`print.mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_strobe_checklist.md),
[`print.mysterycall_table2()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_table2.md)

## Examples

``` r
irr_df <- data.frame(
  term        = c("insuranceMedicaid", "insuranceUninsured"),
  irr         = c(1.28, 0.81),
  ci_lower    = c(1.05, 0.61),
  ci_upper    = c(1.56, 1.07),
  p_value     = c(0.014, 0.134),
  stringsAsFactors = FALSE
)
mysterycall_combined_results_table(irr_df, baseline_mean = 21,
                                   exposure_col = "insurance",
                                   ref_group    = "BCBS")
#>                 Term  IRR IRR 95% CI p-value Days Diff Days 95% CI Significance
#> 1  insuranceMedicaid 1.28  1.05-1.56   0.014      +5.9 1.1 to 11.8            *
#> 2 insuranceUninsured 0.81  0.61-1.07   0.134      -4.0 -8.2 to 1.5             
```
