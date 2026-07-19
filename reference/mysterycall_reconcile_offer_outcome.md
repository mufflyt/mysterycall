# Reconcile a binary "offered" flag against a granular outcome field

Call logs often record the same appointment fact twice: a coarse binary
"appointment offered" flag and a richer categorical disposition (e.g.
`"With sampled physician"`, `"No appointment offered"`). These drift
apart during data entry. This function finds — and optionally fixes —
the two kinds of contradiction:

## Usage

``` r
mysterycall_reconcile_offer_outcome(
  data,
  flag_col,
  outcome_col,
  offered_values,
  not_offered_values,
  dependent_cols = character(0),
  action = c("flag", "fix"),
  true_value = c(TRUE, "TRUE"),
  false_value = c(FALSE, "FALSE"),
  clear_value = NA,
  id_col = NULL
)
```

## Arguments

- data:

  A data frame with one row per call.

- flag_col:

  Name of the binary offered flag column.

- outcome_col:

  Name of the granular disposition column.

- offered_values:

  Values of `outcome_col` that imply an appointment **was** offered.

- not_offered_values:

  Values of `outcome_col` that imply **no** appointment was offered.

- dependent_cols:

  Character vector of columns to blank out when a row is flipped to "not
  offered" (e.g. `c("wait_days_business", "appointment_date")`). Default
  none.

- action:

  `"flag"` (default) to detect and report discordance without changing
  `data`, or `"fix"` to apply the corrections.

- true_value, false_value:

  The value(s) that represent offered / not offered in `flag_col`.
  Matching uses `%in%`, so pass every spelling present (defaults cover
  logical and character `TRUE`/`FALSE`). When `action = "fix"` the first
  element of each is written back, coerced to the column's type.

- clear_value:

  Value written into `dependent_cols` on a not-offered flip. Defaults to
  `NA`; use `""` for character columns you export with `na = ""`.

- id_col:

  Optional identifier column included in the discordance report.

## Value

An object of class `"mysterycall_offer_reconciliation"`: a list with
`data` (unchanged when `action = "flag"`, corrected when `"fix"`),
`discordant` (a tibble: `row`, optional id, `flag`, `outcome`,
`direction`, `suggested`), and `n_understated` / `n_overstated` counts.
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the discordance report.

## Details

- **flag understates** the outcome: the disposition names an appointment
  that was offered, but the flag says it was not. The flag is set to
  "offered".

- **flag overstates** the outcome: the flag says an appointment was
  offered, but the disposition says none was. The flag is set to "not
  offered" and any `dependent_cols` (wait time, appointment date) are
  cleared so the "a wait exists only when an appointment was offered"
  invariant holds.

The granular `outcome_col` is treated as authoritative. Rows whose
outcome is in neither `offered_values` nor `not_offered_values` are left
untouched.

## Examples

``` r
d <- data.frame(
  record_id           = 1:4,
  appointment_offered = c(FALSE, TRUE, TRUE, FALSE),
  appointment_outcome = c("With sampled physician", "No appointment offered",
                          "With sampled physician", "No appointment offered"),
  wait_days_business  = c(10, 5, 8, NA)
)
res <- mysterycall_reconcile_offer_outcome(
  d, "appointment_offered", "appointment_outcome",
  offered_values     = "With sampled physician",
  not_offered_values = "No appointment offered",
  dependent_cols     = "wait_days_business",
  action = "fix", id_col = "record_id"
)
as.data.frame(res)
#>   row record_id  flag                outcome        direction   suggested
#> 1   1         1 FALSE With sampled physician flag_understates     offered
#> 2   2         2  TRUE No appointment offered  flag_overstates not_offered
```
