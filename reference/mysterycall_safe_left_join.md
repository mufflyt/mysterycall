# Safe left join with coverage validation

Wraps
[`dplyr::left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
with:

- Key-type harmonization (prevents silent 0-match joins after type
  coercion from RDS or Parquet round-trips).

- Right-side uniqueness assertion (blocks accidental many-to-many
  fan-outs).

- Coverage threshold enforcement – stops if fewer than `min_coverage` of
  left rows find a match.

- Optional CSV audit report written to `JOIN_REPORT_DIR` env var or
  `getOption("mysterycall.join_report_dir", tempdir())`.

## Usage

``` r
mysterycall_safe_left_join(
  left,
  right,
  by,
  expect_unique_right = TRUE,
  label_left = "left",
  label_right = "right",
  min_coverage = NULL,
  max_duplication = NULL,
  suffix = c(".x", ".y"),
  write_report = FALSE,
  report_prefix = "join_left"
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

- expect_unique_right:

  Logical. When `TRUE` (default) right-side keys must be unique; stops
  if duplicates are detected.

- label_left, label_right:

  Character scalars used in messages and the audit report.

- min_coverage:

  Numeric in `[0, 1]`. Minimum fraction of left rows that must find a
  match. Default `0.98` (reads `JOIN_MIN_COVERAGE` env var).

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

A data frame containing all rows of `left` joined to matching rows of
`right`. Columns from both tables are included; name conflicts gain the
`suffix` extensions. Stops with an informative error when: `left` or
`right` is not a data frame; `by` columns are absent; coverage falls
below `min_coverage`; or output rows exceed `max_duplication` times
input rows. When `write_report = TRUE`, a one-row CSV audit record is
written to the working directory using `report_prefix` as the filename
stem.

## Details

Coverage defaults and env-var overrides:

- `min_coverage` default `0.98`; override with `JOIN_MIN_COVERAGE`.

- `max_duplication` default `1.02`; override with
  `JOIN_MAX_DUPLICATION`.

## See also

[`mysterycall_safe_inner_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_inner_join.md),
[`mysterycall_safe_semi_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_semi_join.md),
[`mysterycall_safe_anti_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_anti_join.md),
[`mysterycall_assert_unique_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assert_unique_keys.md)

Other safe-joins:
[`mysterycall_assert_unique_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assert_unique_keys.md),
[`mysterycall_safe_anti_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_anti_join.md),
[`mysterycall_safe_inner_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_inner_join.md),
[`mysterycall_safe_semi_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_semi_join.md)

## Examples

``` r
physicians <- data.frame(
  npi       = c("1", "2", "3"),
  specialty = c("OB", "GYN", "RE"),
  stringsAsFactors = FALSE
)
demographics <- data.frame(
  npi  = c("1", "2"),
  state = c("CO", "TX"),
  stringsAsFactors = FALSE
)

result <- mysterycall_safe_left_join(
  left         = physicians,
  right        = demographics,
  by           = "npi",
  label_left   = "physicians",
  label_right  = "demographics",
  min_coverage = 0.50,
  write_report = FALSE
)
#> Join coverage: physicians 2/3 matched (66.7%)
```
