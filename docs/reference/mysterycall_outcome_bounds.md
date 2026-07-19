# Worst-case / best-case bounds on a proportion under non-response

When some calls are incomplete, the true outcome rate over the full
sampling frame is not point-identified: the missing calls could all have
been successes or all failures. This computes the Manski-style bounds –
the complete-case rate, plus the assumption-free interval you get by
assigning every unobserved call first to failure (worst case) then to
success (best case) – over the full universe. Reviewers of audit studies
routinely ask for these bounds so a headline offer/acceptance rate is
not quietly conditioned on the calls that happened to complete.

## Usage

``` r
mysterycall_outcome_bounds(
  data,
  outcome_col,
  positive_values = TRUE,
  observed = NULL,
  conf_level = 0.95
)
```

## Arguments

- data:

  A data frame spanning the full sampling universe (observed *and*
  unobserved calls).

- outcome_col:

  Name of the binary outcome column.

- positive_values:

  Value(s) of `outcome_col` counted as a success. Default `TRUE` (also
  matched against `"TRUE"`/`1` via `%in%`).

- observed:

  Optional: which rows have a trustworthy observed outcome. Either a
  column name (interpreted so that non-missing / truthy = observed) or a
  logical vector the length of `nrow(data)`. If `NULL` (default), a row
  is observed when `outcome_col` is not `NA`.

- conf_level:

  Confidence level for the Wilson interval on the complete-case rate.
  Default `0.95`.

## Value

An object of class `"mysterycall_outcome_bounds"`: a list with
`n_universe`, `n_observed`, `n_missing`, `n_positive`,
`complete_case_rate` (+ Wilson `cc_ci_lower`/`cc_ci_upper`),
`lower_bound` (all missing are failures), `upper_bound` (all missing are
successes), and `bound_width` (= `n_missing / n_universe`, the ignorance
interval). All rates are proportions in `[0, 1]`.
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns a
one-row tibble.

## Examples

``` r
d <- data.frame(
  offered  = c(TRUE, FALSE, TRUE, NA, NA, TRUE, FALSE, NA),
  complete = c("Y", "Y", "Y", "N", "N", "Y", "Y", "N")
)
mysterycall_outcome_bounds(d, "offered")
#> <mysterycall outcome bounds under non-response>
#>   universe 8 = observed 5 + missing 3; positives 3
#>   complete-case rate: 60.0%  (95% CI 23.1%-88.2%)
#>   bounds over universe: [37.5% (all missing fail), 75.0% (all succeed)]  width 37.5%
```
