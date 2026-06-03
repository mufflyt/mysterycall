# Safe semi join with keep-rate enforcement

Wraps
[`dplyr::semi_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html)
(filter left to matching rows, no right columns added) with key
validation, type harmonization, and a minimum keep-rate threshold.

## Usage

``` r
mysterycall_safe_semi_join(
  left,
  right,
  by,
  label_left = "left",
  label_right = "right",
  min_coverage = NULL,
  write_report = FALSE,
  report_prefix = "join_semi"
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

- min_coverage:

  Numeric in `[0, 1]`. Default `0.50`.

- write_report:

  Logical. Write a one-row CSV audit record. Default `FALSE`.

- report_prefix:

  Character scalar. Filename prefix for the audit CSV.

## Value

A data frame: the filtered subset of `left`.

## Details

Default `min_coverage = 0.50` intentionally differs from
`safe_left_join` (0.98) because semi joins are often used for
intentional subsetting.

## See also

[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md),
[`mysterycall_safe_inner_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_inner_join.md),
[`mysterycall_safe_anti_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_anti_join.md),
[`mysterycall_assert_unique_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assert_unique_keys.md)

Other safe-joins:
[`mysterycall_assert_unique_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assert_unique_keys.md),
[`mysterycall_safe_anti_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_anti_join.md),
[`mysterycall_safe_inner_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_inner_join.md),
[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md)

## Examples

``` r
physicians    <- data.frame(npi = c("1","2","3","4"), stringsAsFactors = FALSE)
has_isochrone <- data.frame(npi = c("1","3"),         stringsAsFactors = FALSE)

result <- mysterycall_safe_semi_join(
  left         = physicians,
  right        = has_isochrone,
  by           = "npi",
  min_coverage = 0.25,
  write_report = FALSE
)
#> Semi join: left kept 2/4 (50.0%)
```
