# Compute inter-rater reliability between mystery callers

Calculates Cohen's kappa, ICC, or percent agreement between two or more
callers – or between a caller and a gold standard – using only base R.

## Usage

``` r
mysterycall_caller_reliability(
  data,
  caller_col,
  outcome_col,
  gold_col = NULL,
  pair_col = NULL,
  type = c("auto", "kappa", "icc", "percent_agreement"),
  alpha = 0.05
)
```

## Arguments

- data:

  A data frame.

- caller_col:

  Character scalar: column identifying which caller made each rating.

- outcome_col:

  Character scalar: column containing the rating/outcome.

- gold_col:

  Character scalar or NULL (default). When provided, each row of
  `outcome_col` is compared with `gold_col` (two-rater agreement).

- pair_col:

  Character scalar or NULL (default). Each unique value identifies a
  subject/call that multiple callers rated. The data are reshaped wide
  (caller x subject matrix) and reliability is computed across all
  caller pairs.

- type:

  One of `"auto"`, `"kappa"`, `"icc"`, or `"percent_agreement"`. When
  `"auto"` (default): kappa for binary outcomes (values in {0, 1, NA}),
  icc for numeric continuous outcomes, percent_agreement for
  character/factor outcomes.

- alpha:

  Significance level for confidence intervals. Default 0.05.

## Value

A named list with elements:

- type:

  Character scalar: the reliability method used.

- statistic:

  Numeric: kappa, ICC, or percent agreement.

- lower_ci:

  Lower confidence bound.

- upper_ci:

  Upper confidence bound.

- n_pairs:

  Number of matched pairs used.

- interpretation:

  Landis & Koch label for kappa ("poor", "fair", "moderate", "good",
  "excellent"); NA for other types.

## See also

[`mysterycall_check_generalist_presence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_generalist_presence.md)
for pre-call QC;
[`mysterycall_call_productivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_call_productivity.md)
for per-caller volume metrics;
[`mysterycall_compare_waves()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compare_waves.md)
for cross-wave outcome comparisons.

Other caller-management:
[`print.mysterycall_reliability()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_reliability.md)

## Examples

``` r
df <- data.frame(
  caller  = c("A","A","B","B"),
  outcome = c(1, 0, 1, 0),
  gold    = c(1, 0, 1, 1)
)
mysterycall_caller_reliability(df, "caller", "outcome", gold_col = "gold")
#> Only 4 complete pair(s) found. ICC and kappa are unreliable with fewer than 30 pairs; interpret results with caution.
#> -- mysterycall_caller_reliability --
#> Method       : kappa 
#> Statistic    : 0.5 
#> 95% CI       : [ -0.3487 , 1.3487 ]
#> N pairs      : 4 
#> Interpretation: moderate (Landis & Koch)
```
