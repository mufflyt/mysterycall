# Apply a battery of consistency rules to a call log

Runs a list of cross-field rules over a call log and returns a single,
priority-sorted worklist of every row that violates a rule – the general
form of the one-off `mysterycall_flag_*` checks. Each flagged row
appears once per rule it trips, tagged with the rule's flag, priority,
description, and recommended action, so the output can drive a
data-cleaning pass or a correction report.

## Usage

``` r
mysterycall_check_consistency(
  data,
  rules = mysterycall_default_consistency_rules(),
  id_col = NULL,
  keep_cols = NULL,
  output_dir = NA,
  filename = NA
)
```

## Arguments

- data:

  A data frame (one row per call).

- rules:

  A list of
  [`mysterycall_consistency_rule()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_consistency_rule.md)
  objects. Defaults to
  [`mysterycall_default_consistency_rules()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_default_consistency_rules.md).

- id_col:

  Optional identifier column carried into the report so flagged rows can
  be traced back to the source record.

- keep_cols:

  Optional character vector of extra columns to include in the report
  for context.

- output_dir, filename:

  Optional. If both are non-`NA`, the worklist is written to
  `file.path(output_dir, filename)` as CSV.

## Value

An object of class `"mysterycall_consistency_report"`: a list with
`report` (a tibble of `row`, optional id/keep columns, `flag`,
`priority`, `description`, `action`, sorted by priority then row),
`summary` (per-flag counts), and `n_rules`.
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the report.

## Examples

``` r
d <- data.frame(
  record_id           = 1:3,
  office_answered     = c(FALSE, TRUE, TRUE),
  appointment_date    = c("2026-02-01", NA, "2026-03-01"),
  taking_new_patients = c("Yes", "Yes", "Yes"),
  complete            = c("Complete", "Complete", "Complete"),
  call_date           = c("2026-01-01", "2026-01-02", NA),
  caller              = c("AB", NA, "CD")
)
mysterycall_check_consistency(d, id_col = "record_id")
#> <mysterycall consistency report: 4 rows flagged by 4 of 5 rules>
#> 
#> By priority / flag:
#> # A tibble: 4 × 3
#>   priority flag                   n
#>   <chr>    <chr>              <int>
#> 1 HIGH     ANSWER_CONFLICT        1
#> 2 HIGH     MISSING_APPT_DATE      1
#> 3 HIGH     MISSING_CALL_DATE      1
#> 4 MEDIUM   NO_CALLER_ASSIGNED     1
#> 
#> # A tibble: 4 × 6
#>     row record_id flag               priority description                 action
#>   <int>     <int> <chr>              <fct>    <chr>                       <chr> 
#> 1     1         1 ANSWER_CONFLICT    HIGH     Office not answered but an… Clari…
#> 2     2         2 MISSING_APPT_DATE  HIGH     Practice taking new patien… Back-…
#> 3     3         3 MISSING_CALL_DATE  HIGH     Record marked complete but… Calle…
#> 4     2         2 NO_CALLER_ASSIGNED MEDIUM   No caller assigned to this… Assig…
```
