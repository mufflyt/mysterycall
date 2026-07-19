# Flag call dates that look like fat-finger entry errors

In mystery-caller studies all calls in a wave are typically placed on
the same day (or within a narrow window). A single row with a date 30
days outside the consensus is almost always a data-entry error - e.g.,
"June 17" mis-keyed as "July 17". This function identifies those
outliers.

## Usage

``` r
mysterycall_flag_date_outliers(
  data,
  date_col,
  group_col = NULL,
  tolerance_days = 7L,
  min_group_size = 3L,
  flag_col = "date_flag",
  expected_col = "expected_date"
)
```

## Arguments

- data:

  A data frame.

- date_col:

  Character scalar. Name of the Date (or coercible-to-Date) column to
  check.

- group_col:

  Character scalar or `NULL`. Optional column that identifies the call
  wave or batch. When supplied, outlier detection is performed
  independently within each group. Default `NULL` (whole data set as one
  group).

- tolerance_days:

  Non-negative integer. Maximum absolute deviation (in calendar days)
  from the group modal date that is still considered acceptable. Default
  `7` (one week). Set to `0` to flag any date that differs from the
  exact mode.

- min_group_size:

  Positive integer. Groups with fewer rows than this are skipped (all
  flagged as `NA`). Useful when a wave genuinely has only 1-2 calls.
  Default `3`.

- flag_col:

  Character scalar. Name of the logical flag column to add. Default
  `"date_flag"`.

- expected_col:

  Character scalar. Name of the column that records the group modal
  date. Default `"expected_date"`.

## Value

`data` with two new columns appended:

- `<flag_col>`:

  Logical. `TRUE` if the row's date is more than `tolerance_days` away
  from the group modal date; `FALSE` otherwise; `NA` if the group was
  too small to evaluate.

- `<expected_col>`:

  Date. The modal date for the row's group (or `NA` for small groups).

## Details

For each group (defined by `group_col`, or the whole data set if
`group_col = NULL`), the *modal date* (most-frequent date) is used as
the expected anchor. Any row whose date differs from that anchor by more
than `tolerance_days` is flagged.

## Interpreting output

    out <- mysterycall_flag_date_outliers(df, "call_date", group_col = "wave")
    out[out$date_flag %in% TRUE, c("wave", "call_date", "expected_date")]

Rows where `date_flag == TRUE` should be reviewed against the original
call logs. Common causes: month transposition (06 vs 07), year rollover
(Dec vs Jan), or a genuine make-up call placed weeks later.

## See also

[`mysterycall_check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_normality.md),
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md)

Other data-quality:
[`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md)

## Examples

``` r
df <- data.frame(
  wave      = c(rep("A", 10), rep("B", 10)),
  call_date = as.Date(c(
    rep("2025-06-17", 9), "2025-07-17",   # wave A: 9 correct, 1 fat-finger
    rep("2025-09-03", 10)                 # wave B: all correct
  )),
  stringsAsFactors = FALSE
)
out <- mysterycall_flag_date_outliers(df, "call_date", group_col = "wave")
#> mysterycall_flag_date_outliers: 1 row(s) flagged as date outliers (>7 days from group modal date); 0 row(s) skipped (group too small). Review `$date_flag == TRUE`.
out[, c("wave", "call_date", "expected_date", "date_flag")]
#>    wave  call_date expected_date date_flag
#> 1     A 2025-06-17    2025-06-17     FALSE
#> 2     A 2025-06-17    2025-06-17     FALSE
#> 3     A 2025-06-17    2025-06-17     FALSE
#> 4     A 2025-06-17    2025-06-17     FALSE
#> 5     A 2025-06-17    2025-06-17     FALSE
#> 6     A 2025-06-17    2025-06-17     FALSE
#> 7     A 2025-06-17    2025-06-17     FALSE
#> 8     A 2025-06-17    2025-06-17     FALSE
#> 9     A 2025-06-17    2025-06-17     FALSE
#> 10    A 2025-07-17    2025-06-17      TRUE
#> 11    B 2025-09-03    2025-09-03     FALSE
#> 12    B 2025-09-03    2025-09-03     FALSE
#> 13    B 2025-09-03    2025-09-03     FALSE
#> 14    B 2025-09-03    2025-09-03     FALSE
#> 15    B 2025-09-03    2025-09-03     FALSE
#> 16    B 2025-09-03    2025-09-03     FALSE
#> 17    B 2025-09-03    2025-09-03     FALSE
#> 18    B 2025-09-03    2025-09-03     FALSE
#> 19    B 2025-09-03    2025-09-03     FALSE
#> 20    B 2025-09-03    2025-09-03     FALSE
```
