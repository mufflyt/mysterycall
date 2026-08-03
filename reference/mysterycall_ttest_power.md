# Analytic power for a two-group continuous outcome under unequal allocation

The package's analytic power tools are all count/binary; a
mystery-caller study with a continuous outcome (wait days) and a *fixed
natural allocation* – e.g. only 15% of practices are rural – needs a
Cohen's-d two-sample calculation that a naive equal-N formula gets
wrong. This reports both the equal-allocation sample size and the total
N required under the study's real group split, found by a binary search
over
[`pwr::pwr.t2n.test()`](https://rdrr.io/pkg/pwr/man/pwr.t2n.test.html).

## Usage

``` r
mysterycall_ttest_power(mde, sd, group_frac = 0.5, alpha = 0.05, power = 0.8)
```

## Arguments

- mde:

  Minimum detectable effect (difference in group means, same units as
  `sd`). May be a vector; one result row per value.

- sd:

  Common within-group standard deviation.

- group_frac:

  Fraction of the sample in the smaller (exposure) group, in `(0, 1)`.
  Default `0.5` (equal allocation).

- alpha:

  Two-sided significance level. Default `0.05`.

- power:

  Target power. Default `0.80`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html),
one row per `mde`: `mde`, `cohens_d`, `n_per_group_equal`,
`equal_total_n`, `natural_n_small`, `natural_n_large`,
`natural_total_n`.

## Details

Requires the pwr package.

## See also

[`mysterycall_lm_interaction_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lm_interaction_power.md),
[`mysterycall_power_curve()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_power_curve.md)

Other power:
[`mysterycall_adjusted_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_adjusted_power.md),
[`mysterycall_lm_interaction_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lm_interaction_power.md)

## Examples

``` r
if (requireNamespace("pwr", quietly = TRUE)) {
  mysterycall_ttest_power(mde = c(3, 5, 7), sd = 12, group_frac = 0.15)
}
#> # A tibble: 3 × 7
#>     mde cohens_d n_per_group_equal equal_total_n natural_n_small natural_n_large
#>   <dbl>    <dbl>             <dbl>         <dbl>           <dbl>           <dbl>
#> 1     3    0.25                253           506             148             840
#> 2     5    0.417                92           184              54             303
#> 3     7    0.583                48            96              28             156
#> # ℹ 1 more variable: natural_total_n <int>
```
