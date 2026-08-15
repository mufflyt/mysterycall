# Generate a boilerplate methods paragraph for a mystery-caller study

Fills a standard methods template describing the mystery-caller audit
methodology, sample size, geographic scope, insurance types tested,
outcome measure, and analysis software.

## Usage

``` r
mysterycall_methods_paragraph(
  n_physicians,
  n_cities,
  specialties,
  insurance_types = c("Medicaid", "commercial insurance"),
  outcome = "business days until a new-patient appointment",
  software = "R (R Foundation for Statistical Computing)",
  model_family = c("poisson", "negative_binomial", "auto")
)
```

## Arguments

- n_physicians:

  Integer. Total number of physicians contacted.

- n_cities:

  Integer. Number of cities/states covered.

- specialties:

  Character vector of medical specialties included.

- insurance_types:

  Character vector of insurance types tested. Default
  `c("Medicaid", "commercial insurance")`.

- outcome:

  Character scalar describing the primary outcome. Default
  `"business days until a new-patient appointment"`.

- software:

  Character scalar naming the analysis software. Default
  `"R (R Foundation for Statistical Computing)"`.

- model_family:

  One of `"poisson"` (default), `"negative_binomial"`, or `"auto"`.
  Controls the statistical-model sentence appended after the software
  statement. Alternatively, pass a fitted `mysterycall_poisson_model` or
  `mysterycall_nb_model` object and the family is detected
  automatically.

## Value

A single character string containing a ready-to-paste methods paragraph
describing the mystery-caller study design.

## See also

[`mysterycall_sample_size_text()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_size_text.md)
for the sample-size sentence;
[`mysterycall_summarize_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_demographics.md)
for the demographics summary;
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md)
for the results section.

Other manuscript:
[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md),
[`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md),
[`mysterycall_flow_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_diagram.md),
[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md),
[`mysterycall_literature_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_literature_table.md),
[`mysterycall_materials_methods()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_materials_methods.md),
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
mysterycall_methods_paragraph(
  n_physicians  = 369,
  n_cities      = 10,
  specialties   = c("otolaryngology", "neurotology"),
  insurance_types = c("Medicaid", "Blue Cross Blue Shield")
)
#> [1] "A mystery-caller audit methodology was employed. A total of 369 physicians representing otolaryngology and neurotology were identified from publicly available directories across 10 cities and states in the United States. Mystery callers posed as new patients insured with Medicaid and Blue Cross Blue Shield and contacted each physician's office to request the earliest available new-patient appointment. Calls were standardized and completed within one week of each other. The primary outcome was business days until a new-patient appointment. All analyses were performed using R (R Foundation for Statistical Computing). A multilevel Poisson regression model with physician random intercepts was fit using the lme4 package to estimate incidence rate ratios (IRR) for the primary outcomes."

mysterycall_methods_paragraph(
  n_physicians    = 216,
  n_cities        = 12,
  specialties     = "otolaryngology",
  model_family    = "negative_binomial"
)
#> [1] "A mystery-caller audit methodology was employed. A total of 216 physicians representing otolaryngology were identified from publicly available directories across 12 cities and states in the United States. Mystery callers posed as new patients insured with Medicaid and commercial insurance and contacted each physician's office to request the earliest available new-patient appointment. Calls were standardized and completed within one week of each other. The primary outcome was business days until a new-patient appointment. All analyses were performed using R (R Foundation for Statistical Computing). A multilevel negative binomial regression model with physician random intercepts was fit using the glmmTMB package to account for overdispersion in appointment wait times and estimate incidence rate ratios (IRR)."
```
