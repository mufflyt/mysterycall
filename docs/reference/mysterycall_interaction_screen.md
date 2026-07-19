# Screen all pairwise factor interactions using linear mixed models

For every pair of factor columns in `data` (excluding `outcome_col` and
`random_effect`), fits a linear mixed model with an interaction term
using [`lmerTest::lmer()`](https://rdrr.io/pkg/lmerTest/man/lmer.html).
Pairs that yield at least one significant non-intercept coefficient (p
\<= `alpha`) are collected. AIC is computed for every model that
converges, allowing the best-fitting interaction to be identified.

## Usage

``` r
mysterycall_interaction_screen(
  data,
  outcome_col = "business_days_until_appointment",
  random_effect = "last",
  alpha = 0.05,
  p_adjust_method = "none",
  max_pairs = 50L,
  output_dir = NULL,
  filename = "interaction_screen.csv"
)
```

## Arguments

- data:

  A data frame. Rows where `outcome_col` is `NA` are dropped.

- outcome_col:

  Character scalar. Numeric outcome column. Default
  `"business_days_until_appointment"`.

- random_effect:

  Character scalar. Column for the random intercept. Default `"last"`.

- alpha:

  Numeric. P-value threshold for a pair to be considered significant.
  Default `0.05`.

- p_adjust_method:

  Character scalar passed to
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html) after all
  raw per-pair p-values are collected. `"none"` (default) skips
  adjustment and preserves existing behaviour. Common choices: `"BH"`,
  `"bonferroni"`, `"holm"`. When not `"none"`, a `P_Value_Adjusted`
  column is added to `$interaction_results` and significance is
  evaluated against the adjusted values.

- max_pairs:

  Integer. Maximum pairs to test. When the pool exceeds this,
  `max_pairs` pairs are sampled randomly with `set.seed(42)`. Default
  `50L`.

- output_dir:

  Character scalar or `NULL`. Directory for CSV output. `NULL` uses
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).
  Pass `NA` to skip writing.

- filename:

  Character scalar. CSV file name. Default `"interaction_screen.csv"`.

## Value

A named list:

- `interaction_results`:

  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  with columns `Interaction` and `P_Value` for significant interactions.

- `aic_results`:

  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  with columns `Interaction` and `AIC` for every converged model.

- `best_interaction`:

  Single-row tibble (lowest AIC), or `NULL` if no models converged.

- `n_pairs_tested`:

  Integer. Number of pairs actually tested.

- `sentence`:

  Character scalar summarising the result.

## Details

When the number of possible pairs exceeds `max_pairs`, a random sample
of `max_pairs` pairs is drawn with `set.seed(42)`.

## See also

[`mysterycall_univariate_lmm_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_lmm_screen.md),
[`mysterycall_univariate_poisson_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_poisson_screen.md)

Other modeling helpers:
[`mysterycall_check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_normality.md),
[`mysterycall_create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_formula.md),
[`mysterycall_overdispersion_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_sentence.md),
[`mysterycall_plot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_interaction.md),
[`mysterycall_r2_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_r2_sentence.md),
[`mysterycall_random_effect_variance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_random_effect_variance.md),
[`mysterycall_univariate_lmm_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_lmm_screen.md),
[`mysterycall_univariate_poisson_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_poisson_screen.md)

## Examples

``` r
set.seed(1)
df <- data.frame(
  business_days_until_appointment = rpois(60, 10),
  insurance = factor(rep(c("BCBS", "Medicaid"), 30)),
  gender    = factor(rep(c("M", "F"), 30)),
  last      = rep(paste0("Dr", 1:10), each = 6),
  stringsAsFactors = FALSE
)
res <- mysterycall_interaction_screen(df, output_dir = NA)
#> fixed-effect model matrix is rank deficient so dropping 2 columns / coefficients
#> boundary (singular) fit: see help('isSingular')
```
