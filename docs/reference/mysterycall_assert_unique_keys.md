# Assert that join key columns are unique

Checks that the specified key columns form a unique key in `.data`. When
duplicates are found, either errors with sample duplicate values or
silently deduplicates (keeping the first row per key), depending on
`dedupe`.

## Usage

``` r
mysterycall_assert_unique_keys(
  .data,
  key_cols,
  label = "table",
  dedupe = FALSE
)
```

## Arguments

- .data:

  A data frame to check.

- key_cols:

  Character vector of column names that together form the key.

- label:

  Character scalar used in error/message text. Default `"table"`.

- dedupe:

  Logical. When `TRUE` duplicates are silently removed (first row per
  key is kept) and the deduplicated data frame is returned invisibly.
  When `FALSE` (default) any duplicates raise an error with sample
  duplicate values to help locate the problem.

## Value

`.data` invisibly (possibly deduplicated). Errors when duplicates exist
and `dedupe = FALSE`.

## See also

Other safe-joins:
[`mysterycall_safe_anti_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_anti_join.md),
[`mysterycall_safe_inner_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_inner_join.md),
[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md),
[`mysterycall_safe_semi_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_semi_join.md)

## Examples

``` r
df <- data.frame(npi = c("A", "B", "A"), value = 1:3)

# Deduplicate silently
clean <- mysterycall_assert_unique_keys(df, "npi", dedupe = TRUE)
#> assert_unique_keys: removed 1 duplicate row(s) from table
nrow(clean)  # 2
#> [1] 2
```
