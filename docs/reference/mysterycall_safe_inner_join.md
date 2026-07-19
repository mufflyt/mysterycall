# Safe inner join with cardinality checking

Wraps
[`dplyr::inner_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
with key-type harmonization, optional uniqueness assertion on both
tables, coverage enforcement, and an optional CSV audit record.

## Usage

``` r
mysterycall_safe_inner_join(
  left,
  right,
  by,
  expect_unique_both = TRUE,
  label_left = "left",
  label_right = "right",
  min_coverage = NULL,
  max_duplication = NULL,
  suffix = c(".x", ".y"),
  write_report = FALSE,
  report_prefix = "join_inner"
)
```

## Arguments

- left:

  A data frame. All rows are preserved.

- right:

  A data frame. The lookup / enrichment table.

- by:

  Character vector or
  [`dplyr::join_by()`](https://dplyr.tidyverse.org/reference/join_by.html)
  specifying join keys. Required; use named vector for cross-column
  mapping (`c("npi" = "provider_npi")`).

- expect_unique_both:

  Logical. When `TRUE` (default) keys must be unique on **both** sides.

- label_left, label_right:

  Character scalars used in messages and the audit report.

- min_coverage:

  Numeric in `[0, 1]`. Default `0.90`.

- max_duplication:

  Numeric \>= 0. Maximum allowed output/input row ratio. Default `1.02`
  (reads `JOIN_MAX_DUPLICATION` env var).

- suffix:

  Character vector of length 2. Suffixes for conflicting column names.
  Default `c(".x", ".y")`.

- write_report:

  Logical. Write a one-row CSV audit record. Default `FALSE`.

- report_prefix:

  Character scalar. Filename prefix for the audit CSV.

## Value

A data frame: the inner-join result.

## Details

Coverage is measured as `nrow(semi_join(left, right)) / nrow(left)` to
avoid double-counting from many-to-many multiplication.

## See also

[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md),
[`mysterycall_safe_semi_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_semi_join.md),
[`mysterycall_safe_anti_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_anti_join.md),
[`mysterycall_assert_unique_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assert_unique_keys.md)

Other safe-joins:
[`mysterycall_assert_unique_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assert_unique_keys.md),
[`mysterycall_safe_anti_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_anti_join.md),
[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md),
[`mysterycall_safe_semi_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_semi_join.md)

## Examples

``` r
physicians <- data.frame(npi = c("1", "2", "3"), specialty = c("OB", "GYN", "RE"),
                         stringsAsFactors = FALSE)
claims     <- data.frame(npi = c("1", "2"), year = c(2020L, 2020L),
                         stringsAsFactors = FALSE)

result <- mysterycall_safe_inner_join(
  left         = physicians,
  right        = claims,
  by           = "npi",
  label_left   = "physicians",
  label_right  = "claims",
  min_coverage = 0.50,
  write_report = FALSE
)
#> Join coverage: physicians 2/3 matched (66.7%)
```
