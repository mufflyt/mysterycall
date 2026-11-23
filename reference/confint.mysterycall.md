# Wald Confidence Intervals for a mysterycall Model

Intervals are **Wald** intervals on the link scale, computed from
[`vcov()`](https://rdrr.io/r/stats/vcov.html). They use the same
critical-value convention the fitter itself used, so they agree with the
interval the object already reports: a normal quantile for the count and
logistic models, and the Satterthwaite \\t\\ quantile with the per-term
degrees of freedom for `mysterycall_lmm`, where a normal quantile would
be anticonservative at small residual df.

## Usage

``` r
# S3 method for class 'mysterycall_poisson_model'
confint(object, parm, level = NULL, ...)

# S3 method for class 'mysterycall_nb_model'
confint(object, parm, level = NULL, ...)

# S3 method for class 'mysterycall_lmm'
confint(object, parm, level = NULL, ...)

# S3 method for class 'mysterycall_logistic_model'
confint(object, parm, level = NULL, ...)
```

## Arguments

- object:

  A mysterycall fitted-model object.

- parm:

  Optional character or numeric selection of parameters.

- level:

  Numeric scalar confidence level. Defaults to the level the model was
  fitted with.

- ...:

  Ignored, present for generic compatibility.

## Value

Numeric matrix with two columns of link-scale interval bounds.

## Details

`level` defaults to the `conf_level` the model was **fitted** with, not
to `0.95`. A model fitted at 90% therefore reports a 90% interval here,
which is what `object$irr_table` (or `$coef_table` / `$or_table`)
contains. Passing `level` explicitly recomputes the interval at that
level.

These are not profile-likelihood or bootstrap intervals. For a
profile-likelihood interval on a mixed model, call
`stats::confint(object$model, method = "profile")` directly and expect
it to be considerably slower.

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
[`fitted.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/fitted.mysterycall.md),
[`formula.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/formula.mysterycall.md),
[`nobs.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/nobs.mysterycall.md),
[`print.mysterycall_model_summary()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_summary.md),
[`residuals.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/residuals.mysterycall.md),
[`summary.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/summary.mysterycall.md),
[`vcov.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/vcov.mysterycall.md)
