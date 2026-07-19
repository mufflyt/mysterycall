# Tabulate a Multi-Response ("Check-All-That-Apply") Call Outcome

Summarises an outcome where each call may name several options at once –
for example the set of pain-management options a clinic offers (Sharma
2025) or the alternatives a pharmacy suggests when a product is
unavailable (Wilkinson 2018). Reports per-option prevalence with Wilson
intervals, an option co-occurrence matrix, and options-per-call
summaries. Denominators use only *responding* calls; a call that
responded but named nothing counts toward the denominator with zero
options.

## Usage

``` r
mysterycall_multiresponse_tabulate(
  data,
  var,
  group_var = NULL,
  sep = ";",
  conf_level = 0.95,
  sort = TRUE
)
```

## Arguments

- data:

  A data frame.

- var:

  Character scalar. The multi-response column: either a list-column of
  character vectors, or a delimited string (see `sep`). `NA` marks a
  non-responding call (excluded from denominators); an empty string is a
  responding call that named no options.

- group_var:

  Character scalar or `NULL`. Optional grouping column; when supplied,
  per-option prevalence is also computed within each group.

- sep:

  Character scalar. Delimiter for string-valued option columns. Default
  `";"`.

- conf_level:

  Numeric. Confidence level for Wilson intervals. Default `0.95`.

- sort:

  Logical. Sort options by descending prevalence. Default `TRUE`.

## Value

A `mysterycall_multiresponse` object: a list with `prevalence` (a
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)),
`cooccurrence` (an integer matrix; diagonal = option counts,
off-diagonal = joint counts), `summary` (n_calls, n_responding,
mean_options_per_call, pct_naming_any), `by_group` (tibble or `NULL`),
and `settings`.

## See also

Other call-outcomes:
[`mysterycall_classify_call_outcome()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_call_outcome.md),
[`mysterycall_ordinal_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ordinal_model.md),
[`mysterycall_outcome_gradient()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_outcome_gradient.md)

## Examples

``` r
calls <- data.frame(
  options = c("ibuprofen;lidocaine", "ibuprofen", "", "misoprostol;ibuprofen"),
  region  = c("W", "W", "E", "E"),
  stringsAsFactors = FALSE
)
res <- mysterycall_multiresponse_tabulate(calls, "options", group_var = "region")
res$prevalence
#> # A tibble: 3 × 6
#>   option          n total prevalence ci_lower ci_upper
#>   <chr>       <int> <int>      <dbl>    <dbl>    <dbl>
#> 1 ibuprofen       3     4       0.75    0.301    0.954
#> 2 lidocaine       1     4       0.25    0.046    0.699
#> 3 misoprostol     1     4       0.25    0.046    0.699
```
