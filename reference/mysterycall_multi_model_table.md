# Build a three-column regression table for manuscript submission

Creates the "three-column regression table" that reviewers almost always
request: Model 1 (unadjusted) \| Model 2 (adjusted) \| Model 3 (+
interaction). Supports any combination of `mysterycall_logistic_model`,
`mysterycall_poisson_model`, `mysterycall_nb_model`, and
`mysterycall_lmm` objects in a single table. Mixed model types trigger a
warning and label each column header with its model type.

## Usage

``` r
mysterycall_multi_model_table(
  models,
  include_intercept = FALSE,
  digits = 2L,
  estimate_col_label = NULL,
  include_n = TRUE,
  include_aic = TRUE,
  ref_symbol = "Ref.",
  cell_layout = c("stacked", "inline")
)
```

## Arguments

- models:

  Named list of fitted model objects. Each element must be one of
  `mysterycall_logistic_model`, `mysterycall_poisson_model`,
  `mysterycall_nb_model`, or `mysterycall_lmm`. Must contain at least
  two models. Names become column headers in the output table.

- include_intercept:

  Logical. When `FALSE` (default) the `(Intercept)` row is dropped from
  output.

- digits:

  Integer. Decimal places for point estimates and confidence interval
  bounds. Default `2L`.

- estimate_col_label:

  Character or `NULL`. A label describing the estimate type shown in
  each model column (printed as a subtitle). When `NULL` (default) it is
  auto-detected from the model class: `"OR (95% CI)"` for logistic,
  `"IRR (95% CI)"` for Poisson/NB, and `"Beta (95% CI)"` for LMM. When
  model types differ the label falls back to `"Estimate (95% CI)"`.

- include_n:

  Logical. When `TRUE` (default) a footer row labelled `"N"` is appended
  showing the complete-case sample size for each model.

- include_aic:

  Logical. When `TRUE` (default) a footer row labelled `"AIC"` is
  appended. AIC is not meaningful for LMMs fitted with `REML = TRUE`;
  those cells are labelled `"(REML)"`.

- ref_symbol:

  Character. Symbol placed in reference-category cells. Default
  `"Ref."`.

- cell_layout:

  Character. How the p-value sits relative to the estimate within a
  cell. `"stacked"` (default) puts the p-value on a second line
  (`"1.45 (1.02-2.05)\np=0.038"`) – correct for gt/HTML and the console
  print method. `"inline"` keeps the whole cell on one line
  (`"1.45 (1.02-2.05), p=0.038"`) so the table renders correctly in a
  Markdown/pandoc **pipe table**, which cannot contain a multi-line cell
  (an embedded newline otherwise spills every p-value onto its own row).

## Value

A `data.frame` with class
`c("mysterycall_multi_model_table", "data.frame")`. Column `"Term"`
contains variable/level labels; subsequent columns are named after
`names(models)`. The attribute `"estimate_label"` stores the
auto-detected or user-supplied `estimate_col_label`; `"mixed_types"`
stores a logical indicating whether multiple model classes are present.

## Details

**Cell format.** Each non-reference cell contains the point estimate and
95\\ the p-value is on a second line, e.g.
`"1.45 (1.02-2.05)\np=0.038"`, and with `"inline"` it follows on the
same line. Reference-category cells show `ref_symbol`. Terms absent from
a particular model show an empty string.

**Row ordering.** Rows follow the union of all unique terms across
models. For categorical predictors, the reference-category row is
inserted immediately before the first coefficient level found in the
model output, using the `factor_refs` metadata stored in each model
object.

**Mixed model types.** When models of different classes are combined a
warning is issued and each column name gains a type tag such as
`"[Logistic]"` or `"[Poisson]"`. Numbers in each column remain on their
native scale (OR, IRR, or Beta).

## See also

[`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md),
[`mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_comparison_table.md)

Other manuscript:
[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md),
[`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md),
[`mysterycall_flow_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_diagram.md),
[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md),
[`mysterycall_literature_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_literature_table.md),
[`mysterycall_materials_methods()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_materials_methods.md),
[`mysterycall_methods_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_methods_paragraph.md),
[`mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_comparison_table.md),
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
# Build fake model objects with structure() -- no package fitting required.

m_unadj <- structure(
  list(
    or_table = data.frame(
      term        = c("insuranceMedicaid", "scenarioNo appointment"),
      or          = c(1.45, 0.82),
      ci_lower    = c(1.02, 0.61),
      ci_upper    = c(2.05, 1.10),
      p_value_fmt = c("0.038", "0.189"),
      stringsAsFactors = FALSE
    ),
    factor_refs = list(insurance = "BCBS", scenario = "Appointment"),
    n   = 200L,
    aic = 312.4
  ),
  class = "mysterycall_logistic_model"
)

m_adj <- structure(
  list(
    or_table = data.frame(
      term        = c("insuranceMedicaid", "scenarioNo appointment",
                      "regionSouth"),
      or          = c(1.38, 0.79, 1.21),
      ci_lower    = c(0.97, 0.58, 0.88),
      ci_upper    = c(1.96, 1.07, 1.66),
      p_value_fmt = c("0.072", "0.124", "0.238"),
      stringsAsFactors = FALSE
    ),
    factor_refs = list(insurance = "BCBS", scenario = "Appointment",
                       region    = "North"),
    n   = 200L,
    aic = 308.1
  ),
  class = "mysterycall_logistic_model"
)

m_inter <- structure(
  list(
    or_table = data.frame(
      term        = c("insuranceMedicaid", "scenarioNo appointment",
                      "regionSouth",
                      "insuranceMedicaid:scenarioNo appointment"),
      or          = c(1.41, 0.81, 1.19, 0.67),
      ci_lower    = c(0.99, 0.59, 0.86, 0.41),
      ci_upper    = c(2.01, 1.09, 1.65, 1.09),
      p_value_fmt = c("0.059", "0.163", "0.272", "0.107"),
      stringsAsFactors = FALSE
    ),
    factor_refs = list(insurance = "BCBS", scenario = "Appointment",
                       region    = "North"),
    n   = 200L,
    aic = 306.8
  ),
  class = "mysterycall_logistic_model"
)

tbl <- mysterycall_multi_model_table(
  models = list(
    "Unadjusted"   = m_unadj,
    "Adjusted"     = m_adj,
    "+ Interaction" = m_inter
  )
)
print(tbl)
#> Multi-model regression table  [OR (95% CI)]
#> ------------------------------------------------------------ 
#>  Term                                     Unadjusted                   
#>  insuranceBCBS                            Ref.                         
#>  insuranceMedicaid                        1.45 (1.02 to 2.05) | p=0.038
#>  scenarioAppointment                      Ref.                         
#>  scenarioNo appointment                   0.82 (0.61 to 1.10) | p=0.189
#>  regionNorth                                                           
#>  regionSouth                                                           
#>  insuranceMedicaid:scenarioNo appointment                              
#>  N                                        200                          
#>  AIC                                      312.4                        
#>  Adjusted                      + Interaction                
#>  Ref.                          Ref.                         
#>  1.38 (0.97 to 1.96) | p=0.072 1.41 (0.99 to 2.01) | p=0.059
#>  Ref.                          Ref.                         
#>  0.79 (0.58 to 1.07) | p=0.124 0.81 (0.59 to 1.09) | p=0.163
#>  Ref.                          Ref.                         
#>  1.21 (0.88 to 1.66) | p=0.238 1.19 (0.86 to 1.65) | p=0.272
#>                                0.67 (0.41 to 1.09) | p=0.107
#>  200                           200                          
#>  308.1                         306.8                        
#> ------------------------------------------------------------ 
```
