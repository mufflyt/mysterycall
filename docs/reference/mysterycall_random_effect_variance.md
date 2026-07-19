# Compute random-effect variance components and ICC for mixed models

Extracts variance components from a fitted mixed model via
[`lme4::VarCorr()`](https://rdrr.io/pkg/nlme/man/VarCorr.html), computes
the intraclass correlation coefficient (ICC), and generates a
manuscript-ready interpretive sentence. Handles Poisson GLMER models
where the residual scale parameter (`sc`) is unavailable by returning
`icc = NA` with an informative message.

## Usage

``` r
mysterycall_random_effect_variance(
  model,
  variance_threshold = 0.01,
  digits = 3
)
```

## Arguments

- model:

  A fitted mixed model (`glmerMod`, `lmerMod`, etc.) from lme4.

- variance_threshold:

  Numeric scalar \\\ge 0\\. Variance components with
  `vcov > variance_threshold` are flagged as `"Yes"` in the `$var_table`
  column `Significant`. Default `0.01`.

- digits:

  Integer scalar. Number of decimal places for the ICC in the sentence.
  Default `3`.

## Value

A named list with:

- `icc`:

  Numeric or `NA`. Intraclass correlation coefficient.

- `random_variance`:

  Numeric. Variance of the first random-effect group.

- `residual_variance`:

  Numeric or `NA`. Residual variance (`sc^2`). `NA` for Poisson GLMER.

- `random_effect_group`:

  Character. Name of the first random-effect grouping factor.

- `var_table`:

  Data frame. Output of `as.data.frame(VarCorr(model))` with an
  additional logical column `Significant`.

- `interpretation`:

  Character scalar. One of `"high"`, `"moderate"`, `"low to moderate"`,
  or `"low"`.

- `sentence`:

  Character scalar. Full ICC sentence and interpretation paragraph.

## See also

[`mysterycall_r2_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_r2_sentence.md)
for marginal and conditional R²;
[`lme4::VarCorr()`](https://rdrr.io/pkg/nlme/man/VarCorr.html) for the
underlying computation.

Other modeling helpers:
[`mysterycall_check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_normality.md),
[`mysterycall_create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_formula.md),
[`mysterycall_interaction_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_screen.md),
[`mysterycall_overdispersion_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_sentence.md),
[`mysterycall_plot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_interaction.md),
[`mysterycall_r2_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_r2_sentence.md),
[`mysterycall_univariate_lmm_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_lmm_screen.md),
[`mysterycall_univariate_poisson_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_poisson_screen.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(lme4)
m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
res <- mysterycall_random_effect_variance(m)
cat(res$sentence)
} # }
```
