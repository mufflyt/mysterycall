# Ordered Multi-Category Outcome Summary (Access Gradient)

Summarises a categorical outcome across its levels with per-level
counts, proportions, Wilson intervals, and – for an ordered (graded)
outcome such as an access tier – cumulative proportions. Fits the graded
access ladders in the literature (Sharma's "information by phone /
in-person only / must establish care"; a triage disposition; a
staff-role breakdown).

## Usage

``` r
mysterycall_outcome_gradient(
  data,
  var,
  levels = NULL,
  group_var = NULL,
  conf_level = 0.95,
  cumulative = TRUE
)
```

## Arguments

- data:

  A data frame.

- var:

  Character scalar. The categorical outcome column.

- levels:

  Character vector or `NULL`. The level ordering. `NULL` uses the factor
  levels of `var`, or the sorted unique values.

- group_var:

  Character scalar or `NULL`. Optional grouping column.

- conf_level:

  Numeric. Wilson interval confidence level. Default `0.95`.

- cumulative:

  Logical. Add a `cumulative_prop` column following `levels` order
  (meaningful for an ordinal outcome). Default `TRUE`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns (optional `group`), `level`, `n`, `total`, `proportion`,
`ci_lower`, `ci_upper`, and optionally `cumulative_prop`.

## See also

Other call-outcomes:
[`mysterycall_classify_call_outcome()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_call_outcome.md),
[`mysterycall_multiresponse_tabulate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multiresponse_tabulate.md),
[`mysterycall_ordinal_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ordinal_model.md)

## Examples

``` r
df <- data.frame(
  access = c("phone", "phone", "in_person", "must_establish", "phone",
             "in_person", "must_establish", "must_establish")
)
mysterycall_outcome_gradient(
  df, "access", levels = c("phone", "in_person", "must_establish")
)
#> # A tibble: 3 × 7
#>   level              n total proportion ci_lower ci_upper cumulative_prop
#>   <chr>          <int> <int>      <dbl>    <dbl>    <dbl>           <dbl>
#> 1 phone              3     8      0.375    0.137    0.694           0.375
#> 2 in_person          2     8      0.25     0.071    0.591           0.625
#> 3 must_establish     3     8      0.375    0.137    0.694           1    
```
