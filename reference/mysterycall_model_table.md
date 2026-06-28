# Word-ready IRR table from a fitted Poisson model

Extracts and formats the fixed-effects table from a
`mysterycall_poisson_model` result into a print-ready data frame. Column
names and values follow standard epidemiological reporting conventions
(IRR with 95% CI in a single "IRR (95% CI)" column, formatted p-values).
The returned data frame can be passed directly to
[`flextable::flextable()`](https://davidgohel.github.io/flextable/reference/flextable.html)
or [`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html) for
Word/HTML output.

## Usage

``` r
mysterycall_model_table(
  x,
  include_intercept = FALSE,
  digits = 2L,
  irr_col = "IRR (95% CI)",
  p_col = "p-value",
  term_col = "Term"
)
```

## Arguments

- x:

  A `mysterycall_poisson_model` object from
  [`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
  or a `mysterycall_nb_model` object from
  [`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md).

- include_intercept:

  Logical. When `FALSE` (default) the `(Intercept)` row is dropped.

- digits:

  Integer. Decimal places for IRR and CI values. Default `2`.

- irr_col:

  Character. Name of the combined "IRR (95% CI)" column. Default
  `"IRR (95% CI)"`.

- p_col:

  Character. Name of the p-value column. Default `"p-value"`.

- term_col:

  Character. Name of the term column. Default `"Term"`.

## Value

A data frame (tibble) with columns `term_col`, `irr_col`, and `p_col`.
One row per fixed-effect term.

## See also

[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_irr_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_plot.md)

Other table helpers:
[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md),
[`mysterycall_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_pct.md),
[`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md),
[`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md),
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md),
[`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md),
[`print.mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_disparities_table.md)

## Examples

``` r
if (requireNamespace("lme4", quietly = TRUE)) {
  set.seed(1978)
  df <- data.frame(
    wait_days = rpois(40, lambda = 18),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    physician = rep(paste0("Dr_", 1:8), each = 5),
    stringsAsFactors = FALSE
  )
  result <- suppressWarnings(mysterycall_poisson_model(
    df, "wait_days", "insurance", "physician"
  ))
  mysterycall_model_table(result)
}
#> Fitting Poisson GLMER: wait_days ~ insurance + (1 | physician)
#> boundary (singular) fit: see help('isSingular')
#> Convergence issues detected:
#>   boundary (singular) fit: see help('isSingular')
#> Consider simplifying predictors or using nAGQ = 1.
#> Singular fit: random-intercept variance is ~0. The physician-level random effect explains little variation.
#> Model fitted: n=40, physicians=8, AIC=229.1, overdispersion=0.89
#>                Term     IRR (95% CI) p-value
#> 1 insuranceMedicaid 1.01 (0.87-1.17)   0.883
```
