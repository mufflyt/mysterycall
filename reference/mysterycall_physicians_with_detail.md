# Retrieve detailed records for a set of flagged physician IDs

Filters the full mystery-caller data frame to the rows whose `id_col`
value appears in `flagged_ids`, then returns the requested `select_cols`
arranged by `id_col`. Mirrors the source-Rmd pattern:


    df %>%
      filter(id_number %in% unique(temp$id_number)) %>%
      dplyr::select(id_number, physician_information,
                    reason_for_exclusions, insurance,
                    business_days_until_appointment) %>%
      arrange(id_number)

## Usage

``` r
mysterycall_physicians_with_detail(
  data,
  flagged_ids,
  id_col = "id_number",
  select_cols = c("id_number", "physician_information", "reason_for_exclusions",
    "insurance", "business_days_until_appointment"),
  output_dir = NULL,
  filename = "physicians_with_detail.csv"
)
```

## Arguments

- data:

  A data frame of mystery-caller records.

- flagged_ids:

  A character or numeric vector of IDs to look up, **or** a data frame
  that contains a column named `id_col` (the unique values of that
  column are used as the lookup set).

- id_col:

  Character scalar. Column to match on in both `data` and (when
  `flagged_ids` is a data frame) `flagged_ids`. Default `"id_number"`.

- select_cols:

  Character vector. Columns to return (only those that actually exist in
  `data` are kept). Default:
  `c("id_number", "physician_information", "reason_for_exclusions", "insurance", "business_days_until_appointment")`.

- output_dir:

  Character scalar or `NULL`. Directory for the CSV output. `NULL`
  (default) writes to a session temp directory via
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).
  Pass `NA` to skip writing entirely.

- filename:

  Character scalar. Name of the output CSV file. Default
  `"physicians_with_detail.csv"`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
of matching rows arranged by `id_col`. Returns a zero-row tibble (with
the requested columns) when no IDs match.

## See also

[`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md),
[`mysterycall_flag_repeat_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_repeat_physicians.md)

Other descriptive helpers:
[`mysterycall_demographics_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_demographics_sentence.md),
[`mysterycall_descriptive_stats()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_descriptive_stats.md),
[`mysterycall_distribution_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_distribution_summary.md),
[`mysterycall_facet_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_facet_histogram.md),
[`mysterycall_log_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_histogram.md),
[`mysterycall_scenario_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md),
[`mysterycall_sensitivity_both_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)

## Examples

``` r
df <- data.frame(
  id_number                      = c("001", "002", "003", "004"),
  physician_information          = c("Dr A", "Dr B", "Dr C", "Dr D"),
  reason_for_exclusions          = c("Able to contact", NA,
                                     "No appointment", "Able to contact"),
  insurance                      = c("Medicaid", "BCBS", "Medicaid", "BCBS"),
  business_days_until_appointment = c(5, NA, NA, 10),
  stringsAsFactors               = FALSE
)
mysterycall_physicians_with_detail(df, flagged_ids = c("001", "003"),
                                   output_dir = NA)
#> Found 2 matching records for 2 unique IDs.
#> # A tibble: 2 × 5
#>   id_number physician_information reason_for_exclusions insurance
#>   <chr>     <chr>                 <chr>                 <chr>    
#> 1 001       Dr A                  Able to contact       Medicaid 
#> 2 003       Dr C                  No appointment        Medicaid 
#> # ℹ 1 more variable: business_days_until_appointment <dbl>
```
