# Screen predictors one-at-a-time using a linear mixed model

For each predictor (excluding `outcome_col`, `random_effect`, and any
`exclude_cols`), fits a linear mixed model using
[`lmerTest::lmer()`](https://rdrr.io/pkg/lmerTest/man/lmer.html) with
`REML = FALSE`, then extracts the fixed-effect estimate, standard error,
and p-value from the second row of the coefficient table (the predictor
row). Predictors with only one unique non-NA value are skipped with a
message.

## Usage

``` r
mysterycall_univariate_lmm_screen(
  data,
  outcome_col = "business_days_until_appointment",
  random_effect = "last",
  exclude_cols = c(outcome_col, random_effect, "record_id", "middle", "first", "phone",
    "zip", "notes", "address"),
  alpha = 0.2,
  p_adjust_method = "none",
  output_dir = NULL,
  filename = "univariate_lmm_screen.csv"
)
```

## Arguments

- data:

  A data frame. Rows where `outcome_col` is `NA` are dropped.

- outcome_col:

  Character scalar. The numeric outcome column. Default
  `"business_days_until_appointment"`.

- random_effect:

  Character scalar. Column used as the random intercept
  `(1 | random_effect)`. Default `"last"`.

- exclude_cols:

  Character vector. Columns to exclude from the predictor loop. Default
  includes `outcome_col`, `random_effect`, and common identifier /
  free-text columns.

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
  `"univariate_lmm_screen.csv"`.

## Value

A named list with four elements:

- `results`:

  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  with columns `Predictor`, `P_Value`, `P_Formatted`, `IRR`, `CI_Lower`,
  `CI_Upper` for every predictor attempted.

- `significant`:

  Subset of `results` where `P_Value < alpha`, sorted ascending by
  `P_Value`.

- `sentence`:

  Character scalar summarising significant predictors.

- `alpha`:

  The threshold used.

## Details

Incidence rate ratios (IRR) and 95 % Wald confidence intervals on the
exponential scale are returned for convenient forest-plot input, even
though the underlying model is linear (not Poisson).

## See also

[`mysterycall_univariate_poisson_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_poisson_screen.md),
[`mysterycall_interaction_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_screen.md)

Other modeling helpers:
[`mysterycall_check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_normality.md),
[`mysterycall_create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_formula.md),
[`mysterycall_interaction_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_screen.md),
[`mysterycall_overdispersion_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_sentence.md),
[`mysterycall_plot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_interaction.md),
[`mysterycall_r2_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_r2_sentence.md),
[`mysterycall_random_effect_variance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_random_effect_variance.md),
[`mysterycall_univariate_poisson_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_poisson_screen.md)

## Examples

``` r
set.seed(1)
df <- data.frame(
  business_days_until_appointment = rpois(60, 10),
  insurance = rep(c("BCBS", "Medicaid"), 30),
  gender    = rep(c("M", "F"), 30),
  last      = rep(paste0("Dr", 1:10), each = 6),
  stringsAsFactors = FALSE
)
res <- mysterycall_univariate_lmm_screen(df, output_dir = NA)
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
```
