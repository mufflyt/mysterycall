# Within-practice paired McNemar test for a binary acceptance outcome

The unmatched comparison of acceptance across scenarios (insurance
types, caller personas) is confounded whenever the scenarios were not
called at the same set of practices – one scenario's calls can land
disproportionately at generous practices. The matched comparison removes
each practice's baseline generosity: only practices called under *both*
scenarios contribute, and for a binary outcome only the **discordant**
practices (a different answer to the two callers) carry information, so
the effective sample size is the discordant count, not the paired count.
This runs the exact McNemar test on each pairwise scenario contrast and
reports the discordant split, odds ratio, exact p-value, and the minimum
detectable odds ratio at the requested power.

## Usage

``` r
mysterycall_paired_acceptance_mcnemar(
  data,
  id_col,
  scenario_col,
  outcome_col,
  positive_values = TRUE,
  contrasts = NULL,
  power = 0.8,
  alpha = 0.05,
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

- outcome_col:

  Binary acceptance column.

- positive_values:

  Value(s) of `outcome_col` counted as acceptance. Default `TRUE` (also
  matches `"TRUE"`/`1`/`"Yes"` via `%in%`).

- contrasts:

  Optional list of length-2 character vectors naming the scenario pairs
  to test. Default `NULL` tests all pairwise combinations.

- power, alpha:

  Power and two-sided level for the minimum-detectable odds ratio.
  Defaults `0.80` and `0.05`.

- output_dir, filename:

  Optional CSV export of the result table.

## Value

An object of class `"mysterycall_paired_mcnemar"`: a list with `table`
(one row per contrast: `contrast`, `n_paired`, `concordant`,
`discordant`, `disc_favor_a`, `disc_favor_b`, `odds_ratio`, `mcnemar_p`,
`mde_or_power`).
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the table.

## Examples

``` r
set.seed(1)
d <- data.frame(
  practice = rep(1:40, each = 2),
  scenario = rep(c("Commercial", "Medicaid"), 40),
  accepted = rbinom(80, 1, rep(c(0.8, 0.5), 40))
)
mysterycall_paired_acceptance_mcnemar(d, "practice", "scenario", "accepted")
#> <mysterycall paired McNemar: 1 contrast(s), MDE at 80% power>
#> # A tibble: 1 × 9
#>   contrast   n_paired concordant discordant disc_favor_a disc_favor_b odds_ratio
#>   <chr>         <int>      <int>      <int>        <int>        <int>      <dbl>
#> 1 Commercia…       40         19         21           18            3          6
#> # ℹ 2 more variables: mcnemar_p <dbl>, mde_or_power <dbl>
```
