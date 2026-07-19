# Count business days between two dates (vectorized)

Returns the number of Mon-Fri working days, excluding US federal
holidays, between `start_date` (exclusive) and `end_date` (inclusive).
This matches the `business_days_until_appointment` convention used in
mystery caller studies: a call made on Monday for an appointment on
Friday of the same week returns 4.

## Usage

``` r
mysterycall_count_business_days(start_date, end_date, calendar = NULL)
```

## Arguments

- start_date:

  Date of the mystery call. Accepts `Date`, `POSIXct`, or a character
  vector in `"YYYY-MM-DD"` format. Vectorised.

- end_date:

  Date of the offered appointment. Same types accepted.

- calendar:

  A `bizdays` calendar from
  [`mysterycall_us_federal_calendar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_us_federal_calendar.md).
  When `NULL` (default) a calendar covering 2021 - 2036 is built
  automatically.

## Value

Integer vector the same length as `start_date`.

## Details

Pairs where `end_date < start_date` or either date is `NA` return `NA`.
Pairs where `end_date == start_date` return `0`.

## See also

[`mysterycall_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_business_days.md),
[`mysterycall_us_federal_calendar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_us_federal_calendar.md)

Other business days:
[`mysterycall_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_business_days.md),
[`mysterycall_us_federal_calendar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_us_federal_calendar.md)

## Examples

``` r
# Monday to Friday of the same week = 4 business days
mysterycall_count_business_days("2026-02-02", "2026-02-06")
#> [1] 4

# Spans Presidents Day 2026 (Mon Feb 16) = 4, not 5
mysterycall_count_business_days("2026-02-13", "2026-02-20")
#> [1] 4
```
