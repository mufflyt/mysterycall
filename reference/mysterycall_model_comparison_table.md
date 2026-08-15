# Publication-ready model comparison table

Takes a named list of fitted `mysterycall_poisson_model` and/or
`mysterycall_nb_model` objects and produces a formatted comparison table
suitable for inclusion in a manuscript. Columns include AIC, BIC, their
deltas, Pearson overdispersion (phi), and the NB dispersion parameter
(theta). The winning model is marked with `"*"`.

## Usage

``` r
mysterycall_model_comparison_table(
  models,
  criterion = c("aic", "bic"),
  digits = 1L
)
```

## Arguments

- models:

  A named list (length \>= 2) of model objects. Each element must be a
  `mysterycall_poisson_model` or `mysterycall_nb_model`.

- criterion:

  Character vector. The first element (`"aic"` or `"bic"`) determines
  which criterion selects the winner. Default `c("aic", "bic")`.

- digits:

  Integer. Decimal places for AIC, BIC, and phi columns. Default `1L`.

## Value

A data frame with columns `Model`, `Family`, `N`, `Params`, `AIC`,
`BIC`, `DeltaAIC`, `DeltaBIC`, `Phi (Pearson)`, `Theta`, `Winner`.
`Winner` is `"*"` for the best model under `criterion[1]` and `""`
otherwise. The data frame carries an attribute `"winner"` with the
winning model name.

## See also

[`mysterycall_select_best_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_select_best_model.md)
for a simpler AIC/BIC/LRT comparison;
[`mysterycall_auto_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_auto_model.md)
for automatic model selection.

Other manuscript:
[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md),
[`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md),
[`mysterycall_flow_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_diagram.md),
[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md),
[`mysterycall_literature_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_literature_table.md),
[`mysterycall_materials_methods()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_materials_methods.md),
[`mysterycall_methods_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_methods_paragraph.md),
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
if (FALSE) { # interactive()
tbl <- mysterycall_model_comparison_table(
  list(
    "Base model"  = poisson_fit,
    "+ Setting"   = poisson_fit2,
    "NB full"     = nb_fit
  )
)
print(tbl)
}
```
