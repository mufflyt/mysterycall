# Safe anti join with over-exclusion guard

Wraps
[`dplyr::anti_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html)
(return left rows with **no** match in right) with key validation, type
harmonization, and an optional cap on how many rows may be matched away.

## Usage

``` r
mysterycall_safe_anti_join(
  left,
  right,
  by,
  label_left = "left",
  label_right = "right",
  max_matched = NULL,
  write_report = FALSE,
  report_prefix = "join_anti"
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

- label_left, label_right:

  Character scalars used in messages and the audit report.

- max_matched:

  Numeric in `[0, 1]`. Maximum fraction of left rows that may be matched
  (and thus excluded). Default `NULL` -\> reads `JOIN_MAX_MATCHED` env
  var or `1.0`.

- write_report:

  Logical. Write a one-row CSV audit record. Default `FALSE`.

- report_prefix:

  Character scalar. Filename prefix for the audit CSV.

## Value

A data frame: the unmatched subset of `left`.

## Details

`max_matched` is the maximum fraction of left rows that may be excluded.
Default `1.0` (no limit); reads `JOIN_MAX_MATCHED` env var.

## See also

[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md),
[`mysterycall_safe_inner_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_inner_join.md),
[`mysterycall_safe_semi_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_semi_join.md),
[`mysterycall_assert_unique_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assert_unique_keys.md)

Other safe-joins:
[`mysterycall_assert_unique_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assert_unique_keys.md),
[`mysterycall_safe_inner_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_inner_join.md),
[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md),
[`mysterycall_safe_semi_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_semi_join.md)

## Examples

``` r
all_physicians <- data.frame(npi = c("1","2","3","4"), stringsAsFactors = FALSE)
retired        <- data.frame(npi = c("2","4"),         stringsAsFactors = FALSE)

active <- mysterycall_safe_anti_join(
  left         = all_physicians,
  right        = retired,
  by           = "npi",
  label_left   = "all_physicians",
  label_right  = "retired_list",
  max_matched  = 0.60,
  write_report = FALSE
)
#> Anti join: all_physicians kept 2/4 (excluded 50.0%)
```
