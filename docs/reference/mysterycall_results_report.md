# Generate a complete manuscript results report from a fitted model

Produces every component needed for the results section of a
mystery-caller manuscript in a single call: a combined IRR +
absolute-days table, a prose results paragraph, acceptance-rate summary
(when `data` is supplied), and an optional `.docx` export.

## Usage

``` r
mysterycall_results_report(
  model_result,
  baseline_mean = NULL,
  exposure_col = NULL,
  ref_group = NULL,
  data = NULL,
  accepted_col = "contact_office",
  group_col = NULL,
  outcome_label = "appointment wait time",
  digits = 2L,
  include_intercept = FALSE,
  output_path = NULL
)
```

## Arguments

- model_result:

  A `mysterycall_poisson_model` or `mysterycall_nb_model` object
  returned by
  [`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
  or
  [`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md).

- baseline_mean:

  Numeric scalar. Observed mean wait days in the reference group (e.g.
  `mean(data$wait_days[data$insurance == "BCBS"])`). Used to convert
  IRRs to absolute day differences. Pass `NULL` to omit day columns.

- exposure_col:

  Character scalar. Name of the exposure variable in the model (e.g.
  `"insurance"`). Required for the prose paragraph and for filtering
  IRR-to-days output to a single predictor.

- ref_group:

  Character scalar. Label for the reference group, used in the prose
  paragraph and day-difference sentences (e.g. `"BCBS"`).

- data:

  Optional data frame. When supplied,
  [`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md)
  is called to produce Panel A of the acceptance table. Must contain
  `accepted_col` and `group_col` columns.

- accepted_col:

  Character scalar. Name of the 0/1 (or logical) column indicating
  whether the office accepted the appointment. Default
  `"contact_office"`. Used only when `data` is not `NULL`.

- group_col:

  Character scalar. Column name for the grouping variable in the
  acceptance table (e.g. `"insurance"`). Used only when `data` is not
  `NULL`.

- outcome_label:

  Character scalar passed to
  [`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md).
  Default `"appointment wait time"`.

- digits:

  Integer. Decimal places for IRR and CI in the table. Default `2L`.

- include_intercept:

  Logical. Include the intercept row? Default `FALSE`.

- output_path:

  Character scalar or `NULL`. When a `.docx` path is supplied (e.g.
  `"results/Table2.docx"`),
  [`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md)
  is called to write the combined table and paragraph to Word. Requires
  the `flextable` and `officer` packages.

## Value

A list of class `mysterycall_results_report` with elements:

- `combined_table`:

  Data frame from
  [`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md).
  Columns: `Term`, `IRR`, `IRR 95% CI`, `p-value`, `Days Diff`,
  `Days 95% CI`, `Significance`. Day columns are `NA` when
  `baseline_mean = NULL`.

- `irr_days`:

  A `mysterycall_irr_days` object from
  [`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
  or `NULL` when `baseline_mean = NULL`.

- `paragraph`:

  Character scalar. Prose results paragraph from
  [`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md).

- `day_sentences`:

  Character vector. One day-difference sentence per exposure-level row,
  or `NULL` when `baseline_mean = NULL`.

- `acceptance`:

  List from
  [`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md),
  or `NULL` when `data = NULL`.

- `docx_path`:

  Character scalar path to the exported `.docx` file, or `NULL` when
  `output_path = NULL`.

## Details

This is intentionally a thin wrapper: each component can also be
generated individually via
[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md),
and
[`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md).

## See also

[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md),
[`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md)

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
[`mysterycall_sample_size_text()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_size_text.md),
[`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md),
[`mysterycall_sensitivity_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_table.md),
[`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md),
[`mysterycall_strobe_flow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_flow.md),
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
set.seed(42)
df <- data.frame(
  wait    = rpois(60, 21),
  ins     = rep(c("Medicaid", "BCBS"), 30),
  phys    = rep(paste0("Dr", 1:10), each = 6),
  stringsAsFactors = FALSE
)
fit <- mysterycall_poisson_model(df, "wait", "ins", "phys")
#> Fitting Poisson GLMER: wait ~ ins + (1 | phys)
#> boundary (singular) fit: see help('isSingular')
#> Convergence issues detected:
#>   boundary (singular) fit: see help('isSingular')
#> Consider simplifying predictors or using nAGQ = 1.
#> Singular fit: random-intercept variance is ~0. The physician-level random effect explains little variation.
#> Model fitted: n=60, physicians=10, AIC=371.7, overdispersion=1.16
report <- mysterycall_results_report(
  fit,
  baseline_mean = 21,
  exposure_col  = "ins",
  ref_group     = "BCBS"
)
print(report)
#> === Mystery-Caller Results Report ===
#> 
#> -- Combined Results Table --
#>         Term  IRR IRR 95% CI p-value Days Diff Days 95% CI Significance
#>  insMedicaid 1.01  0.90-1.12   0.912      +0.1 -2.0 to 2.5             
#> 
#> -- Results Paragraph --
#> In multivariable Poisson regression, ins was not significantly associated with
#> appointment wait time (see Table X). Compared with BCBS, callers presenting as
#> Medicaid had an IRR of 1.01 (95% CI 0.90-1.12; p = 0.912) for appointment wait
#> time.
#> 
#> 
#> -- Absolute Day-Difference Sentences --
#>   Medicaid-insured callers waited a mean of 0.1 more days compared with BCBS (95% CI -2.0 to +2.5 days; IRR 1.01; p = 0.912) (difference not statistically significant). 
#> 
```
