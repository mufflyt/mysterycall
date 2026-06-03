# Flag locations where generalist physicians are absent

In a mystery-caller scenario-assignment workflow, subspecialists at a
given city/state need at least one generalist at the same location to
pair with (so the generalist can be called with the same insurance in
the same city). This function performs the QC check and returns a
summary of which locations are missing a generalist.

## Usage

``` r
mysterycall_check_generalist_presence(
  data,
  location_cols,
  specialty_col,
  generalist_level
)
```

## Arguments

- data:

  A data frame containing all physicians (generalists and subspecialists
  combined).

- location_cols:

  Character vector of column names that together define a unique
  location (e.g. `c("city", "state_code")`). Values are normalized to
  lower-case before joining.

- specialty_col:

  Character scalar naming the specialty column.

- generalist_level:

  Character scalar. The value in `specialty_col` that identifies a
  generalist (e.g. `"General Otolaryngology"`).

## Value

A data frame with one row per unique location that contains at least one
subspecialist, with columns:

- location:

  Concatenation of location columns, separated by `", "`.

- n_subspecialists:

  Number of subspecialist physicians.

- n_generalists:

  Number of generalist physicians (0 when absent).

- generalist_needed:

  `TRUE` when no generalist is present.

## See also

[`mysterycall_caller_reliability()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caller_reliability.md)
for inter-rater reliability metrics;
[`mysterycall_assign_scenarios()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_scenarios.md)
to pair generalists with subspecialists once locations are validated;
[`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md)
for row-level NPI validation before location assignment.

Other data management:
[`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md),
[`mysterycall_extract_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_zip5.md),
[`mysterycall_luhn_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_luhn_check.md),
[`mysterycall_merge_with_prefix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_merge_with_prefix.md),
[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md),
[`mysterycall_rename_columns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_rename_columns.md),
[`mysterycall_stratified_sample()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_stratified_sample.md)

## Examples

``` r
df <- data.frame(
  city      = c("Denver","Denver","Denver","Austin","Austin"),
  state     = c("CO","CO","CO","TX","TX"),
  specialty = c("General","Neurotology","Pediatric","Neurotology","General"),
  stringsAsFactors = FALSE
)
mysterycall_check_generalist_presence(df, c("city","state"), "specialty",
                                       "General")
#>     location n_subspecialists n_generalists generalist_needed
#> 1 denver, co                2             1             FALSE
#> 2 austin, tx                1             1             FALSE
```
