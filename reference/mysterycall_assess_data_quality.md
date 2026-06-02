# Assess data quality

Scores a data frame for completeness and validity on a 0-1 scale,
returning both the overall score and a detailed list of specific issues
that may affect downstream workflow steps. Penalties are applied for
missing values in required columns (\>50% missing = -3 pts, 20-50% = -1
pt), excessive duplicate rows (\>10% = -1 pt), and non-character NPI or
name columns.

## Usage

``` r
mysterycall_assess_data_quality(data, required_columns = c("first", "last"))
```

## Arguments

- data:

  Data frame to assess.

- required_columns:

  Character vector of column names that must be present and sufficiently
  complete. Defaults to `c("first", "last")`.

## Value

A named list with elements `score` (numeric 0-1) and `issues` (list of
issue records with `severity` and `message` fields).

## Scoring method

Quality is scored on a 0-1 scale by subtracting penalties from a maximum
of 10:

- Required column with \> 50\\

- Required column with 20-50\\

- More than 10\\

- Required column is not character or factor type: -0.5 points

Final score = max(0, 1 - penalties / 10).

Worked examples for a 1,000-row physician roster with
`required_columns = c("first", "last")`:

- All names present, \< 10\\

- 30\\

- 60\\

- Both columns \> 50\\

The 0.70 and 0.80 thresholds in
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md)
were chosen to catch severely incomplete data while tolerating modest
missingness in large rosters.

## See also

[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md)
which calls this function;
[`mysterycall_estimate_resources()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_estimate_resources.md)
for runtime/memory projections.

Other utilities: `%>%`,
[`mysterycall_check_api_response()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_api_response.md),
[`mysterycall_check_data_completeness()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_data_completeness.md),
[`mysterycall_check_dependencies()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_dependencies.md),
[`mysterycall_check_no_data_loss()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_data_loss.md),
[`mysterycall_check_no_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_limits.md),
[`mysterycall_download_file()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_download_file.md),
[`mysterycall_estimate_resources()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_estimate_resources.md),
[`mysterycall_export_with_backup()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_with_backup.md),
[`mysterycall_normalize_file_format()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_file_format.md),
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md),
[`mysterycall_quality_tier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_quality_tier.md),
[`mysterycall_require_arrow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_require_arrow.md),
[`mysterycall_resolve_path()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_resolve_path.md),
[`mysterycall_save_quality_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_quality_table.md),
[`mysterycall_scan_for_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scan_for_limits.md),
[`mysterycall_standard_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_labels.md),
[`mysterycall_standard_palette()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_palette.md)

## Examples

``` r
df <- data.frame(first = c("Jane", NA), last = c("Doe", "Smith"))
mysterycall_assess_data_quality(df)
#> $score
#> [1] 0.9
#> 
#> $issues
#> $issues[[1]]
#> $issues[[1]]$severity
#> [1] "warning"
#> 
#> $issues[[1]]$message
#> [1] "Column 'first' has 50.0% missing values"
#> 
#> 
#> 
#> $penalties
#> [1] 1
#> 
```
