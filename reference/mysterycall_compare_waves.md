# Compare a study outcome across waves of a mystery caller study

Calculates per-wave (and optionally per-group) summary statistics and
pairwise tests against a reference wave, using only base R.

## Usage

``` r
mysterycall_compare_waves(
  data,
  wave_col,
  outcome_col,
  group_col = NULL,
  type = c("auto", "proportion", "continuous"),
  ref_wave = NULL
)
```

## Arguments

- data:

  A data frame.

- wave_col:

  Character scalar: column identifying the study wave.

- outcome_col:

  Character scalar: column containing the outcome to compare.

- group_col:

  Character scalar or NULL (default). When provided, results are
  stratified by group x wave.

- type:

  One of `"auto"` (default), `"proportion"`, or `"continuous"`. `"auto"`
  detects based on whether all non-missing outcome values are in {0, 1}.

- ref_wave:

  Scalar or NULL. The reference wave against which other waves are
  compared. When NULL, the first wave (sorted
  alphabetically/numerically) is used.

## Value

A data frame. For proportion outcomes: columns `wave`, (`group`,) `n`,
`n_accepted`, `rate`, `lower_ci`, `upper_ci`, `p_vs_ref`. For continuous
outcomes: columns `wave`, (`group`,) `n`, `mean`, `median`, `sd`, `iqr`,
`p_vs_ref`. The `group` column is only present when `group_col` is
non-`NULL`. The attribute `ref_wave` is set on the returned data frame.

## See also

[`mysterycall_wait_time_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_summary.md),
[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md)
for detailed single-wave outcome analysis;
[`mysterycall_bootstrap_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bootstrap_ci.md)
for non-parametric confidence intervals.

Other inference:
[`mysterycall_bootstrap_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bootstrap_ci.md),
[`mysterycall_multiple_comparison_adjust()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multiple_comparison_adjust.md)

## Examples

``` r
df <- data.frame(
  wave    = c("pre","pre","post","post"),
  outcome = c(1, 0, 1, 1)
)
mysterycall_compare_waves(df, "wave", "outcome")
#>   wave n n_accepted rate   lower_ci  upper_ci  p_vs_ref
#> 1 post 2          2  1.0 0.34238023 1.0000000        NA
#> 2  pre 2          1  0.5 0.09453121 0.9054688 0.2482131
```
