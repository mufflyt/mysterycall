# Prepare raw REDCap mystery-caller data for statistical analysis

Applies the standard filtering pipeline for mystery-caller studies:
removes records without a call date, applies exclusion-code filtering,
resolves second-call contacts, standardizes caller names to title case,
and creates ready-to-model outcome columns for both the logistic model
(appointment offered: yes/no) and the wait-time model (calendar days).

## Usage

``` r
mysterycall_prepare_calls(
  data,
  col_calldate = "calldate1",
  col_contacted1 = "contacted1",
  col_contacted2 = "contacted2",
  col_appdate = "appdate",
  col_exclusions = "exclusions",
  col_initials = "initials",
  logistic_include_codes = c(0L, 7L, 9L, 10L),
  na_exclusions = c("warn", "drop", "include"),
  caller_col_out = "caller",
  appt_offered_col = "appt_offered",
  calendar_days_col = "calendar_days",
  business_days_col = "business_days_until_appointment"
)
```

## Arguments

- data:

  A data frame. The raw REDCap export.

- col_calldate:

  Character scalar. Column containing the date of the first call.
  Default `"calldate1"`.

- col_contacted1:

  Character scalar. Binary column: office reached on first call (1 =
  yes, 0 = no). Default `"contacted1"`.

- col_contacted2:

  Character scalar. Binary column: office reached on second call (1 =
  yes, 0 = no, 99 = N/A). Default `"contacted2"`.

- col_appdate:

  Character scalar. Appointment date column. Default `"appdate"`.

- col_exclusions:

  Character scalar. Integer exclusion-code column. Default
  `"exclusions"`.

- col_initials:

  Character scalar. Caller-identity column. Default `"initials"`.

- logistic_include_codes:

  Integer vector. Exclusion codes to include in the **logistic** dataset
  (appointment-offered model). Code 0 is always included. Codes 7, 9,
  and 10 represent "office reached but appointment refused/blocked" and
  default to inclusion (outcome = 0). Default `c(0L, 7L, 9L, 10L)`.

- na_exclusions:

  Character. How to handle `NA` exclusion codes. `"warn"` (default)
  keeps them but issues a warning and adds a flag column. `"drop"`
  removes them. `"include"` silently keeps them.

- caller_col_out:

  Character scalar. Name of the standardized caller column in the
  output. Default `"caller"`.

- appt_offered_col:

  Character scalar. Name of the binary outcome column added to
  `$logistic_data`. Default `"appt_offered"`.

- calendar_days_col:

  Character scalar. Name of the calendar-days column added to
  `$waittime_data` (kept for calendar-vs-business sensitivity). Default
  `"calendar_days"`.

- business_days_col:

  Character scalar. Name of the **canonical** business-days outcome
  column added to `$waittime_data`, computed with
  [`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md)
  (same-day = 0, US federal holidays excluded). This is the primary wait
  outcome the modelling functions default to. Default
  `"business_days_until_appointment"`.

## Value

A list of class `mysterycall_prepared` with elements:

- `logistic_data`:

  Data frame ready for
  [`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md).
  Adds columns: `caller` (title-cased), `appt_offered` (0/1), `reached`
  (logical), `exclusion_na` (logical flag).

- `waittime_data`:

  Subset of `logistic_data` with `appdate` present. Adds
  `business_days_until_appointment` (canonical outcome, business days,
  same-day = 0) and `calendar_days` (secondary, raw days from call to
  appt).

- `waterfall`:

  Data frame: one row per filter step showing `step`, `n_remaining`,
  `n_dropped`, and `reason`.

- `exclusion_summary`:

  Data frame: counts by exclusion code with labels.

- `caller_summary`:

  Data frame: standardized caller names and call counts.

- `na_exclusion_records`:

  Data frame: rows where `exclusions` is `NA`, for manual review. `NULL`
  when none.

## Details

**Two inclusion sets are created (see Value):**

- `$logistic_data`:

  All calls where the office was *reached* - whether or not an
  appointment was offered. Use with
  [`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md).
  Exclusion codes 7, 9, and 10 are included as "appointment not offered"
  (outcome = 0).

- `$waittime_data`:

  Subset of `$logistic_data` where an appointment date was recorded. Use
  with
  [`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
  [`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
  or
  [`mysterycall_auto_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_auto_model.md).

**Standard REDCap column names assumed** (override via `col_*`
arguments):

- `calldate1` - date of first call attempt

- `contacted1` - 1 = office reached, 0 = not reached (first call)

- `contacted2` - 1 = reached on second attempt, 0 = not, 99 = N/A

- `appdate` - date of appointment offered

- `exclusions` - integer exclusion code (0 = included)

- `initials` - caller identity (standardized to title case)

- `medicaid_status` - 1=accepts, 2=refuses, 3=BCBS call, 4=unknown

## See also

[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
[`mysterycall_auto_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_auto_model.md)

Other data-preparation:
[`mysterycall_exclusion_crosswalk()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_crosswalk.md),
[`mysterycall_reconcile_inclusion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_inclusion.md),
[`print.mysterycall_prepared()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_prepared.md),
[`print.mysterycall_reconciliation()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_reconciliation.md)

## Examples

``` r
df <- data.frame(
  calldate1   = c("2024-01-10", "2024-01-11", "2024-01-12", NA, "2024-01-14"),
  contacted1  = c(1, 1, 0, 1, 1),
  contacted2  = c(99, 99, 1, 99, 99),
  appdate     = c("2024-02-01", "", "2024-02-05", "2024-02-03", "2024-02-10"),
  exclusions  = c(0, 9, 0, 0, 7),
  initials    = c("lizeth", "MERILYN", "Lizeth", "jessica", "merilyn"),
  stringsAsFactors = FALSE
)
result <- mysterycall_prepare_calls(df)
print(result)
#> === Mystery-Caller Data Preparation ===
#> 
#> -- Filtering Waterfall --
#>  step n_remaining n_dropped
#>     1           5         0
#>     2           4         1
#>     3           4         0
#>     4           2         2
#>                                                  reason
#>                                       Raw REDCap export
#>                     calldate1 present (call was placed)
#>        Logistic set: reached + exclusions in {0,7,9,10}
#>  Wait-time set: exclusion==0 + appointment date present
#> 
#> Logistic dataset (appt offered):  n = 4
#>   Appointment offered: 3 (75.0%)   Not offered: 1 (25.0%)
#> 
#> Wait-time dataset (appt date present): n = 2
#>   Calendar days: median=23  mean=23.0  range=22-24
#> 
#> -- Exclusion Code Summary --
#>  Code Freq                      Label
#>     0    2                   Included
#>     7    1          Referral required
#>     9    1 Not accepting new patients
#> 
#> -- Caller Summary (standardized) --
#>   Caller Freq
#>   Lizeth    2
#>  Merilyn    2
```
