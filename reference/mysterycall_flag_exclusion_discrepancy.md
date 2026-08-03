# Flag Records with Exclusions That Also Have a Wait Time

A quality-control check that finds records where `reason_for_exclusions`
indicates the call was NOT successfully completed (i.e. not
`"Able to contact"`) but `business_days_until_appointment` is
nonetheless non-negative — a logical discrepancy suggesting a data-entry
error.

## Usage

``` r
mysterycall_flag_exclusion_discrepancy(
  data,
  days_col = "business_days_until_appointment",
  exclusion_col = "reason_for_exclusions",
  contact_value = "Able to contact",
  select_cols = c("physician_information", "id_number", "notes", "reason_for_exclusions",
    "business_days_until_appointment"),
  min_days = 0,
  output_dir = NULL,
  filename = "discrepancy_rows.csv"
)
```

## Arguments

- data:

  A data frame of mystery-caller records.

- days_col:

  Character scalar. Name of the wait-time column. Default
  `"business_days_until_appointment"`.

- exclusion_col:

  Character scalar. Name of the exclusion-reason column. Default
  `"reason_for_exclusions"`.

- contact_value:

  Character scalar. The value in `exclusion_col` that means the call
  succeeded (no exclusion). Default `"Able to contact"`.

- select_cols:

  Character vector of extra columns to include in the returned table.
  Default returns a standard audit set.

- min_days:

  Numeric scalar. Lower bound for the wait-time comparison (inclusive).
  Default `0` (any non-negative value is flagged).

- output_dir:

  Character scalar or `NULL`. Directory for the CSV output. `NULL`
  (default) writes to a session temp directory via
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).
  Pass `NA` to skip writing entirely.

- filename:

  Character scalar. Output CSV file name. Default
  `"discrepancy_rows.csv"`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
of discrepant rows, sorted descending by the id column (if present).
Returns a zero-row tibble (invisibly) when no discrepancies are found.

## What this detects

If a call is logged as excluded (e.g.
`reason_for_exclusions == "Physician not available"`) but also has a
non-negative `business_days_until_appointment`, the record is
contradictory — an excluded call should not have a valid appointment
wait time. These rows must be resolved before analysis.

## See also

[`mysterycall_flag_repeat_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_repeat_physicians.md)
for duplicate-entry checks;
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md)
for broader pre-analysis validation.

Other quality control:
[`mysterycall_clean_medicaid_col()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_medicaid_col.md),
[`mysterycall_dedup_by_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_dedup_by_insurance.md),
[`mysterycall_flag_excluded_with_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_excluded_with_appointments.md),
[`mysterycall_flag_included_na_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_included_na_appointments.md),
[`mysterycall_flag_repeat_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_repeat_physicians.md)

## Examples

``` r
df <- data.frame(
  physician_information          = c("Dr A", "Dr B", "Dr C"),
  id_number                      = c("001", "002", "003"),
  notes                          = c("Called twice", NA, "Left VM"),
  reason_for_exclusions          = c("Physician not available",
                                     "Able to contact",
                                     "Number disconnected"),
  business_days_until_appointment = c(5, 3, 0),
  stringsAsFactors = FALSE
)
# Dr A and Dr C are flagged: excluded but have a wait time >= 0
result <- mysterycall_flag_exclusion_discrepancy(df, output_dir = NA)
#> Quality check: 2 record(s) are marked as excluded but have business_days_until_appointment >= 0.
result
#>   physician_information id_number        notes   reason_for_exclusions
#> 1                  Dr C       003      Left VM     Number disconnected
#> 2                  Dr A       001 Called twice Physician not available
#>   business_days_until_appointment
#> 1                               0
#> 2                               5
```
