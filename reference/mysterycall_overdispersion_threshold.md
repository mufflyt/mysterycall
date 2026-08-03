# Canonical overdispersion threshold for Poisson-vs-negative-binomial choice

Every function in the package that reduces a Pearson dispersion
statistic (phi = sum(pearson_resid^2) / resid_df) to a "keep Poisson vs
switch to negative binomial" decision routes through this single value,
so the model choice can never again diverge between the automated
selector and the standalone diagnostics. When phi exceeds the threshold,
a negative-binomial (or otherwise overdispersion-robust) model is
recommended.

## Usage

``` r
mysterycall_overdispersion_threshold()
```

## Value

A single positive number: the current overdispersion threshold.

## Details

The default is `1.5`, a common overdispersion rule of thumb. Override it
globally with `options(mysterycall.overdispersion_threshold = <value>)`;
every consumer
([`mysterycall_auto_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_auto_model.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_simple_poisson()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_simple_poisson.md),
[`mysterycall_overdispersion_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_test.md),
[`mysterycall_overdispersion_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_sentence.md),
[`mysterycall_marginal_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_marginal_power.md))
picks up the new value through its default argument.

## See also

[`mysterycall_auto_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_auto_model.md),
[`mysterycall_overdispersion_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_test.md)

## Examples

``` r
mysterycall_overdispersion_threshold()
#> [1] 1.5
withr::with_options(
  list(mysterycall.overdispersion_threshold = 2.0),
  mysterycall_overdispersion_threshold()
)
#> [1] 2
```
