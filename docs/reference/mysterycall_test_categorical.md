# Association Test for a Contingency Table (auto chi-squared / Fisher)

Cross-tabulates two categorical variables and tests their association,
automatically falling back from Pearson's chi-squared to an exact test
when expected cell counts are small – the standard pattern in
mystery-caller audits (Lungfiel 2023, Sharma 2025, Hodson 2025). Reports
Cramer's V as an effect size and, optionally,
Benjamini-Hochberg-adjusted post-hoc pairwise proportion comparisons
when the outcome is binary.

## Usage

``` r
mysterycall_test_categorical(
  data,
  row_var,
  col_var,
  method = c("auto", "chisq", "fisher"),
  min_expected = 5,
  correct = TRUE,
  posthoc = FALSE,
  p_adjust = "BH",
  conf_level = 0.95
)
```

## Arguments

- data:

  A data frame.

- row_var, col_var:

  Character scalars. Names of the two categorical columns to
  cross-tabulate.

- method:

  Character. `"auto"` (default) uses an exact test when any expected
  count is `< min_expected`, otherwise chi-squared; `"chisq"` and
  `"fisher"` force the choice. For tables larger than 2x2 the exact test
  is the Fisher-Freeman-Halton test (simulated if the exact computation
  is infeasible).

- min_expected:

  Numeric. Expected-count threshold that triggers the exact test under
  `"auto"`. Default `5`.

- correct:

  Logical. Apply Yates' continuity correction for 2x2 chi-squared tests.
  Default `TRUE`.

- posthoc:

  Logical. If `TRUE` and the outcome is binary and the overall test is
  significant at `1 - conf_level`, compute pairwise proportion
  comparisons across the other variable's levels. Default `FALSE`.

- p_adjust:

  Character. Multiple-comparison method for post-hoc p-values, passed to
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html). Default
  `"BH"`.

- conf_level:

  Numeric. Confidence level (drives the post-hoc alpha). Default `0.95`.

## Value

A `mysterycall_categorical_test` object: a list with `method`,
`statistic`, `df`, `p_value`, `cramers_v`, `effect_size` (label), `n`,
`min_expected`, `table`, and `posthoc` (a tibble or `NULL`).

## See also

Other categorical:
[`mysterycall_cmh_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cmh_test.md),
[`mysterycall_compare_ranks()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compare_ranks.md),
[`mysterycall_prevalence_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prevalence_ci.md)

## Examples

``` r
df <- data.frame(
  offered = c(rep("yes", 30), rep("no", 10), rep("yes", 18), rep("no", 22)),
  payer   = c(rep("commercial", 40), rep("medicaid", 40))
)
res <- mysterycall_test_categorical(df, "offered", "payer", posthoc = TRUE)
res
#> <mysterycall_categorical_test> offered x payer
#>   Pearson's chi-squared (Yates' correction)
#>   statistic = 6.302, df = 1, p = 0.012
#>   Cramer's V = 0.306 (medium); n = 80
#>   post-hoc pairwise proportions (BH-adjusted):
#>      group1   group2 prop1 prop2 p_value  p_adj
#>  commercial medicaid  0.25  0.55  0.0121 0.0121
```
