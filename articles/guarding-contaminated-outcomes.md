# Guarding Against a Contaminated Outcome Variable

## The defect this vignette is about

A mystery-caller log has one row per call. Some calls reach an office
and get an appointment date; most of the rest never reach anyone at all.
The wait-time column should therefore be missing for every call that
produced no appointment.

Fill-down contamination is what happens when that column gets carried
forward. It usually arrives through a spreadsheet: the rows are sorted
so that each answered call is followed by the calls that were not,
someone drags a formula down or applies a fill operation, and every
unreachable office silently inherits the wait of the last office that
answered.

The reason this deserves its own vignette, rather than a line in a
checklist, is that **the result does not look broken**.

``` r

calls <- data.frame(
  clinic = c("Northside", "Lakeview", "Harbor",
             "Cedar Park", "Ridgeway",
             "Summit", "Fairmont", "Brookline", "Eastgate"),
  appointment_date = as.Date(c("2019-07-11", NA, NA,
                               "2019-08-23", NA,
                               "2019-09-03", NA, NA, NA)),
  reason_for_exclusions = c("Able to contact", "Went to voicemail", "Wrong number listed",
                            "Able to contact", "Went to voicemail",
                            "Able to contact", "Wrong number listed",
                            "Went to voicemail", "Went to voicemail"),
  business_days_until_appointment = c(8, 8, 8, 16, 16, 28, 28, 28, 28)
)
calls
#>       clinic appointment_date reason_for_exclusions
#> 1  Northside       2019-07-11       Able to contact
#> 2   Lakeview             <NA>     Went to voicemail
#> 3     Harbor             <NA>   Wrong number listed
#> 4 Cedar Park       2019-08-23       Able to contact
#> 5   Ridgeway             <NA>     Went to voicemail
#> 6     Summit       2019-09-03       Able to contact
#> 7   Fairmont             <NA>   Wrong number listed
#> 8  Brookline             <NA>     Went to voicemail
#> 9   Eastgate             <NA>     Went to voicemail
#>   business_days_until_appointment
#> 1                               8
#> 2                               8
#> 3                               8
#> 4                              16
#> 5                              16
#> 6                              28
#> 7                              28
#> 8                              28
#> 9                              28
```

Every value is a plausible number of business days. Nothing is negative,
nothing is absurdly large, and the column is complete, which usually
reads as a sign of careful data collection rather than a warning.

## Why summary statistics will not save you

The natural instinct is to look at the distribution. That is exactly
what fails here, because the fabricated values are copies of real ones
and so share their distribution.

``` r

honest <- calls$business_days_until_appointment[!is.na(calls$appointment_date)]
c(contaminated_mean = mean(calls$business_days_until_appointment),
  honest_mean       = mean(honest))
#> contaminated_mean       honest_mean 
#>          18.66667          17.33333
```

The two means are close, and in the real dataset that motivated this
function they were closer still: 23.8 against an honest 23.0. A reviewer
comparing that number to the published literature would find nothing to
object to. The mean is not wrong because the arithmetic is wrong; it is
wrong because it is computed over rows that never had an appointment.

The damage only becomes visible when you stop asking what the numbers
are and start asking **which rows they are attached to**.

``` r

data.frame(
  clinic       = calls$clinic,
  wait         = calls$business_days_until_appointment,
  has_appt     = !is.na(calls$appointment_date),
  was_excluded = calls$reason_for_exclusions != "Able to contact"
)
#>       clinic wait has_appt was_excluded
#> 1  Northside    8     TRUE        FALSE
#> 2   Lakeview    8    FALSE         TRUE
#> 3     Harbor    8    FALSE         TRUE
#> 4 Cedar Park   16     TRUE        FALSE
#> 5   Ridgeway   16    FALSE         TRUE
#> 6     Summit   28     TRUE        FALSE
#> 7   Fairmont   28    FALSE         TRUE
#> 8  Brookline   28    FALSE         TRUE
#> 9   Eastgate   28    FALSE         TRUE
```

Six of the nine rows carry a wait time despite having no appointment
date, and four of them were never contacted at all. An office that went
to voicemail cannot have been given an appointment in eleven business
days.

## Refusing the column

[`mysterycall_guard_contaminated_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_guard_contaminated_wait.md)
stops rather than reports. That is the difference between it and
[`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md),
which returns the offending rows so a human can adjudicate them. A guard
is for the case where you have already decided the column is not
analysable and want the pipeline to fail if anyone forgets.

``` r

mysterycall_guard_contaminated_wait(
  calls,
  appointment_col = "appointment_date",
  exclusion_col   = "reason_for_exclusions",
  contact_value   = "Able to contact"
)
#> Error:
#> ! `business_days_until_appointment` is contaminated and must not be analysed as a wait time.
#>   6 of 9 rows are implicated.
#>   wait recorded with no appointment date : 6
#>   wait recorded on an excluded call      : 6
#>   carried forward from the previous row  : 6
#>   Derive the wait from the call and appointment dates instead, and keep
#>   this column only as a labelled historical artefact.
```

It checks three signatures, in decreasing order of certainty:

1.  **A wait with no appointment date.** An office that never gave a
    date cannot have a measured wait. This is the strongest evidence and
    needs no assumptions.
2.  **A wait on an excluded call.** The call is recorded as not having
    produced an appointment, so a wait attached to it contradicts the
    exclusion.
3.  **A carry-forward run.** Consecutive identical waits where the later
    row has no appointment of its own to justify them. This is the
    fingerprint of the fill operation itself.

The condition carries the offending rows, so you can triage rather than
guess:

``` r

cond <- tryCatch(
  mysterycall_guard_contaminated_wait(calls, appointment_col = "appointment_date"),
  mysterycall_contaminated_wait = function(e) e
)
cond$rows
#> [1] 2 3 5 7 8 9
cond$counts
#> wait_without_appointment    wait_on_excluded_call       carry_forward_runs 
#>                        6                        0                        6
```

## A guard that cannot fail is worse than no guard

Two behaviours are worth knowing about, because both exist to stop the
function from giving false assurance.

**Repeated values are not automatically suspicious.** Two offices can
genuinely offer the same wait. The guard only objects when the repeat is
*unjustified*, meaning the later row has no appointment of its own.

``` r

legit <- data.frame(
  appointment_date                = as.Date(c("2019-07-11", "2019-07-12", "2019-07-15")),
  business_days_until_appointment = c(10, 10, 10)
)
mysterycall_guard_contaminated_wait(legit, appointment_col = "appointment_date")
```

**A non-numeric wait column is refused, not passed.** Call logs of this
kind often carry a banded version of the wait alongside the numeric one.
Returning a clean bill of health for a column the guard never examined
would be exactly the false assurance it exists to prevent, so it errors
instead.

``` r

banded <- data.frame(
  appointment_date                = as.Date(c("2019-07-11", NA)),
  business_days_until_appointment = c("1 to 10 business days", NA)
)
mysterycall_guard_contaminated_wait(banded, appointment_col = "appointment_date")
#> Error:
#> ! `business_days_until_appointment` is character, not numeric. This guard audits a numeric wait time; it has not checked this column.
```

## What to do instead

Do not repair the column, and do not delete it.

Repairing it means guessing which values were real, and the fill
operation has already destroyed the information needed to tell. Deleting
it means the next person to open the source file finds an undocumented
column and no reason not to use it, which is how a defect gets
reintroduced three years later.

Derive the outcome from the source fields instead. The call date and the
appointment date are the authority; the wait is a function of them.

``` r

business_days <- function(from, to, holidays = as.Date(character(0))) {
  vapply(seq_along(from), function(i) {
    if (is.na(from[i]) || is.na(to[i]) || to[i] < from[i]) return(NA_real_)
    if (to[i] == from[i]) return(0)
    d <- seq(from[i] + 1, to[i], by = "day")
    sum(!(format(d, "%u") %in% c("6", "7")) & !(d %in% holidays))
  }, numeric(1))
}

calls$call_date <- as.Date(c("2019-07-01", "2019-07-01", "2019-07-02",
                             "2019-07-02", "2019-07-03",
                             "2019-07-08", "2019-07-08", "2019-07-09", "2019-07-09"))
calls$wait_derived <- business_days(calls$call_date, calls$appointment_date,
                                    holidays = as.Date("2019-07-04"))
calls[, c("clinic", "call_date", "appointment_date", "wait_derived")]
#>       clinic  call_date appointment_date wait_derived
#> 1  Northside 2019-07-01       2019-07-11            7
#> 2   Lakeview 2019-07-01             <NA>           NA
#> 3     Harbor 2019-07-02             <NA>           NA
#> 4 Cedar Park 2019-07-02       2019-08-23           37
#> 5   Ridgeway 2019-07-03             <NA>           NA
#> 6     Summit 2019-07-08       2019-09-03           41
#> 7   Fairmont 2019-07-08             <NA>           NA
#> 8  Brookline 2019-07-09             <NA>           NA
#> 9   Eastgate 2019-07-09             <NA>           NA
```

The derived column is missing exactly where it should be, and the guard
now passes:

``` r

mysterycall_guard_contaminated_wait(
  data.frame(appointment_date = calls$appointment_date,
             business_days_until_appointment = calls$wait_derived),
  appointment_col = "appointment_date"
)
```

Keep the original column in the source file, labelled as a known-bad
historical artefact, and let the guard be the thing that prevents its
use. A defect that is documented and blocked is safer than one that has
been quietly tidied away.

## Where this fits

- [`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md)
  reports the same class of discrepancy as a table, for adjudication
  rather than refusal.
- [`mysterycall_flag_included_na_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_included_na_appointments.md)
  covers the mirror-image problem: rows marked as included that have no
  appointment date.
- The `data-quality` vignette covers upstream validation of phones,
  names and joins, before any outcome variable exists.
