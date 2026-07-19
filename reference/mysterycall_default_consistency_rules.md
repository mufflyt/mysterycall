# Default cross-field consistency rules for a call log

A starter set of study-agnostic rules covering contradictions common to
mystery-caller call logs: an appointment date recorded when the office
was never reached, a practice marked as taking new patients yet with no
appointment recorded, a record marked complete but missing its call
date, a missing caller assignment, and a wait time recorded when no
appointment was offered (the "a wait exists only when offered"
invariant, the companion detector to
[`mysterycall_reconcile_offer_outcome()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_offer_outcome.md)).
Column names are supplied via `cols` so the rules travel across studies;
any rule whose columns are absent from the data silently no-ops.

## Usage

``` r
mysterycall_default_consistency_rules(cols = list(), values = list())
```

## Arguments

- cols:

  Named list mapping roles to column names. Recognized roles:
  `answered`, `appointment_date`, `taking_new`, `complete`, `call_date`,
  `caller`, `offered`, `wait`. Override any you use; unmatched roles
  keep their defaults.

- values:

  Named list of the values that trigger each rule: `answered_no`
  (default `FALSE`), `taking_new_yes` (default `"Yes"`), `complete_yes`
  (default `"Complete"`), `offered_no` (default `c(FALSE, "FALSE")`).

## Value

A list of
[`mysterycall_consistency_rule()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_consistency_rule.md)
objects.

## See also

[`mysterycall_check_consistency()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_consistency.md)

## Examples

``` r
rules <- mysterycall_default_consistency_rules()
length(rules)
#> [1] 5
```
