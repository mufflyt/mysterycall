# Summarise a mysterycall Model

Collects the cohort size, formula, coefficient table, dispersion
diagnostic and convergence status into one object of class
`mysterycall_model_summary`. The engine's own summary remains available
as `summary(object$model)`.

## Usage

``` r
# S3 method for class 'mysterycall_poisson_model'
summary(object, ...)

# S3 method for class 'mysterycall_nb_model'
summary(object, ...)

# S3 method for class 'mysterycall_lmm'
summary(object, ...)

# S3 method for class 'mysterycall_logistic_model'
summary(object, ...)
```

## Arguments

- object:

  A mysterycall fitted-model object.

- ...:

  Ignored, present for generic compatibility.

## Value

An object of class `mysterycall_model_summary`.

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
[`fitted.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/fitted.mysterycall.md),
[`formula.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/formula.mysterycall.md),
[`nobs.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/nobs.mysterycall.md),
[`print.mysterycall_model_summary()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_summary.md),
[`residuals.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/residuals.mysterycall.md),
[`vcov.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/vcov.mysterycall.md)
