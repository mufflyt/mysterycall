# Cumulative appointment-acquisition curve for single-contact designs

Plots (and tabulates) the empirical cumulative proportion of *all* calls
that had secured an appointment by business-day `t`. This is
deliberately **not** a Kaplan-Meier / time-to-event analysis: a
mystery-caller study is a single simulated contact, not longitudinal
follow-up, so there is no censoring and no at-risk set. Calls that never
received an offer are retained in the denominator as never obtaining an
appointment, which is why each curve plateaus at its group's offer rate
rather than approaching 1.

## Usage

``` r
mysterycall_cumulative_access_curve(
  data,
  time_col,
  offered_col,
  group_col = NULL,
  horizon = 90,
  plot = FALSE,
  output_dir = NA,
  filename = NA
)
```

## Arguments

- data:

  A data frame, one row per call.

- time_col:

  Name of the wait-time column (business days to the appointment among
  offered calls; ignored/`NA` for non-offered calls).

- offered_col:

  Name of the binary offered indicator. Values are coerced with
  [`as.logical()`](https://rdrr.io/r/base/logical.html) after mapping
  `1`/`0` and `"TRUE"`/`"FALSE"`; anything that is not truthy counts as
  not offered.

- group_col:

  Optional grouping column; one curve per group. If `NULL`, a single
  overall curve is produced.

- horizon:

  Maximum business day to evaluate (waits are capped here). Default
  `90`.

- plot:

  Logical; if `TRUE` (requires ggplot2) attach a step-curve figure to
  `$plot`.

- output_dir, filename:

  Optional. If both are non-`NA`, the tidy curve table is written to
  `file.path(output_dir, filename)` as CSV.

## Value

An object of class `"mysterycall_cumulative_access_curve"`: a list with
`table` (tidy `group`, `day`, `p`, `n`), `plateau` (each group's final
cumulative proportion = its offer rate), `horizon`, and `plot`.
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the tidy table.

## Details

Prefer this over
[`mysterycall_kaplan_meier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_kaplan_meier.md)
when "wait" is the delay to a one-shot offer: KM right-censors the
non-offered calls at the horizon, which implies continued follow-up the
design does not have and inflates the implied cumulative probability.

## Examples

``` r
set.seed(1)
d <- data.frame(
  wait_days = c(5, 12, NA, 30, 8, NA, 45, 20),
  offered   = c(1, 1, 0, 1, 1, 0, 1, 1),
  group     = rep(c("A", "B"), each = 4)
)
res <- mysterycall_cumulative_access_curve(
  d, "wait_days", "offered", "group", horizon = 60
)
res$plateau
#> # A tibble: 2 × 3
#>   group offer_rate     n
#>   <chr>      <dbl> <int>
#> 1 A           0.75     4
#> 2 B           0.75     4
```
