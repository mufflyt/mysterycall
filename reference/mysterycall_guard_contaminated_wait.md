# Refuse to Analyse a Carry-Forward-Contaminated Wait-Time Variable

A hard guard, not a report. Where
[`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md)
returns the offending rows so a human can adjudicate them, this stops
the analysis outright. It exists because a wait-time column that has
been fill-down contaminated does not look broken: every value is a
plausible number of business days, models fit, and the resulting mean is
close enough to the honest one to pass a smell test. The damage only
shows up when you ask which rows the numbers are attached to.

## Usage

``` r
mysterycall_guard_contaminated_wait(
  data,
  wait_col = "business_days_until_appointment",
  appointment_col = NULL,
  exclusion_col = NULL,
  contact_value = "Able to contact",
  action = c("error", "warn")
)
```

## Arguments

- data:

  A data frame of mystery-caller records.

- wait_col:

  Character scalar. Name of the wait-time column to audit. Default
  `"business_days_until_appointment"`.

- appointment_col:

  Character scalar or `NULL`. Name of the appointment date column. When
  supplied this is the strongest available evidence: a wait time on a
  row with no appointment date cannot have been measured.

- exclusion_col:

  Character scalar or `NULL`. Name of the exclusion-reason column. When
  supplied, rows whose value is not `contact_value` are treated as calls
  that never produced an appointment.

- contact_value:

  Character scalar. The value in `exclusion_col` meaning the call
  succeeded. Default `"Able to contact"`.

- action:

  One of `"error"` (default) or `"warn"`. `"warn"` exists for auditing a
  historical file on purpose; it is not a way to keep going.

## Value

Invisibly, `TRUE` when the column is clean. Otherwise raises a condition
of class `mysterycall_contaminated_wait`, carrying the offending row
indices in `$rows` and the per-test counts in `$counts`.

## What this detects

Three signatures, in decreasing order of certainty.

1.  **Wait without an appointment.** `wait_col` is non-missing where
    `appointment_col` is missing. An office that never gave a date
    cannot have a measured wait.

2.  **Wait on an excluded call.** `wait_col` is non-missing where
    `exclusion_col` is not `contact_value`.

3.  **Carry-forward runs.** Consecutive identical `wait_col` values
    where the second and later rows have no appointment of their own.
    This is the fingerprint of a fill-down
    (last-observation-carried-forward) operation, which is how the
    contamination is usually introduced: a spreadsheet sorted so that
    each answered call is followed by the calls that were not.

## The historical defect this was written for

The 2020 NPI-enrichment branch of the 2019 FPMRS mystery-caller study
(`_mystery_caller_data_uploaded_4_9_mutate_90.csv`) carries a numeric
`Business_days_until_appointment` that is non-missing on all 352 rows,
including all 165 excluded ones. Those 165 rows hold zero appointment
dates and 116 were never contacted at all, yet 127 of them (77 percent)
repeat the wait of the nearest preceding included row. Analysing it
assigns real appointment waits to offices that never answered the phone.
The column is kept rather than deleted or repaired, because a defect
that has been quietly removed is a defect that gets reintroduced; this
guard is what makes keeping it safe.

## See also

[`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md),
which reports the same class of discrepancy as a table instead of
stopping.

Other quality control:
[`mysterycall_clean_medicaid_col()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_medicaid_col.md),
[`mysterycall_dedup_by_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_dedup_by_insurance.md),
[`mysterycall_flag_excluded_with_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_excluded_with_appointments.md),
[`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md),
[`mysterycall_flag_included_na_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_included_na_appointments.md),
[`mysterycall_flag_repeat_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_repeat_physicians.md)

## Examples

``` r
# A fill-down contaminated frame: rows 2 and 3 inherit row 1's wait.
bad <- data.frame(
  appointment_date                = as.Date(c("2019-07-11", NA, NA)),
  business_days_until_appointment = c(10, 10, 10)
)
res <- try(
  mysterycall_guard_contaminated_wait(bad, appointment_col = "appointment_date"),
  silent = TRUE
)
inherits(res, "try-error")
#> [1] TRUE

# The honest version: no wait where there is no appointment.
good <- data.frame(
  appointment_date                = as.Date(c("2019-07-11", NA, NA)),
  business_days_until_appointment = c(10, NA, NA)
)
mysterycall_guard_contaminated_wait(good, appointment_col = "appointment_date")
```
