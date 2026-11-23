# Fitted Values of a mysterycall Model

Returns the engine's fitted values. For the mixed models these are
**conditional** on the estimated random effects and on the response
scale (expected wait-time counts for the count models, probabilities for
the logistic model) – not marginal, population-average predictions. For
marginal predictions over a covariate profile use
[`mysterycall_predicted_means()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_predicted_means.md)
or
[`mysterycall_marginal_effects()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_marginal_effects.md).

## Usage

``` r
# S3 method for class 'mysterycall_poisson_model'
fitted(object, ...)

# S3 method for class 'mysterycall_nb_model'
fitted(object, ...)

# S3 method for class 'mysterycall_lmm'
fitted(object, ...)

# S3 method for class 'mysterycall_logistic_model'
fitted(object, ...)
```

## Arguments

- object:

  A mysterycall fitted-model object.

- ...:

  Passed to the engine's
  [`fitted()`](https://rdrr.io/r/stats/fitted.values.html) method.

## Value

Numeric vector of fitted values, one per fitted observation.

## See also

Other model-accessors:
[`.mc_coefficient_table()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_coefficient_table.md),
[`.mc_dispersion_details()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_dispersion_details.md),
[`.mc_dispersion_ratio()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_dispersion_ratio.md),
[`.mc_engine_fit()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_engine_fit.md),
[`.mc_fitted_model_classes()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_fitted_model_classes.md),
[`.mc_fixed_effect_df()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_fixed_effect_df.md),
[`.mc_fixed_effects()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_fixed_effects.md),
[`.mc_fixed_vcov()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_fixed_vcov.md),
[`.mc_model_formula()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_model_formula.md),
[`.mc_model_summary()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_model_summary.md),
[`.mc_reject_cohort_altering_args()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_reject_cohort_altering_args.md),
[`.mc_wald_confint()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_wald_confint.md),
[`coef.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/coef.mysterycall.md),
[`confint.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/confint.mysterycall.md),
[`formula.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/formula.mysterycall.md),
[`nobs.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/nobs.mysterycall.md),
[`print.mysterycall_model_summary()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_summary.md),
[`residuals.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/residuals.mysterycall.md),
[`summary.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/summary.mysterycall.md),
[`vcov.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/vcov.mysterycall.md)
