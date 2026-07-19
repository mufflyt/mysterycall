# Test for overdispersion and generate an interpretive sentence

Computes Pearson chi-square–based dispersion statistics for a fitted
model (GLM or GLMER), categorises the result, and returns a
manuscript-ready sentence. Suitable for Poisson and quasi-Poisson models
as well as linear models (`lm`) which also expose
[`df.residual()`](https://rdrr.io/r/stats/df.residual.html).

## Usage

``` r
mysterycall_overdispersion_sentence(model, digits_ratio = 2, digits_p = 3)
```

## Arguments

- model:

  A fitted model with
  [`df.residual()`](https://rdrr.io/r/stats/df.residual.html),
  `residuals(type = "pearson")`, and `df.residual > 0`.

- digits_ratio:

  Integer scalar. Decimal places for the dispersion ratio in the
  sentence. Default `2`.

- digits_p:

  Integer scalar. Decimal places for the p-value in the sentence.
  Default `3`.

## Value

A named list with:

- `chisq`:

  Numeric. Pearson chi-square statistic.

- `ratio`:

  Numeric. Dispersion ratio (\\\chi^2 / df\\).

- `df`:

  Numeric. Residual degrees of freedom.

- `p_value`:

  Numeric. Upper-tail chi-square p-value.

- `p_formatted`:

  Character. Formatted p-value string.

- `interpretation`:

  Character. Tiered interpretation message.

- `sentence`:

  Character. Full manuscript sentence.

- `overdispersed`:

  Logical. `TRUE` when `p_value < 0.05` AND `ratio > 1.2`.

## See also

[`mysterycall_random_effect_variance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_random_effect_variance.md)
for random-effect ICC;
[`mysterycall_r2_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_r2_sentence.md)
for R² interpretation.

Other modeling helpers:
[`mysterycall_check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_normality.md),
[`mysterycall_create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_formula.md),
[`mysterycall_interaction_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_screen.md),
[`mysterycall_plot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_interaction.md),
[`mysterycall_r2_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_r2_sentence.md),
[`mysterycall_random_effect_variance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_random_effect_variance.md),
[`mysterycall_univariate_lmm_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_lmm_screen.md),
[`mysterycall_univariate_poisson_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_poisson_screen.md)

## Examples

``` r
m <- glm(breaks ~ wool + tension, data = warpbreaks, family = poisson)
res <- mysterycall_overdispersion_sentence(m)
cat(res$sentence)
#> The Pearson dispersion ratio is 4.26 (chi-square = 213.08, df = 50, p = < 0.001). Significant overdispersion detected (ratio = 4.26). Consider using a Negative Binomial model to account for overdispersion.
```
