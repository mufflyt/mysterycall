# STROBE reporting checklist for mystery-caller studies

Evaluates a fitted model result against STROBE (Strengthening the
Reporting of Observational Studies in Epidemiology) criteria relevant to
mystery-caller audit studies. Returns a data frame of 16 checklist items
with pass/warn/fail status, suitable for inclusion in a supplementary
file or peer-review response.

## Usage

``` r
mysterycall_strobe_checklist(
  model_result,
  data = NULL,
  sensitivity_run = FALSE,
  has_flow_diagram = FALSE,
  irr_reported = NULL,
  overdispersion_reported = NULL
)
```

## Arguments

- model_result:

  A `mysterycall_poisson_model` or `mysterycall_nb_model` object.

- data:

  Optional data frame. When provided, used to check total N and
  missing-data patterns.

- sensitivity_run:

  Logical. Was a sensitivity analysis (e.g.
  [`mysterycall_sensitivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity.md))
  performed and reported? Default `FALSE`.

- has_flow_diagram:

  Logical. Does the manuscript include a participant flow diagram
  (CONSORT-style)? Default `FALSE`.

- irr_reported:

  Logical or `NULL`. Override auto-detection of whether IRRs with
  confidence intervals were reported. When `NULL` (default),
  auto-detected from `model_result$irr_table`.

- overdispersion_reported:

  Logical or `NULL`. Override auto-detection of whether overdispersion
  was reported. When `NULL` (default), auto-detected from
  `model_result$overdispersion`.

## Value

A data frame of class `mysterycall_strobe_checklist` with columns:

- `Item`:

  Integer. STROBE item number (1-16, adapted for this study type).

- `Category`:

  Character. STROBE section (e.g. `"Methods"`, `"Results"`).

- `Description`:

  Character. Brief description of the reporting requirement.

- `Status`:

  Character. One of `"PASS"`, `"WARN"`, or `"FAIL"`.

- `Detail`:

  Character. Explanation of the status assessment.

## Details

Where a criterion cannot be determined from the model object alone, the
status is `"WARN"` with a note to verify manually. Only items where a
programmatic check is possible (e.g., CI columns present, overdispersion
value recorded) may reach `"PASS"` or `"FAIL"` automatically.

## References

von Elm E, Altman DG, Egger M, Pocock SJ, Gotzsche PC, Vandenbroucke JP;
STROBE Initiative. Strengthening the Reporting of Observational Studies
in Epidemiology (STROBE) statement: guidelines for reporting
observational studies. *Lancet*. 2007;370(9596):1453-1457.
[doi:10.1016/S0140-6736(07)61602-X](https://doi.org/10.1016/S0140-6736%2807%2961602-X)

## See also

[`mysterycall_sensitivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity.md)
for running sensitivity analyses;
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md)
and
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
for the model objects this function inspects.

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
irr_tbl <- data.frame(
  term      = c("(Intercept)", "insuranceMedicaid"),
  irr       = c(1.00, 1.28),
  ci_lower  = c(NA,   1.05),
  ci_upper  = c(NA,   1.56),
  p_value   = c(NA,   0.014),
  stringsAsFactors = FALSE
)
fake_model <- structure(
  list(
    irr_table     = irr_tbl,
    overdispersion = 1.3,
    n_dropped     = 4L,
    model         = NULL
  ),
  class = "mysterycall_poisson_model"
)
cl <- mysterycall_strobe_checklist(fake_model, sensitivity_run = TRUE)
print(cl)
#> STROBE Checklist for Mystery-Caller Study
#> ================================================== 
#> [WARN] Item  1  Title/Abstract: Study design stated in title or abstract
#>          Cannot auto-detect; verify manually.
#> [WARN] Item  2  Introduction: Scientific background and objectives stated
#>          Cannot auto-detect; verify manually.
#> [WARN] Item  3  Methods: Setting, locations, and dates described
#>          Cannot auto-detect; verify manually.
#> [WARN] Item  4  Methods: Eligibility criteria for participants stated
#>          Cannot auto-detect; verify manually.
#> [WARN] Item  5  Methods: Mystery-caller protocol described (script, blinding, call timing)
#>          Cannot auto-detect; verify manually.
#> [WARN] Item  6  Methods: Sample size justified
#>          No power/sample_size field found. Verify that a power analysis is reported.
#> [WARN] Item  8  Methods: Physician random intercepts included and stated
#>          Could not detect '|' in model formula. Verify random intercepts are stated in methods.
#> [WARN] Item  9  Methods: Overdispersion addressed (NB model or test reported)
#>          Poisson model detected; verify that overdispersion test/phi is reported in methods.
#> [WARN] Item 10  Results: Flow diagram or N screened/excluded reported
#>          Verify that a participant flow diagram or exclusion table is included.
#> [WARN] Item 16  Discussion: Limitations discussed
#>          Cannot auto-detect; verify manually.
#> [PASS] Item  7  Methods: Statistical methods: model family specified
#>          Model class 'mysterycall_poisson_model' detected; model family is unambiguous.
#> [PASS] Item 11  Results: Number of observations with missing data reported
#>          model_result$n_dropped = 4.
#> [PASS] Item 12  Results: IRR with 95% confidence intervals reported
#>          ci_lower and ci_upper columns found with non-NA values in irr_table.
#> [PASS] Item 13  Results: p-values reported for primary comparisons
#>          p_value column with non-NA values found in irr_table.
#> [PASS] Item 14  Results: Overdispersion statistic (phi) reported
#>          model_result$overdispersion = 1.300.
#> [PASS] Item 15  Results: Sensitivity analysis performed
#>          sensitivity_run=TRUE supplied by caller.
#> 
#> Summary: 6 PASS, 10 WARN, 0 FAIL
```
