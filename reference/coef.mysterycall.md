# Fixed-Effect Coefficients of a mysterycall Model

Returns the fixed-effect estimates on the link scale, exactly as the
underlying engine reports them
([`lme4::fixef()`](https://rdrr.io/pkg/nlme/man/fixed.effects.html) for
`glmerMod`/`lmerMod`, the conditional component of
[`glmmTMB::fixef()`](https://rdrr.io/pkg/nlme/man/fixed.effects.html)
for `glmmTMB`). Random effects are not included; use
[`lme4::ranef()`](https://rdrr.io/pkg/nlme/man/random.effects.html) on
`$model` for those.

## Usage

``` r
# S3 method for class 'mysterycall_poisson_model'
coef(object, ...)

# S3 method for class 'mysterycall_nb_model'
coef(object, ...)

# S3 method for class 'mysterycall_lmm'
coef(object, ...)

# S3 method for class 'mysterycall_logistic_model'
coef(object, ...)
```

## Arguments

- object:

  A mysterycall fitted-model object.

- ...:

  Ignored, present for generic compatibility.

## Value

Named numeric vector of fixed-effect estimates on the link scale.

## Details

For a count model with a log link, `exp(coef(object))` gives the
incidence rate ratios reported in `object$irr_table$irr`.

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
[`confint.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/confint.mysterycall.md),
[`fitted.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/fitted.mysterycall.md),
[`formula.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/formula.mysterycall.md),
[`nobs.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/nobs.mysterycall.md),
[`print.mysterycall_model_summary()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_summary.md),
[`residuals.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/residuals.mysterycall.md),
[`summary.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/summary.mysterycall.md),
[`vcov.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/vcov.mysterycall.md)
