# Rank-Based Comparison of a Numeric Outcome Across Groups

Kruskal-Wallis (three or more groups) or Mann-Whitney / Wilcoxon
rank-sum (two groups) test for a skewed numeric outcome – e.g. wait
times or quoted prices (Campbell 2013, Lungfiel 2023) – with an effect
size and per-group medians (IQR).

## Usage

``` r
mysterycall_compare_ranks(data, outcome_var, group_var)
```

## Arguments

- data:

  A data frame.

- outcome_var:

  Character scalar. Numeric outcome column.

- group_var:

  Character scalar. Grouping column (two or more levels).

## Value

A `mysterycall_rank_comparison` object: a list with `method`,
`statistic`, `df`, `p_value`, `effect_size`, `effect_type`,
`group_summary` (a tibble of `n`, `median`, `q1`, `q3`), and `n`.

## See also

Other categorical:
[`mysterycall_cmh_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cmh_test.md),
[`mysterycall_prevalence_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prevalence_ci.md),
[`mysterycall_test_categorical()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_categorical.md)

## Examples

``` r
set.seed(1)
df <- data.frame(
  price = c(rexp(20, 1 / 20), rexp(20, 1 / 35)),
  payer = rep(c("A", "B"), each = 20)
)
mysterycall_compare_ranks(df, "price", "payer")
#> <mysterycall_rank_comparison> price by payer
#>   Mann-Whitney U (Wilcoxon rank-sum)
#>   statistic = 179.000, p = 0.579
#>   effect size r (Z/sqrt(N)) = 0.088; n = 40
#>  group  n median    q1    q3
#>      A 20  17.19 10.28 24.63
#>      B 20  21.36  9.78 37.11
```
