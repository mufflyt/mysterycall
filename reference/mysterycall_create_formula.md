# Create a Formula for Poisson Model

This function creates a formula for a Poisson model based on the
provided data, response variable, and optional random effect.

## Usage

``` r
mysterycall_create_formula(data, response_var, random_effect = NULL)
```

## Arguments

- data:

  A data frame containing all predictor and response variables. Factor
  columns are detected automatically and included as-is; all other
  non-response columns are treated as fixed-effect predictors.

- response_var:

  Character scalar naming the count/numeric response (outcome) column in
  `data`.

- random_effect:

  Optional character scalar naming a grouping column to add as a random
  intercept `(1 | random_effect)` term, e.g. `"physician"`. Default
  `NULL` (no random effects; produces a fixed-effects-only formula).

## Value

A `formula` object. When `random_effect` is `NULL` the formula is
suitable for [`stats::glm()`](https://rdrr.io/r/stats/glm.html); when
provided it is suitable for
[`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html).

## See also

[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
which uses this formula builder internally.

Other modeling helpers:
[`mysterycall_check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_normality.md),
[`mysterycall_interaction_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_screen.md),
[`mysterycall_overdispersion_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_sentence.md),
[`mysterycall_plot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_interaction.md),
[`mysterycall_r2_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_r2_sentence.md),
[`mysterycall_random_effect_variance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_random_effect_variance.md),
[`mysterycall_univariate_lmm_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_lmm_screen.md),
[`mysterycall_univariate_poisson_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_poisson_screen.md)

## Examples

``` r
df <- data.frame(days = c(5, 10, 15), age = c(30, 40, 50), name = c("A", "B", "C"))
mysterycall_create_formula(df, "days", random_effect = "name")
#> Creating formula with response variable: days
#> Predictor variables identified: age
#> Predictor variables after formatting: `age`
#> Initial formula string: days ~ `age`
#> Formula string with random effect: days ~ `age` + (1 | name )
#> Final formula object created: days ~ age + (1 | name)
#> days ~ age + (1 | name)
#> <environment: 0x56231c2513a8>
mysterycall_create_formula(df, "days")  # fixed-effects only
#> Creating formula with response variable: days
#> Predictor variables identified: age, name
#> Predictor variables after formatting: `age`, `name`
#> Initial formula string: days ~ `age` + `name`
#> Final formula object created: days ~ age + name
#> days ~ age + name
#> <environment: 0x56231d78b1c0>
```
