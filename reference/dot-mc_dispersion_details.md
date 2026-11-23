# Record an Auditable Dispersion Diagnostic

Bundles the dispersion statistic with the exact formula, denominator and
assumptions behind it, so a reader can reproduce the number rather than
having to infer which convention was used. The returned `df` is the
denominator actually divided by, so
`pearson_chisq / df == overdispersion` holds exactly.

## Usage

``` r
.mc_dispersion_details(
  method,
  formula,
  pearson_chisq,
  df,
  n,
  n_parameters,
  df_engine = NA_real_,
  n_pearson_na = NA_integer_
)
```

## Arguments

- method:

  Character scalar naming the convention.

- formula:

  Character scalar giving the computation verbatim.

- pearson_chisq:

  Numeric scalar. The Pearson chi-square statistic.

- df:

  Numeric scalar. The denominator actually used.

- n:

  Integer scalar. Observations in the fitted cohort.

- n_parameters:

  Integer scalar. Parameters debited by `df`.

- df_engine:

  Numeric scalar. The engine's own residual df, for comparison.
  `NA_real_` when the engine does not report one.

- n_pearson_na:

  Integer scalar. Pearson residuals that could not be computed. A
  non-zero value makes the statistic uninterpretable, and all of them
  being `NA` previously summed to a dispersion of exactly zero.

## Value

A named list describing the diagnostic.

## Choice of denominator

The count fitters divide the Pearson chi-square by `n - p_fixed`,
counting only the fixed-effect parameters.
[`stats::df.residual()`](https://rdrr.io/r/stats/df.residual.html) on a
`merMod` instead returns `n - (p_fixed + n_varpar)`, which also debits
the random-effect variance components, and so is smaller by the number
of variance parameters – one, for a single random intercept. The two
denominators therefore differ by one, and the resulting statistic by a
factor of roughly `1 + 1/df`.

Both conventions appear in practice, and the Pearson statistic is in any
case only an approximate dispersion diagnostic for a GLMM: its reference
chi-square distribution is asymptotic and does not strictly hold once
random effects are estimated. `df_engine` is recorded alongside `df` so
the difference is visible and auditable; the statistic reported in
`$overdispersion` is unchanged from previous releases, and changing the
convention is a separate decision that would move published numbers.

## See also

Other model-accessors:
[`.mc_coefficient_table()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_coefficient_table.md),
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
[`summary.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/summary.mysterycall.md),
[`vcov.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/vcov.mysterycall.md)
