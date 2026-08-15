# Define one stage of an access cascade

Helper that builds a single stage specification for
[`mysterycall_access_cascade()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_access_cascade.md).
A stage is one row of the access cascade: a labelled measure counted
over a column, with a denominator that is either the full analytic
sample, the previous stage, another stage, or a fixed number.

## Usage

``` r
mysterycall_cascade_stage(
  label,
  column,
  success,
  denominator = "total",
  group = NULL
)
```

## Arguments

- label:

  Human-readable measure name shown in the table and figure (e.g.
  `"Practice accepting new patients"`).

- column:

  Name of the column in `data` that carries this measure.

- success:

  The value(s) in `column` that count as a "hit". Matched with `%in%`
  (so `NA` never counts). Alternatively a predicate `function(x)`
  returning a logical vector the length of `x`.

- denominator:

  What the count is a percentage *of*. One of: `"total"` (the number of
  rows in `data`, i.e. the analytic sample; the default), `"previous"`
  (the hit count of the stage defined immediately before this one,
  giving a strict funnel), a single positive number, or a character
  string naming the `label` of an earlier stage (whose hit count becomes
  the denominator – e.g. reporting "share of offers" against an earlier
  "offered" stage).

- group:

  Optional block label used to group related stages in the output table
  (e.g. `"Access cascade"`, `"Reasons not accepting"`). Defaults to
  `"Access cascade"`.

## Value

A list with class `"mysterycall_cascade_stage"`.

## See also

[`mysterycall_access_cascade()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_access_cascade.md)

## Examples

``` r
mysterycall_cascade_stage(
  "New-patient appointment offered", "appointment_offered", success = TRUE
)
#> $label
#> [1] "New-patient appointment offered"
#> 
#> $column
#> [1] "appointment_offered"
#> 
#> $success
#> [1] TRUE
#> 
#> $denominator
#> [1] "total"
#> 
#> $group
#> [1] "Access cascade"
#> 
#> attr(,"class")
#> [1] "mysterycall_cascade_stage"
```
