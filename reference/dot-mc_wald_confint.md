# Build a Wald Confidence Interval Matrix

Build a Wald Confidence Interval Matrix

## Usage

``` r
.mc_wald_confint(object, parm, level, call_name)
```

## Arguments

- object:

  A mysterycall fitted-model object.

- parm:

  Optional parameter selection.

- level:

  Numeric scalar confidence level.

- call_name:

  Character scalar naming the accessor, for errors.

## Value

Numeric matrix of link-scale bounds.

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
[`coef.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/coef.mysterycall.md),
[`confint.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/confint.mysterycall.md),
[`fitted.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/fitted.mysterycall.md),
[`formula.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/formula.mysterycall.md),
[`nobs.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/nobs.mysterycall.md),
[`print.mysterycall_model_summary()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_summary.md),
[`residuals.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/residuals.mysterycall.md),
[`summary.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/summary.mysterycall.md),
[`vcov.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/vcov.mysterycall.md)
