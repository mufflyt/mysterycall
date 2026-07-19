# Compute R-squared values and generate an interpretive sentence for mixed models

Extracts marginal (fixed-effects only) and conditional (fixed + random
effects) R^2 values from a fitted mixed model using
[`performance::r2()`](https://easystats.github.io/performance/reference/r2.html),
then formats them into a manuscript-ready interpretive paragraph.

## Usage

``` r
mysterycall_r2_sentence(model, digits = 3, digits_pct = 1)
```

## Arguments

- model:

  A fitted mixed model (`glmerMod`, `lmerMod`, etc.) compatible with
  [`performance::r2()`](https://easystats.github.io/performance/reference/r2.html).
  Pure fixed-effects models (e.g., `lm`, `glm`) are not supported and
  will trigger an error.

- digits:

  Integer scalar. Number of decimal places for R^2 values in the
  sentence. Default `3`.

- digits_pct:

  Integer scalar. Number of decimal places for percentage values in the
  sentence. Default `1`.

## Value

A named list with:

- `marginal_r2`:

  Numeric. Marginal R^2 (fixed effects only).

- `conditional_r2`:

  Numeric. Conditional R^2 (fixed + random effects).

- `fixed_effects`:

  Character vector of fixed-effect term names.

- `random_effects`:

  Character vector of random-effect group names.

- `sentence`:

  Character scalar. Full interpretive paragraph.

## See also

[`mysterycall_random_effect_variance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_random_effect_variance.md)
for ICC-based random-effect interpretation;
[`performance::r2()`](https://easystats.github.io/performance/reference/r2.html)
for the underlying computation.

Other modeling helpers:
[`mysterycall_check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_normality.md),
[`mysterycall_create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_formula.md),
[`mysterycall_interaction_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_screen.md),
[`mysterycall_overdispersion_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_sentence.md),
[`mysterycall_plot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_interaction.md),
[`mysterycall_random_effect_variance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_random_effect_variance.md),
[`mysterycall_univariate_lmm_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_lmm_screen.md),
[`mysterycall_univariate_poisson_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_poisson_screen.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(lme4)
m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
res <- mysterycall_r2_sentence(m)
cat(res$sentence)
} # }
```
