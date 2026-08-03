# Analytic power for factorial linear-model terms via Cohen's f-squared

A saturated factorial audit model (e.g.
`rural * subspecialty * insurance`) has a main effect and interaction
for every term, each an F-test with its own numerator degrees of
freedom. This reports the total sample size each term needs at a target
power, using
[`pwr::pwr.f2.test()`](https://rdrr.io/pkg/pwr/man/pwr.f2.test.html)
with the correct numerator df and adding back the full model's parameter
count so the returned figure is a usable N rather than a residual df.

## Usage

``` r
mysterycall_lm_interaction_power(
  terms,
  n_params,
  f2 = c(small = 0.02, medium = 0.15),
  alpha = 0.05,
  power = 0.9
)
```

## Arguments

- terms:

  Either a named integer vector mapping term label to numerator df (e.g.
  `c("rural" = 1, "rural x subspec" = 6)`), or a data frame with columns
  `term` and `df_num`.

- n_params:

  Number of parameters (cell means) in the full saturated model, e.g.
  `2 * n_subspec * n_insurance`. Added, with an intercept, to the solved
  residual df to give a total N.

- f2:

  Named numeric vector of Cohen's f-squared effect sizes to report.
  Default `c(small = 0.02, medium = 0.15)`.

- alpha:

  Significance level. Default `0.05`.

- power:

  Target power. Default `0.90`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html),
one row per term: `term`, `df_num`, and one `n_<name>` column per `f2`
entry giving the required total N.

## Details

Requires the pwr package.

## See also

[`mysterycall_ttest_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ttest_power.md),
[`mysterycall_joint_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_joint_test.md)

Other power:
[`mysterycall_adjusted_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_adjusted_power.md),
[`mysterycall_ttest_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ttest_power.md)

## Examples

``` r
if (requireNamespace("pwr", quietly = TRUE)) {
  mysterycall_lm_interaction_power(
    terms = c("rural" = 1, "subspecialty" = 6, "rural x insurance" = 1),
    n_params = 2 * 7 * 2
  )
}
#> # A tibble: 3 × 4
#>   term              df_num n_small n_medium
#>   <chr>              <int>   <int>    <int>
#> 1 rural                  1     555      100
#> 2 subspecialty           6     900      145
#> 3 rural x insurance      1     555      100
```
