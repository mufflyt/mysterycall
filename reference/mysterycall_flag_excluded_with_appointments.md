# Flag Excluded Records That Still Have a Positive Wait Time

Finds records where `business_days_until_appointment > 0` but
`reason_for_exclusions` is not `contact_value`. These are logical
contradictions: a call that failed contact should not have a valid
positive wait time.

## Usage

``` r
mysterycall_flag_excluded_with_appointments(
  data,
  days_col = "business_days_until_appointment",
  exclusion_col = "reason_for_exclusions",
  contact_value = "Able to contact",
  select_cols = c("physician_information", "id_number", "notes", "reason_for_exclusions",
    "business_days_until_appointment"),
  output_dir = NULL,
  filename = "excluded_with_appointments.csv"
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
  succeeded. Default `"Able to contact"`.

- select_cols:

  Character vector of columns to return. Columns not present in `data`
  are silently dropped.

- output_dir:

  Character scalar or `NULL`. Directory for CSV output. `NULL` writes to
  a session temp directory via
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).
  Pass `NA` to skip writing.

- filename:

  Character scalar. Output CSV file name.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
of flagged rows, sorted descending by `id_number` (when present).
Returns a zero-row tibble (invisibly) when no records are flagged.

## See also

[`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md)
for the `>= 0` variant;
[`mysterycall_flag_included_na_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_included_na_appointments.md)
for the complementary check.

Other quality control:
[`mysterycall_clean_medicaid_col()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_medicaid_col.md),
[`mysterycall_dedup_by_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_dedup_by_insurance.md),
[`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md),
[`mysterycall_flag_included_na_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_included_na_appointments.md),
[`mysterycall_flag_repeat_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_repeat_physicians.md)

## Examples

``` r
df <- data.frame(
  physician_information           = c("Dr A", "Dr B", "Dr C"),
  id_number                       = c("001", "002", "003"),
  notes                           = c(NA, NA, NA),
  reason_for_exclusions           = c("Not available", "Able to contact", "Not available"),
  business_days_until_appointment = c(5L, 3L, 0L),
  stringsAsFactors = FALSE
)
# Only Dr A is flagged (days > 0 AND excluded)
mysterycall_flag_excluded_with_appointments(df, output_dir = NA)
#> Quality check: 1 record(s) have a positive wait time but are marked as excluded.
#>   physician_information id_number notes reason_for_exclusions
#> 1                  Dr A       001    NA         Not available
#>   business_days_until_appointment
#> 1                               5
```
