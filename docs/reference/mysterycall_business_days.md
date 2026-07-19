# Business-day utilities for mystery caller studies

The primary outcome in mystery caller studies is
`business_days_until_appointment`: the number of Mon-Fri working days
(excluding US federal holidays) between the call date and the offered
appointment date. These helpers build a `bizdays` calendar from US
federal holidays and compute that column for a data frame.

Computes
[`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md)
for every row and stores the result in a new column. This is the primary
way to produce the `business_days_until_appointment` outcome column
needed for
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md).

## Usage

``` r
mysterycall_business_days(
  data,
  call_col = "call_date",
  appt_col = "appointment_date",
  result_col = "business_days_until_appointment",
  calendar = NULL
)
```

## Arguments

- data:

  A data frame containing date columns for the call and the offered
  appointment.

- call_col:

  Name of the column holding the call date. Defaults to `"call_date"`.

- appt_col:

  Name of the column holding the appointment date. Defaults to
  `"appointment_date"`.

- result_col:

  Name of the new column to create. Defaults to
  `"business_days_until_appointment"`, which matches the outcome name
  used throughout the package.

- calendar:

  A `bizdays` calendar from
  [`mysterycall_us_federal_calendar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_us_federal_calendar.md).
  Built automatically when `NULL` (default). Pass a pre-built calendar
  when calling this function many times to avoid rebuilding it on each
  call.

## Value

`data` with one additional integer column named `result_col`.

## See also

[`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)

Other business days:
[`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md),
[`mysterycall_us_federal_calendar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_us_federal_calendar.md)

## Examples

``` r
df <- data.frame(
  physician        = c("Dr. Smith", "Dr. Jones"),
  call_date        = as.Date(c("2026-02-02", "2026-02-13")),
  appointment_date = as.Date(c("2026-02-10", "2026-02-20"))
)
if (requireNamespace("bizdays", quietly = TRUE)) {
  mysterycall_business_days(df)
}
#> Business days computed for 2/2 row(s); stored in column 'business_days_until_appointment'.
#>   physician  call_date appointment_date business_days_until_appointment
#> 1 Dr. Smith 2026-02-02       2026-02-10                               6
#> 2 Dr. Jones 2026-02-13       2026-02-20                               4
```
