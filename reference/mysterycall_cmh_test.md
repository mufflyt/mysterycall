# Cochran-Mantel-Haenszel Test for a Matched / Stratified Design

Tests the association between a categorical outcome and a group while
conditioning on a matching stratum – the correct engine for within-unit
audit designs where the same clinic/pharmacy is called under several
personas (Wilkinson 2018). Wraps
[`stats::mantelhaen.test()`](https://rdrr.io/r/stats/mantelhaen.test.html);
for a binary outcome and binary group it also returns the common odds
ratio and its confidence interval.

## Usage

``` r
mysterycall_cmh_test(
  data,
  outcome_var,
  group_var,
  strata_var,
  conf_level = 0.95,
  correct = TRUE
)
```

## Arguments

- data:

  A data frame in long form (one row per call).

- outcome_var, group_var, strata_var:

  Character scalars. The outcome, the grouping (exposure) variable, and
  the matching stratum (e.g. the clinic id).

- conf_level:

  Numeric. Confidence level for the common odds ratio. Default `0.95`.

- correct:

  Logical. Continuity correction for the 2x2xK case. Default `TRUE`.

## Value

A `mysterycall_cmh_test` object: a list with `method`, `statistic`,
`df`, `p_value`, `estimate` (common OR or `NA`), `conf_int`, `n`,
`n_strata`, and `table`.

## See also

Other categorical:
[`mysterycall_compare_ranks()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compare_ranks.md),
[`mysterycall_prevalence_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prevalence_ci.md),
[`mysterycall_test_categorical()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_categorical.md)

## Examples

``` r
set.seed(1)
clinic <- rep(paste0("c", 1:20), each = 2)
persona <- rep(c("adult", "teen"), times = 20)
offered <- rbinom(40, 1, ifelse(persona == "teen", 0.55, 0.8))
df <- data.frame(clinic, persona, offered = ifelse(offered == 1, "yes", "no"))
mysterycall_cmh_test(df, "offered", "persona", "clinic")
#> <mysterycall_cmh_test> 20 strata, n = 40
#>   Mantel-Haenszel chi-squared test with continuity correction
#>   statistic = 0.571, df = 1, p = 0.450
#>   common OR = 0.400 (95% CI 0.078 to 2.062)
```
