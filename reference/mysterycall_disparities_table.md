# Compute Disparity Metrics Across Groups

For each level of a grouping column (e.g., insurance type), compute
acceptance rates, confidence intervals, and disparity metrics relative
to a reference group.

## Usage

``` r
mysterycall_disparities_table(
  data,
  outcome_col,
  group_col,
  ref_group = NULL,
  ci_method = c("wilson", "exact", "wald"),
  alpha = 0.05
)
```

## Arguments

- data:

  A data.frame containing the study data.

- outcome_col:

  Character scalar. Name of the binary outcome column (values must be
  0/1; NAs are dropped before calculations).

- group_col:

  Character scalar. Name of the grouping column.

- ref_group:

  Character scalar or NULL. Reference group label. If NULL, uses the
  first factor level when `group_col` is a factor, otherwise the
  alphabetically first level.

- ci_method:

  One of `"wilson"` (default), `"exact"`, or `"wald"`.

- alpha:

  Numeric in (0, 1). Significance level. Default 0.05 yields 95% CIs.

## Value

A data.frame with class
`c("mysterycall_disparities_table", "data.frame")` sorted with the
reference group first, then remaining groups by descending acceptance
rate. Attributes `ref_group`, `ci_method`, and `alpha` are attached.
Columns:

- group:

  Group label.

- n:

  Total observations in group.

- n_accepted:

  Sum of `outcome_col` (excluding NAs).

- rate:

  Acceptance rate (n_accepted / n).

- lower_ci:

  Lower bound of rate CI.

- upper_ci:

  Upper bound of rate CI.

- abs_diff:

  Difference in percentage points from ref group (0 for reference).

- rel_risk:

  Rate relative to ref group rate (1 for reference).

- rr_lower:

  Lower bound of RR CI via log method (NA for reference).

- rr_upper:

  Upper bound of RR CI via log method (NA for reference).

- p_value:

  Two-proportion z-test p-value vs. reference (NA for reference).

- p_value_fmt:

  Formatted p-value string.

## Details

Relative-risk CIs use the log method with a 0.5 continuity correction
when `n_accepted` is 0: \\SE(\log RR) = \sqrt{1/n\_+ - 1/n +
1/n\_{ref,+} - 1/n\_{ref}}\\.

## See also

[`mysterycall_table1_gtsummary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1_gtsummary.md),
[`mysterycall_bootstrap_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bootstrap_ci.md)

Other table helpers:
[`mysterycall_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_pct.md),
[`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md),
[`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md),
[`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md),
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md),
[`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md),
[`print.mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_disparities_table.md)

## Examples

``` r
set.seed(1)
df <- data.frame(
  insurance = sample(c("Medicaid", "Private", "Medicare"), 120, replace = TRUE),
  accepted  = rbinom(120, 1, 0.5)
)
mysterycall_disparities_table(df, "accepted", "insurance")
#> Disparity table -- 3 groups | ref: 'Medicaid' | wilson 95% CI
#> Group                       n  n_acc     Rate  95% CI            Abs.Diff  RR (95% CI)             p-value
#> ---------------------------------------------------------------------------------------------------- 
#> Medicaid                   38     18    47.4%  32.5%-62.7%          (ref)  1.00 (ref)              (ref)
#> Private                    44     21    47.7%  33.8%-62.1%        +0.4 pp  1.01 (0.64-1.59)        0.974
#> Medicare                   38     18    47.4%  32.5%-62.7%        +0.0 pp  1.00 (0.62-1.61)        1.000
```
