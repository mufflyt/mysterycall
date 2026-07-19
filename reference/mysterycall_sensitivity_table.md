# Side-by-side sensitivity table of exposure-term estimates across models

Produces a classic "3-column regression table" (Model 1 unadjusted /
Model 2 adjusted / Model 3 + interaction) in which each column shows the
**key exposure term's** odds ratio (OR), incidence rate ratio (IRR), or
linear coefficient (beta) together with its 95% confidence interval and
p-value. Optional footer rows report sample size and AIC for each model.

## Usage

``` r
mysterycall_sensitivity_table(
  models,
  exposure_term,
  digits = 2L,
  include_n = TRUE,
  include_aic = TRUE
)
```

## Arguments

- models:

  Named list of fitted model objects. Every element must be one of:
  `mysterycall_logistic_model`, `mysterycall_poisson_model`,
  `mysterycall_nb_model`, or `mysterycall_lmm`. Mixed model types are
  permitted (e.g. a logistic model alongside a Poisson model). At least
  one model is required.

- exposure_term:

  Character scalar. The exact term name to extract from each model's
  coefficient table (e.g. `"insuranceMedicaid"`, `"scenarioB"`). Must
  match the `term` column produced by the fitting function. When a model
  does not contain the term an em-dash (`"--"`) is placed in that
  column.

- digits:

  Integer. Number of decimal places for estimates and confidence
  interval bounds. Default `2L`.

- include_n:

  Logical. When `TRUE` (default) a "Sample size" row is appended at the
  bottom showing `N=<n>` for each model.

- include_aic:

  Logical. When `TRUE` (default) an "AIC" row is appended at the bottom
  showing the Akaike Information Criterion to one decimal place for each
  model. Note: AIC from models fitted with `REML = TRUE`
  (`mysterycall_lmm`) is not directly comparable to ML-fitted AIC.

## Value

A `data.frame` with columns:

- `Characteristic`:

  Row label: the exposure term (with metric type in parentheses), then
  optionally "Sample size" and "AIC".

- `<model name>`:

  One column per element of `models`, named by the list element name.
  The exposure row shows `"1.23 (0.98-1.54), p=0.071"`. The footer rows
  show `"N=160"` and `"210.4"` respectively. An em-dash is used when a
  term is absent from a model.

The data frame is suitable for passing directly to
[`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html),
[`flextable::flextable()`](https://davidgohel.github.io/flextable/reference/flextable.html),
or [`gt::gt()`](https://gt.rstudio.com/reference/gt.html) for Word/HTML
output.

## Details

This function is intentionally distinct from
[`mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_comparison_table.md),
which compares overall model fit statistics (AIC, BIC, phi). Here the
emphasis is on **how the exposure effect estimate changes** as
covariates are added or the analytic specification varies – the classic
sensitivity/robustness check for a primary manuscript table.

## Cell format

Each exposure-row cell follows the pattern:

    <estimate> (<ci_lower>-<ci_upper>), p=<p_value>

where `estimate` is:

- **OR** for `mysterycall_logistic_model` (exponentiated log-odds)

- **IRR** for `mysterycall_poisson_model` or `mysterycall_nb_model`
  (exponentiated log-rate)

- **beta** for `mysterycall_lmm` (coefficient in outcome units, e.g.
  days)

The metric label is appended to the `Characteristic` entry in
parentheses when all models share the same type; otherwise the bare term
is used and readers should consult footnotes.

## Typical workflow

1.  Fit a series of models of increasing complexity.

2.  Call `mysterycall_sensitivity_table()` with those models and the
    primary exposure term.

3.  Pass the result to
    [`flextable::flextable()`](https://davidgohel.github.io/flextable/reference/flextable.html)
    or [`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html) and
    insert into the manuscript.

## See also

[`mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_comparison_table.md)
for AIC/BIC/phi comparison;
[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md)
for the logistic model;
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
for the Poisson model;
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md)
for the negative binomial model;
[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md)
for the linear mixed model.

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
# ---- Build fake model objects with structure() -- no lme4 required --------

# Model 1: unadjusted logistic (only insurance)
m1 <- structure(
  list(
    or_table = data.frame(
      term        = c("(Intercept)", "insuranceMedicaid"),
      or          = c(3.50, 0.62),
      ci_lower    = c(2.10, 0.40),
      ci_upper    = c(5.80, 0.97),
      p_value     = c(0.0001, 0.036),
      p_value_fmt = c("< 0.001", "0.036"),
      stringsAsFactors = FALSE
    ),
    n   = 160L,
    aic = 210.4
  ),
  class = "mysterycall_logistic_model"
)

# Model 2: adjusted (insurance + practice setting)
m2 <- structure(
  list(
    or_table = data.frame(
      term        = c("(Intercept)", "insuranceMedicaid", "settingAcademic"),
      or          = c(3.20, 0.65, 1.18),
      ci_lower    = c(1.80, 0.42, 0.79),
      ci_upper    = c(5.70, 1.01, 1.77),
      p_value     = c(0.0003, 0.055, 0.417),
      p_value_fmt = c("< 0.001", "0.055", "0.417"),
      stringsAsFactors = FALSE
    ),
    n   = 160L,
    aic = 208.1
  ),
  class = "mysterycall_logistic_model"
)

# Model 3: adjusted + insurance x setting interaction
m3 <- structure(
  list(
    or_table = data.frame(
      term        = c("(Intercept)", "insuranceMedicaid",
                      "settingAcademic",
                      "insuranceMedicaid:settingAcademic"),
      or          = c(3.10, 0.68, 1.21, 0.85),
      ci_lower    = c(1.70, 0.43, 0.80, 0.51),
      ci_upper    = c(5.60, 1.07, 1.84, 1.42),
      p_value     = c(0.0005, 0.094, 0.371, 0.530),
      p_value_fmt = c("< 0.001", "0.094", "0.371", "0.530"),
      stringsAsFactors = FALSE
    ),
    n   = 160L,
    aic = 209.7
  ),
  class = "mysterycall_logistic_model"
)

tbl <- mysterycall_sensitivity_table(
  models        = list("Unadjusted" = m1,
                       "Adjusted"   = m2,
                       "+ Interaction" = m3),
  exposure_term = "insuranceMedicaid",
  digits        = 2L
)
print(tbl)
#>           Characteristic                Unadjusted                  Adjusted
#> 1 insuranceMedicaid (OR) 0.62 (0.40–0.97), p=0.036 0.65 (0.42–1.01), p=0.055
#> 2            Sample size                     N=160                     N=160
#> 3                    AIC                     210.4                     208.1
#>               + Interaction
#> 1 0.68 (0.43–1.07), p=0.094
#> 2                     N=160
#> 3                     209.7

# ---- Mixed model types: logistic + Poisson side by side -------------------
m_poisson <- structure(
  list(
    irr_table = data.frame(
      term        = c("(Intercept)", "insuranceMedicaid"),
      irr         = c(18.3, 1.41),
      ci_lower    = c(14.1, 1.08),
      ci_upper    = c(23.7, 1.84),
      p_value     = c(0.0001, 0.012),
      p_value_fmt = c("< 0.001", "0.012"),
      stringsAsFactors = FALSE
    ),
    n   = 145L,
    aic = 893.6
  ),
  class = "mysterycall_poisson_model"
)

tbl2 <- mysterycall_sensitivity_table(
  models        = list("Offered appt (OR)" = m2,
                       "Wait days (IRR)"   = m_poisson),
  exposure_term = "insuranceMedicaid",
  digits        = 2L
)
print(tbl2)
#>      Characteristic         Offered appt (OR)           Wait days (IRR)
#> 1 insuranceMedicaid 0.65 (0.42–1.01), p=0.055 1.41 (1.08–1.84), p=0.012
#> 2       Sample size                     N=160                     N=145
#> 3               AIC                     208.1                     893.6
```
