# Simulated-patient (CRiSP-style) reporting checklist

Mystery-caller / secret-shopper studies are a form of
*simulated-patient* research, and reviewers increasingly expect the
covert-methodology reporting items that a generic STROBE checklist does
not cover: why the covert method was justified, how callers were
recruited and standardized, how scenario fidelity was monitored, how
(and whether) practices could detect the call, and how the deception was
handled ethically. This returns a fillable checklist organized around
the domains of the CRiSP framework (Checklist for Reporting Research
using Simulated-Patient methodology), as a companion to
[`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md).

## Usage

``` r
mysterycall_crisp_checklist(reported = NA)
```

## Arguments

- reported:

  Optional character vector, one entry per checklist item, used to
  pre-fill the `reported` column (e.g. page numbers). Length must equal
  the number of items (see [`nrow()`](https://rdrr.io/r/base/nrow.html)
  of a default call). Default `NA`.

## Value

An object of class `"mysterycall_crisp_checklist"`: a data frame with
columns `section`, `item`, `recommendation`, `reported`.
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
it plainly.

## Details

It is a scaffold, not a substitute for the source instrument: the
`reported` column is yours to complete (a page/section reference or
`"n/a"`), and item wording should be confirmed against the current
published checklist for a formal submission.

## See also

[`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md)

## Examples

``` r
cl <- mysterycall_crisp_checklist()
head(cl)
#> <CRiSP-style simulated-patient reporting checklist: 6 items, 3 sections>
#>    section                                   item
#>  Rationale         Justification of covert method
#>  Rationale                     Construct measured
#>   Scenario                   Scenario development
#>   Scenario               Scenario standardization
#>    Callers Caller recruitment and characteristics
#>    Callers                        Caller training
#>                                                                                          recommendation
#>  State why a simulated-patient/mystery-caller design was necessary rather than a survey or overt audit.
#>    Define the access construct(s) audited (e.g. new-patient acceptance, wait time) and why they matter.
#>   Describe how the caller scenario(s) were developed, piloted, and validated for clinical plausibility.
#>   Report the script and the fields deliberately varied (e.g. insurance) vs. held constant across calls.
#>              Describe who placed the calls, their number, background, and any relevant characteristics.
#>            Report how callers were trained to deliver the scenario consistently and to record outcomes.
#>  reported
#>      <NA>
#>      <NA>
#>      <NA>
#>      <NA>
#>      <NA>
#>      <NA>
nrow(cl)
#> [1] 20
```
