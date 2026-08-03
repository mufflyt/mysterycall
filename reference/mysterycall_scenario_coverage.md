# Per-cluster scenario coverage for a matched multi-scenario audit

A matched mystery-caller design calls the *same* practice under two or
more scenarios (insurance types, caller personas), and the paired
analyses
([`mysterycall_paired_acceptance_mcnemar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_acceptance_mcnemar.md),
[`mysterycall_paired_wait_within_practice()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_wait_within_practice.md))
only draw information from clusters observed under both arms of a
contrast. Before running them it is worth knowing how complete the
design actually is: how many practices were reached under the *full* set
of scenarios versus only a partial set, and which scenario is short. A
mistyped or unmatched cluster key silently becomes a one-scenario
singleton and deflates the paired denominator, so this coverage check is
a design-integrity guard as much as a descriptive table. Pair it with
[`mysterycall_flag_near_duplicate_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_near_duplicate_keys.md)
to catch the mistyped keys that cause spurious singletons.

## Usage

``` r
mysterycall_scenario_coverage(
  data,
  id_col,
  scenario_col,
  scenarios = NULL,
  output_dir = NA,
  filename = NA
)
```

## Arguments

- data:

  A long data frame: one row per cluster x scenario call.

- id_col:

  Cluster / practice identifier column.

- scenario_col:

  Scenario column.

- scenarios:

  Optional character vector naming the scenario levels the design
  intended. When `NULL` (default) all non-missing values found in
  `scenario_col` are used. A "complete" cluster is one observed under
  every scenario in this set. Names not present in the data are still
  reported (as fully missing), so you can assert the design you *meant*
  to run.

- output_dir, filename:

  Optional CSV export of the per-cluster coverage table.
  `output_dir = NA` (default) skips writing; `NULL` writes to a session
  temp directory via
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).

## Value

An object of class `"mysterycall_scenario_coverage"`: a list with

- `coverage`:

  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html),
  one row per cluster: `id`, a logical `has_<scenario>` column per
  scenario level, and `n_scenarios` (how many of the intended scenarios
  were observed).

- `summary`:

  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  design totals: `n_clusters`, `n_complete` (observed under all
  scenarios), `n_partial`, `n_singleton`, plus one
  `n_missing_<scenario>` count per scenario.

- `scenarios`:

  The scenario levels used.

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the per-cluster `coverage` table.

## See also

[`mysterycall_paired_acceptance_mcnemar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_acceptance_mcnemar.md),
[`mysterycall_flag_near_duplicate_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_near_duplicate_keys.md)

Other descriptive helpers:
[`mysterycall_demographics_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_demographics_sentence.md),
[`mysterycall_descriptive_stats()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_descriptive_stats.md),
[`mysterycall_distribution_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_distribution_summary.md),
[`mysterycall_facet_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_facet_histogram.md),
[`mysterycall_log_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_histogram.md),
[`mysterycall_physicians_with_detail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physicians_with_detail.md),
[`mysterycall_scenario_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md),
[`mysterycall_sensitivity_both_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)

## Examples

``` r
d <- data.frame(
  practice = c(1, 1, 1, 2, 2, 3),
  scenario = c("Straight", "Lesbian", "Single mother",
               "Straight", "Lesbian", "Straight")
)
mysterycall_scenario_coverage(d, "practice", "scenario")
#> Scenario coverage across 3 clusters
#>   complete (all 3 scenarios): 1
#>   partial (2+ but not all):    1
#>   singleton (1 scenario):      1
#>   missing Lesbian:             1
#>   missing Single mother:       2
#>   missing Straight:            0
```
