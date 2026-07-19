# Within-practice paired wait-time comparison

The matched analogue of
[`mysterycall_paired_acceptance_mcnemar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_acceptance_mcnemar.md)
for a continuous wait-time outcome: for each pairwise scenario contrast
it pairs the practices called under both scenarios, forms the
within-practice wait differences, and reports the mean difference (with
a paired-t confidence interval), the paired t-test and Wilcoxon
signed-rank p-values, and the minimum detectable difference in days at
the requested power. Pairing removes each practice's baseline speed,
which the unmatched comparison confounds.

## Usage

``` r
mysterycall_paired_wait_within_practice(
  data,
  id_col,
  scenario_col,
  wait_col,
  contrasts = NULL,
  power = 0.8,
  conf_level = 0.95,
  output_dir = NA,
  filename = NA
)
```

## Arguments

- data:

  A long data frame: one row per practice x scenario.

- id_col:

  Practice / cluster identifier column.

- scenario_col:

  Scenario column (2+ levels).

- wait_col:

  Numeric wait-time column.

- contrasts:

  Optional list of length-2 character vectors of scenario pairs. Default
  `NULL` tests all pairwise combinations.

- power, conf_level:

  Power for the minimum detectable difference and confidence level for
  the mean-difference interval. Defaults `0.80`, `0.95`.

- output_dir, filename:

  Optional CSV export of the result table.

## Value

An object of class `"mysterycall_paired_wait"`: a list with `table` (one
row per contrast: `contrast`, `n_paired`, `mean_diff_days`, `ci_lower`,
`ci_upper`, `sd_diff`, `paired_t_p`, `wilcoxon_p`, `mde_days_power`).
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the table.

## Examples

``` r
set.seed(2)
d <- data.frame(
  practice = rep(1:30, each = 2),
  scenario = rep(c("Commercial", "Medicaid"), 30),
  wait_days = round(c(rbind(rpois(30, 10), rpois(30, 18))))
)
mysterycall_paired_wait_within_practice(d, "practice", "scenario", "wait_days")
#> <mysterycall paired wait: 1 contrast(s), MDE at 80% power>
#> # A tibble: 1 × 9
#>   contrast          n_paired mean_diff_days ci_lower ci_upper sd_diff paired_t_p
#>   <chr>                <int>          <dbl>    <dbl>    <dbl>   <dbl>      <dbl>
#> 1 Commercial vs Me…       30          -7.93    -9.70    -6.17    4.72   4.15e-10
#> # ℹ 2 more variables: wilcoxon_p <dbl>, mde_days_power <dbl>
```
