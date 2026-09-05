# SAMPL statistical-reporting checklist

STROBE says what to report about an observational study's design; SAMPL
(Statistical Analyses and Methods in the Published Literature) says how
to report the numbers themselves: give an effect size with a confidence
interval rather than a bare p-value, name the test and why it fits, give
the denominator behind every percentage, and state the precision the
data actually support. This returns a fillable checklist of the SAMPL
items that bear on a mystery-caller audit – proportions, rate ratios,
wait times, clustered calls – as a companion to
[`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md)
and
[`mysterycall_crisp_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_crisp_checklist.md).

## Usage

``` r
mysterycall_sampl_checklist(reported = NA)
```

## Arguments

- reported:

  Optional character vector, one entry per checklist item, used to
  pre-fill the `reported` column (e.g. page numbers). Length must equal
  the number of items (see [`nrow()`](https://rdrr.io/r/base/nrow.html)
  of a default call). Default `NA`.

## Value

An object of class `"mysterycall_sampl_checklist"`: a data frame with
columns `section`, `item`, `recommendation`, `reported`.
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
it plainly.

## Details

The point of citing it in a manuscript is usually defensive: reporting
`"OR 0.31, 95% CI 0.05 to 1.9"` instead of `"p = .21"` is a deliberate
choice backed by a published guideline, not a way to dodge a null
result.

It is a scaffold, not a substitute for the source guideline: the
`reported` column is yours to complete (a page/section reference or
`"n/a"`), and item wording should be confirmed against the published
guidelines for a formal submission.

The `reported` column is filled in by hand, which is the weakness of any
checklist object: nothing ties an item to the code that satisfies it.
rOpenSci's srr (Software Review Roclets, MIT) solves that properly and
is the model to follow if these items ever need machine verification.
Standards are tagged in roxygen at the code location that meets them
(`@srrstats`), unaddressed ones stay visible as `@srrstatsTODO`,
inapplicable ones are justified with `@srrstatsNA`, and a pre-submit
check fails while any TODO remains. That anchors compliance to code
rather than to a page number typed into a column.

## References

Lang TA, Altman DG. Basic statistical reporting for articles published
in biomedical journals: the "Statistical Analyses and Methods in the
Published Literature" or the SAMPL Guidelines. *International Journal of
Nursing Studies*. 2015;52(1):5-9.
[doi:10.1016/j.ijnurstu.2014.09.006](https://doi.org/10.1016/j.ijnurstu.2014.09.006)

rOpenSci Software Review Roclets (srr), the model for tying checklist
items to the code that satisfies them:
<https://github.com/ropensci-review-tools/srr>

## See also

[`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md)
for the design-reporting items and
[`mysterycall_crisp_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_crisp_checklist.md)
for the simulated-patient items.

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
cl <- mysterycall_sampl_checklist()
head(cl)
#> <SAMPL statistical-reporting checklist: 6 items, 1 sections>
#>  section                                      item
#>  General Methods reproducible from the description
#>  General                       Numerical precision
#>  General         Denominators for every percentage
#>  General    Intervals and ranges written with 'to'
#>  General         P values reported as exact values
#>  General           Effect size, not just a p value
#>                                                                                                                                                             recommendation
#>                                             Describe the statistical methods in enough detail that a knowledgeable reader with the data could verify the reported results.
#>                 Report numbers to the precision the data support: two significant digits for most effect sizes, and no more decimal places than the measurement justifies.
#>                              Give the numerator and denominator behind each percentage, and report counts alone rather than percentages for groups of fewer than about 20.
#>                                     Separate the endpoints of confidence intervals and ranges with 'to' rather than a hyphen, so that negative endpoints stay unambiguous.
#>  Report p values as exact values to two or three decimal places rather than as inequalities against alpha; reserve '< 0.001' for values below that, and never report 'NS'.
#>            Report an effect size with a confidence interval for every primary comparison; a p value on its own is not a result and does not measure the size of an effect.
#>  reported
#>      <NA>
#>      <NA>
#>      <NA>
#>      <NA>
#>      <NA>
#>      <NA>
nrow(cl)
#> [1] 27
```
