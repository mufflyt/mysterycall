# Adjust P-Values for Multiple Comparisons

Wraps [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html) with
convenience features: accepts either a numeric vector of p-values or a
data.frame with a named p-value column, adds significance stars, and
returns a tidy data.frame.

## Usage

``` r
mysterycall_multiple_comparison_adjust(
  x,
  method = c("bonferroni", "fdr", "holm", "BH", "BY"),
  alpha = 0.05,
  p_col = NULL,
  label_col = NULL
)
```

## Arguments

- x:

  A numeric vector of p-values, or a data.frame containing a p-value
  column identified by `p_col`.

- method:

  Character. Correction method passed to
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html). One of
  `"bonferroni"`, `"fdr"`, `"holm"`, `"BH"`, or `"BY"`. `"fdr"` is an
  alias for `"BH"`.

- alpha:

  Numeric in (0, 1). Significance threshold for the `significant`
  column. Default 0.05.

- p_col:

  Character scalar or NULL. When `x` is a data.frame, the name of the
  column holding raw p-values.

- label_col:

  Character scalar or NULL. When `x` is a data.frame, the name of a
  column to use as `comparison` labels.

## Value

A data.frame with columns:

- comparison:

  Label for each comparison (from `label_col`, row names, or sequential
  integers).

- p_raw:

  Original (unadjusted) p-value.

- p_adjusted:

  Adjusted p-value.

- significant:

  Logical; TRUE when `p_adjusted < alpha`.

- stars:

  Significance stars: `"***"` (p\<0.001), `"**"` (p\<0.01), `"*"`
  (p\<0.05), `"ns"` otherwise.

## See also

[`mysterycall_bootstrap_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bootstrap_ci.md)
for bootstrap-based interval estimation;
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
whose coefficients typically feed this function;
[`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html) for the
underlying adjustment.

Other inference:
[`mysterycall_bootstrap_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bootstrap_ci.md),
[`mysterycall_compare_waves()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compare_waves.md)

## Examples

``` r
pvals <- c(0.001, 0.03, 0.2, 0.5, 0.04)
mysterycall_multiple_comparison_adjust(pvals, method = "bonferroni")
#>   comparison p_raw p_adjusted significant stars
#> 1          1 0.001      0.005        TRUE    **
#> 2          2 0.030      0.150       FALSE    ns
#> 3          3 0.200      1.000       FALSE    ns
#> 4          4 0.500      1.000       FALSE    ns
#> 5          5 0.040      0.200       FALSE    ns

df <- data.frame(
  comparison = c("A vs B", "A vs C", "B vs C"),
  p          = c(0.01, 0.04, 0.3)
)
mysterycall_multiple_comparison_adjust(df, p_col = "p", label_col = "comparison")
#>   comparison p_raw p_adjusted significant stars
#> 1     A vs B  0.01       0.03        TRUE     *
#> 2     A vs C  0.04       0.12       FALSE    ns
#> 3     B vs C  0.30       0.90       FALSE    ns
```
