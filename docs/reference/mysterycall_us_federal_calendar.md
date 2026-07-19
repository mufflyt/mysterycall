# Build a US federal holiday calendar

Creates a
[`bizdays::create.calendar()`](https://rdrr.io/pkg/bizdays/man/create.calendar.html)
object covering all 11 US federal holidays for the requested year range.
Fixed holidays are shifted to their observed weekday (Friday if they
fall on Saturday, Monday if Sunday). Floating holidays (MLK Day,
Presidents Day, Memorial Day, Labor Day, Columbus Day, Thanksgiving) are
computed exactly.

## Usage

``` r
mysterycall_us_federal_calendar(
  start_year = as.integer(format(Sys.Date(), "%Y")) - 5L,
  end_year = as.integer(format(Sys.Date(), "%Y")) + 10L
)
```

## Arguments

- start_year:

  First year to include. Defaults to five years before the current year,
  which covers retrospective data collection.

- end_year:

  Last year to include. Defaults to ten years after the current year.

## Value

An S3 object of class `"calendar"` (from `bizdays`) named `"USFederal"`.
Pass it to
[`bizdays::bizdays()`](https://rdrr.io/pkg/bizdays/man/bizdays.html) or
[`bizdays::is.bizday()`](https://rdrr.io/pkg/bizdays/man/is.bizday.html)
for date arithmetic. Contains one holiday entry per year from
`start_year` to `end_year`, with fixed holidays observing the
Saturday-to-Friday / Sunday-to-Monday shift rule.

## Details

The calendar is used internally by
[`mysterycall_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_business_days.md)
and
[`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md).
You only need to call this directly if you want to reuse the same
calendar object across many calls for performance, or if you need to
inspect the holiday list.

## See also

[`mysterycall_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_business_days.md),
[`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md)

Other business days:
[`mysterycall_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_business_days.md),
[`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md)

## Examples

``` r
cal <- mysterycall_us_federal_calendar(2024, 2028)
bizdays::is.bizday(as.Date("2026-01-19"), cal)  # MLK Day -> FALSE
#> [1] FALSE
```
