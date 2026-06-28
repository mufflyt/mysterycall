# Sensitivity analysis: physicians called under both insurance types

Identifies physicians (by `phone_col`) who were called under both
Medicaid and Blue Cross/Blue Shield, then compares their wait times
between insurance types with summary statistics and a t-test. Mirrors
the sensitivity analysis in the mystery-caller study Rmd (lines
1469-1505).

## Usage

``` r
mysterycall_sensitivity_both_insurance(
  data,
  phone_col = "phone",
  insurance_col = "insurance",
  outcome_col = "business_days_until_appointment",
  medicaid_label = "medicaid",
  bcbs_label = "blue cross/blue shield",
  output_dir = NULL,
  filename = "sensitivity_both_insurance.csv"
)
```

## Arguments

- data:

  A data frame of mystery-caller records. Must contain `phone_col`,
  `insurance_col`, and `outcome_col`.

- phone_col:

  Character scalar. Column that uniquely identifies each physician (e.g.
  phone number or NPI). Default `"phone"`.

- insurance_col:

  Character scalar. Name of the column recording insurance type. Default
  `"insurance"`.

- outcome_col:

  Character scalar. Name of the numeric column holding wait-time days.
  Default `"business_days_until_appointment"`.

- medicaid_label:

  Character scalar. Lowercase comparison value for Medicaid after
  `tolower(trimws(...))`. Default `"medicaid"`.

- bcbs_label:

  Character scalar. Lowercase comparison value for Blue Cross after
  normalization. Default `"blue cross/blue shield"`.

- output_dir:

  Character scalar or `NULL`. Directory for CSV output. `NULL` (default)
  writes to a session temp directory via
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).
  Pass `NA` to skip writing.

- filename:

  Character scalar. CSV file name. Default
  `"sensitivity_both_insurance.csv"`.

## Value

A named list with seven elements:

- `n_both`:

  Integer. Number of physicians with records under both Medicaid and
  BCBS.

- `n_total`:

  Integer. Total unique physicians (by `phone_col`).

- `both_data`:

  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  of rows for physicians with both insurance types (insurance column is
  normalized to lowercase).

- `wait_comparison`:

  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  with columns `insurance`, `mean_wait`, `sd_wait`, `median_wait`,
  `iqr_wait` for each insurance type. Empty tibble when `n_both == 0`.

- `t_test`:

  Object returned by
  [`stats::t.test()`](https://rdrr.io/r/stats/t.test.html), or `NULL`
  when there are insufficient data.

- `sentence`:

  Character scalar. Manuscript-ready descriptive sentence.

- `phone_ids`:

  Character vector of phone numbers (or IDs) for physicians called under
  both insurance types.

## See also

[`mysterycall_scenario_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md)

Other descriptive helpers:
[`mysterycall_demographics_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_demographics_sentence.md),
[`mysterycall_descriptive_stats()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_descriptive_stats.md),
[`mysterycall_distribution_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_distribution_summary.md),
[`mysterycall_facet_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_facet_histogram.md),
[`mysterycall_log_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_histogram.md),
[`mysterycall_physicians_with_detail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physicians_with_detail.md),
[`mysterycall_scenario_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md)

## Examples

``` r
set.seed(42)
df <- data.frame(
  phone      = rep(paste0("P", 1:10), each = 2L),
  insurance  = rep(c("Medicaid", "Blue Cross/Blue Shield"), 10L),
  business_days_until_appointment = rpois(20L, 14),
  stringsAsFactors = FALSE
)
res <- mysterycall_sensitivity_both_insurance(df, output_dir = NA)
cat(res$sentence)
#> Of 10 physicians called, 10 (100.0%) were called under both Medicaid and Blue Cross/Blue Shield. Among these physicians, mean wait times were 15.8 days (SD 3.3) for Medicaid vs 13.5 days (SD 5.1) for BCBS (t-test p = 0.248).
```
