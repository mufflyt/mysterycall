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
  software = "R (R Foundation for Statistical Computing)"
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
[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md),
[`mysterycall_sample_size_text()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_size_text.md),
[`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md),
[`mysterycall_summarize_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_demographics.md)

## Examples

``` r
mysterycall_methods_paragraph(
  n_physicians  = 369,
  n_cities      = 10,
  specialties   = c("otolaryngology", "neurotology"),
  insurance_types = c("Medicaid", "Blue Cross Blue Shield")
)
#> Error in mysterycall_methods_paragraph(n_physicians = 369, n_cities = 10,     specialties = c("otolaryngology", "neurotology"), insurance_types = c("Medicaid",         "Blue Cross Blue Shield")): could not find function "mysterycall_methods_paragraph"
```
