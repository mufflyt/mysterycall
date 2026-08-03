# Derive the appointment-obtained indicator and wait, with same-day = 0

The two-part / hurdle / Heckman models
([`mysterycall_hurdle_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hurdle_wait.md),
selection models) need two derived columns from the raw call and
appointment dates: a binary **appointment-obtained** indicator (the
selection / hurdle outcome) and, among obtained appointments, the
**business-day wait**. Deriving these by hand is where a subtle but
consequential bug creeps in: computing the wait as
`appt_date <= call_date` -\> `NA` sends *same-day* appointments to `NA`,
which then reads as "no appointment obtained" in the selection stage.
That contradicts the study convention that a same-day appointment is a
0-day wait, and drops the strongest-access cases from the model.

## Usage

``` r
mysterycall_appointment_obtained(
  data,
  call_col = "call_date",
  appt_col = "appointment_date",
  obtained_col = "appt_obtained",
  wait_col = "business_days_until_appointment",
  add_wait = TRUE,
  calendar = NULL
)
```

## Arguments

- data:

  A data frame, one row per call.

- call_col:

  Character scalar. Column holding the call date. Accepts `Date`,
  `POSIXct`, or `"YYYY-MM-DD"` strings. Default `"call_date"`.

- appt_col:

  Character scalar. Column holding the offered appointment date. An
  absent value (`NA` or empty string) means no appointment was offered.
  Default `"appointment_date"`.

- obtained_col:

  Character scalar. Name of the binary indicator column to add (`1` =
  appointment obtained, `0` = not obtained, `NA` = undetermined).
  Default `"appt_obtained"`.

- wait_col:

  Character scalar. Name of the business-day wait column to add when
  `add_wait = TRUE`. Default `"business_days_until_appointment"` -
  matches the outcome name used across the package.

- add_wait:

  Logical. When `TRUE` (default) also attach the business-day wait
  column. When `FALSE` only the obtained indicator is added.

- calendar:

  A `bizdays` calendar from
  [`mysterycall_us_federal_calendar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_us_federal_calendar.md).
  Built automatically when `NULL` (default). Pass a pre-built calendar
  when calling this many times.

## Value

`data` with `obtained_col` (integer 0/1/NA) appended, and - when
`add_wait = TRUE` - `wait_col` (integer business days, `0` for same-day,
`NA` where no appointment was obtained or dates are invalid). The wait
is `NA` for every not-obtained row, matching the `wait | obtained`
structure
[`mysterycall_hurdle_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hurdle_wait.md)
expects.

## Details

This function is the correct, reusable derivation. An appointment is
**obtained** whenever a valid appointment date is present and is not
before the call date - **same day counts as obtained, with a wait of
0**. The wait is computed with
[`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md),
so it inherits the one canonical same-day = 0 / appointment-before-call
= `NA` policy instead of a hand-rolled counter.

## Obtained / not-obtained / undetermined

- obtained (`1`):

  Appointment date present and on/after the call date (includes
  same-day, wait `0`).

- not obtained (`0`):

  Call date present, appointment date absent.

- undetermined (`NA`):

  Appointment date present but *before* the call date (a data-entry
  error - also warned by
  [`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md)),
  or the call date is missing.

## See also

[`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md),
[`mysterycall_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_business_days.md),
[`mysterycall_hurdle_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hurdle_wait.md),
[`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md)

Other business days:
[`mysterycall_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_business_days.md),
[`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md),
[`mysterycall_us_federal_calendar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_us_federal_calendar.md)

## Examples

``` r
df <- data.frame(
  practice         = c("A", "B", "C", "D"),
  call_date        = as.Date(c("2026-02-02", "2026-02-02",
                                "2026-02-02", "2026-02-02")),
  appointment_date = as.Date(c("2026-02-02",  # same day  -> obtained, wait 0
                                "2026-02-06",  # 4 biz days -> obtained
                                NA,            # none       -> not obtained
                                "2026-01-30")) # before call-> undetermined
)
if (requireNamespace("bizdays", quietly = TRUE)) {
  mysterycall_appointment_obtained(df)
}
#> Warning: 1 pair(s) have appointment_date < call_date and were set to NA. Check for data entry errors.
#> mysterycall_appointment_obtained: 2 obtained (incl. 1 same-day, wait 0), 1 not obtained, 1 undetermined. Stored in 'appt_obtained' and 'business_days_until_appointment'.
#>   practice  call_date appointment_date appt_obtained
#> 1        A 2026-02-02       2026-02-02             1
#> 2        B 2026-02-02       2026-02-06             1
#> 3        C 2026-02-02             <NA>             0
#> 4        D 2026-02-02       2026-01-30            NA
#>   business_days_until_appointment
#> 1                               0
#> 2                               4
#> 3                              NA
#> 4                              NA
```
