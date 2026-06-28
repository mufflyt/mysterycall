# Screen predictors one-at-a-time using univariate Poisson GLMs

For each predictor (excluding `outcome_col` and any `exclude_cols`),
fits a simple Poisson GLM (no random effects) using
[`stats::glm()`](https://rdrr.io/r/stats/glm.html) with
`family = poisson(link = "log")`. Predictors with only one unique value
are skipped with a message.

## Usage

``` r
mysterycall_univariate_poisson_screen(
  data,
  outcome_col = "business_days_until_appointment",
  exclude_cols = outcome_col,
  alpha = 0.2,
  p_adjust_method = "none",
  output_dir = NULL,
  filename = "univariate_poisson_screen.csv"
)
```

## Arguments

- data:

  A data frame.

- outcome_col:

  Character scalar. The count or binary outcome column.

- exclude_cols:

  Character vector. Columns to exclude from the predictor loop. Default
  is `outcome_col` alone; supply additional columns as needed.

- alpha:

  Numeric. Significance threshold for the `$significant` table. Default
  `0.2`.

- p_adjust_method:

  Character scalar passed to
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html) after all
  raw p-values are collected. `"none"` (default) skips adjustment and
  preserves existing behaviour. Common choices: `"BH"`, `"bonferroni"`,
  `"holm"`. When not `"none"`, a `P_Value_Adjusted` column is added to
  `$results` and significance is evaluated against the adjusted values.

- output_dir:

  Character scalar or `NULL`. Directory for CSV output. `NULL` uses
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).
  Pass `NA` to skip writing.

- filename:

  Character scalar. CSV file name. Default
  `"univariate_poisson_screen.csv"`.

## Value

A named list with four elements:

- `results`:

  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  with columns `Variable`, `P_Value`, `Formatted_P_Value`, `Direction`
  for every predictor attempted.

- `significant`:

  Subset of `results` where `P_Value < alpha`, sorted ascending by
  `P_Value`.

- `sentence`:

  Character scalar summarising significant predictors.

- `alpha`:

  The threshold used.

## Details

Direction of association is determined from the sign of the predictor
coefficient: positive estimates are labelled `"Higher"` and negative
estimates `"Lower"`.

## See also

[`mysterycall_univariate_lmm_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_lmm_screen.md),
[`mysterycall_interaction_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_screen.md)

Other modeling helpers:
[`mysterycall_check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_normality.md),
[`mysterycall_create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_formula.md),
[`mysterycall_interaction_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_screen.md),
[`mysterycall_overdispersion_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_sentence.md),
[`mysterycall_plot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_interaction.md),
[`mysterycall_r2_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_r2_sentence.md),
[`mysterycall_random_effect_variance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_random_effect_variance.md),
[`mysterycall_univariate_lmm_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_lmm_screen.md)

## Examples

``` r
set.seed(1)
df <- data.frame(
  wait_days = rpois(60, 10),
  insurance = rep(c("BCBS", "Medicaid"), 30),
  gender    = rep(c("M", "F"), 30),
  stringsAsFactors = FALSE
)
res <- mysterycall_univariate_poisson_screen(
  df, outcome_col = "wait_days", output_dir = NA
)
```
