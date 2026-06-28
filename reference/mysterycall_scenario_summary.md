# Scenario call count summary and descriptive sentence

Counts the number of calls per scenario level, computes row percentages,
and builds a ready-to-paste sentence describing the distribution.
Optionally filters to successfully-contacted calls before generating the
contact-level scenario counts.

## Usage

``` r
mysterycall_scenario_summary(
  data,
  scenario_col = "scenario",
  scenario_levels = NULL,
  contact_col = NULL,
  contact_value = "Able to contact",
  output_dir = NULL,
  filename = "scenario_summary.csv"
)
```

## Arguments

- data:

  A data frame of mystery-caller records.

- scenario_col:

  Character scalar. Name of the column containing scenario labels.
  Default `"scenario"`.

- scenario_levels:

  Named character vector. Maps display labels (names) to column values
  (values), e.g.
  `c(hip = "HIP scenario", shoulder = "SHOULDER scenario", knee = "KNEE scenario")`.
  When `NULL` (default), all unique values found in `scenario_col` are
  used and a generic sentence is generated.

- contact_col:

  Character scalar or `NULL`. If provided, also compute scenario counts
  restricted to rows where `contact_col == contact_value`. Default
  `NULL`.

- contact_value:

  Character scalar. The value in `contact_col` that indicates a
  successful contact. Default `"Able to contact"`.

- output_dir:

  Character scalar or `NULL`. Directory for CSV output. `NULL` (default)
  writes to a session temp directory via
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).
  Pass `NA` to skip writing entirely.

- filename:

  Character scalar. Output CSV file name. Default
  `"scenario_summary.csv"`.

## Value

A named list with four elements:

- `counts`:

  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  with columns `scenario`, `count`, `percent`, arranged descending by
  `count`.

- `total`:

  Integer. Total number of rows in `data`.

- `sentence`:

  Character scalar. Manuscript-ready descriptive sentence. When
  `scenario_levels` is `NULL` a generic format is used; when provided
  the sentence follows the sports-medicine orthopedics template from the
  source Rmd.

- `contact_counts`:

  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  with the same columns as `counts` but restricted to rows where
  `contact_col == contact_value`. `NULL` when `contact_col` is not
  supplied.

## See also

[`mysterycall_sensitivity_both_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)

Other descriptive helpers:
[`mysterycall_demographics_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_demographics_sentence.md),
[`mysterycall_descriptive_stats()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_descriptive_stats.md),
[`mysterycall_distribution_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_distribution_summary.md),
[`mysterycall_facet_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_facet_histogram.md),
[`mysterycall_log_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_histogram.md),
[`mysterycall_physicians_with_detail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physicians_with_detail.md),
[`mysterycall_sensitivity_both_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)

## Examples

``` r
df <- data.frame(
  scenario = c(
    "HIP scenario", "HIP scenario", "SHOULDER scenario",
    "KNEE scenario", "HIP scenario"
  ),
  status = rep("Able to contact", 5L),
  stringsAsFactors = FALSE
)
res <- mysterycall_scenario_summary(
  df,
  scenario_levels = c(
    hip      = "HIP scenario",
    shoulder = "SHOULDER scenario",
    knee     = "KNEE scenario"
  ),
  output_dir = NA
)
cat(res$sentence)
#> There were 5 calls, with sports medicine orthopedists specializing in 3 hip, 1 shoulder, and 1 knee.
```
