# Summarize an access cascade across the call pathway

Mystery-caller and simulated-patient studies capture a sequence of
intermediate access constructs on the way to (or instead of) an
appointment: reaching a live office, whether the practice accepts new
patients, whether it treats the presented complaint, whether an
appointment is offered, and with whom. This function turns an ordered
set of stage definitions into a tidy count / denominator / percent table
with Wilson confidence intervals, and an optional funnel-style figure.
Denominators may be the full analytic sample, a strictly nested previous
stage, another named stage, or a fixed number, so a single call can mix
a nested funnel with "share of offers" sub-breakdowns.

## Usage

``` r
mysterycall_access_cascade(
  data,
  stages,
  conf_level = 0.95,
  plot = FALSE,
  title = NULL,
  subtitle = NULL,
  output_dir = NA,
  filename = NA
)
```

## Arguments

- data:

  A data frame (one row per call / encounter). Filter it to your
  analytic sample *before* calling; `"total"` denominators use
  `nrow(data)`.

- stages:

  A list of stage specifications. Each element is either the output of
  [`mysterycall_cascade_stage()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cascade_stage.md)
  or a plain list with the same fields (`label`, `column`, `success`,
  and optionally `denominator`, `group`). Stages are evaluated in order,
  which is what makes `"previous"` and by-name denominators resolvable.

- conf_level:

  Confidence level for the Wilson interval on each proportion. Default
  `0.95`.

- plot:

  Logical; if `TRUE` (requires ggplot2) attach a horizontal funnel
  figure of every stage to the returned object as `$plot`.

- title, subtitle:

  Optional figure title / subtitle. When `plot = TRUE` and left `NULL`,
  sensible defaults describing the analytic sample are used.

- output_dir, filename:

  Optional. If both are non-`NA`, the table is written to
  `file.path(output_dir, filename)` as CSV.

## Value

An object of class `"mysterycall_access_cascade"`: a list with `table`
(a tibble of `group`, `measure`, `n`, `denominator`, `pct`, `ci_lower`,
`ci_upper`), `n_total` (rows in `data`), and `plot` (a ggplot or
`NULL`). [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
returns the table.

## Examples

``` r
d <- data.frame(
  office_answered      = c(TRUE, TRUE, TRUE, FALSE, TRUE),
  new_patient_status   = c("Accepting", "Accepting", "Not accepting", NA, "Accepting"),
  appointment_offered  = c(TRUE, FALSE, FALSE, FALSE, TRUE)
)
mysterycall_access_cascade(d, list(
  mysterycall_cascade_stage("Reached a live office", "office_answered", TRUE),
  mysterycall_cascade_stage("Accepting new patients", "new_patient_status", "Accepting"),
  mysterycall_cascade_stage("Appointment offered", "appointment_offered", TRUE)
))
#> <mysterycall access cascade: 3 stages, 5 analytic calls>
#> # A tibble: 3 × 6
#>   group          measure                    n denominator pct   ci          
#>   <chr>          <chr>                  <int>       <int> <chr> <chr>       
#> 1 Access cascade Reached a live office      4           5 80.0% [37.6, 96.4]
#> 2 Access cascade Accepting new patients     3           5 60.0% [23.1, 88.2]
#> 3 Access cascade Appointment offered        2           5 40.0% [11.8, 76.9]
```
