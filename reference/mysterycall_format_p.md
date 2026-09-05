# Format a p-value for reporting

The package's single source of truth for printing p-values. SAMPL asks
for exact values rather than inequalities against alpha, so a p-value is
printed to `digits` decimal places and only collapses to `"< 0.001"`
below the threshold at which the extra digits stop being meaningful.
`"NS"` is never produced.

## Usage

``` r
mysterycall_format_p(p, digits = 3L, name = NULL, threshold = 0.001)
```

## Arguments

- p:

  Numeric vector of p-values. `NA` stays `NA`.

- digits:

  Integer. Decimal places for values at or above `threshold`. Default
  `3`.

- name:

  Character scalar or `NULL`. When `NULL` (default) the bare value is
  returned (`"0.043"`, `"< 0.001"`). When given, the result is prefixed
  for prose: `name = "p"` yields `"p = 0.043"` and `"p < 0.001"`.

- threshold:

  Numeric. Values below this print as `"< threshold"`. Default `0.001`.

## Value

A character vector the length of `p`.

## References

Lang TA, Altman DG. Basic statistical reporting for articles published
in biomedical journals: the SAMPL Guidelines. *International Journal of
Nursing Studies*. 2015;52(1):5-9.
[doi:10.1016/j.ijnurstu.2014.09.006](https://doi.org/10.1016/j.ijnurstu.2014.09.006)

## See also

[`mysterycall_format_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_ci.md)
for the matching interval formatter.

Other table helpers:
[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md),
[`mysterycall_format_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_ci.md),
[`mysterycall_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_pct.md),
[`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md),
[`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md),
[`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md),
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md),
[`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md),
[`print.mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_disparities_table.md)

## Examples

``` r
mysterycall_format_p(c(0.0431, 0.0004, NA))
#> [1] "0.043"   "< 0.001" NA       
mysterycall_format_p(0.0431, name = "p")
#> [1] "p = 0.043"
mysterycall_format_p(0.0004, name = "p")
#> [1] "p < 0.001"
```
