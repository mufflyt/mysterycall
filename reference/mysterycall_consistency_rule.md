# Define one cross-field consistency rule

A rule pairs a predicate with the metadata needed to triage the rows it
flags. It is the unit consumed by
[`mysterycall_check_consistency()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_consistency.md).

## Usage

``` r
mysterycall_consistency_rule(
  flag,
  description,
  action,
  predicate,
  priority = "MEDIUM"
)
```

## Arguments

- flag:

  Short machine tag for the rule (e.g. `"ANSWER_CONFLICT"`).

- description:

  Human-readable statement of the contradiction.

- action:

  What the study team should do about it.

- predicate:

  A `function(data)` returning a logical vector with one entry per row
  of `data`; `TRUE` marks a row that *violates* the rule. `NA` is
  treated as "not flagged". A predicate that references a column absent
  from the data should return `FALSE` for every row (see
  [`mysterycall_default_consistency_rules()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_default_consistency_rules.md)
  for the pattern) so a rule set can be applied to logs that lack some
  fields.

- priority:

  One of `"CRITICAL"`, `"HIGH"`, `"MEDIUM"`, `"LOW"` (default
  `"MEDIUM"`); controls sort order in the report.

## Value

A list with class `"mysterycall_consistency_rule"`.

## See also

[`mysterycall_check_consistency()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_consistency.md),
[`mysterycall_default_consistency_rules()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_default_consistency_rules.md)

## Examples

``` r
mysterycall_consistency_rule(
  flag = "WAIT_NO_OFFER",
  description = "A wait time is recorded but no appointment was offered",
  action = "Clear wait_days or correct appointment_offered",
  predicate = function(d) !is.na(d$wait_days) & d$offered == FALSE,
  priority = "HIGH"
)
#> $flag
#> [1] "WAIT_NO_OFFER"
#> 
#> $description
#> [1] "A wait time is recorded but no appointment was offered"
#> 
#> $action
#> [1] "Clear wait_days or correct appointment_offered"
#> 
#> $predicate
#> function (d) 
#> !is.na(d$wait_days) & d$offered == FALSE
#> <environment: 0x55dbba2d84a0>
#> 
#> $priority
#> [1] "HIGH"
#> 
#> attr(,"class")
#> [1] "mysterycall_consistency_rule"
```
