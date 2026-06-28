# Assess completeness for required data columns

Assess completeness for required data columns

## Usage

``` r
mysterycall_check_data_completeness(
  data,
  required = NULL,
  id_cols = NULL,
  thresholds = c(high = 0.9, medium = 0.75)
)
```

## Arguments

- data:

  A data frame to assess.

- required:

  Columns that must be present and non-missing.

- id_cols:

  Optional identifier columns used to compute uniqueness.

- thresholds:

  Named numeric vector with `high` and `medium` breakpoints between 0
  and 1 determining the quality tier.

## Value

A named list with three elements:

- `summary`:

  A
  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  with one row per entry in `required` (plus one uniqueness row when
  `id_cols` is supplied). Columns: `column` (character), `completeness`
  (numeric, proportion 0-1 of non-missing values), `missing` (numeric,
  `1 - completeness`).

- `quality`:

  Character scalar: `"high"`, `"medium"`, or `"low"` based on the mean
  completeness score relative to `thresholds`.

- `score`:

  Numeric scalar. Mean completeness across all `required` columns (and
  the uniqueness row when `id_cols` is supplied).

## See also

Other utilities:
[`.title_case()`](https://mufflyt.github.io/mysterycall/reference/dot-title_case.md),
`%>%()`,
[`format_phone_number()`](https://mufflyt.github.io/mysterycall/reference/format_phone_number.md),
[`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md),
[`mysterycall_check_api_response()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_api_response.md),
[`mysterycall_check_dependencies()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_dependencies.md),
[`mysterycall_check_no_data_loss()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_data_loss.md),
[`mysterycall_check_no_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_limits.md),
[`mysterycall_download_file()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_download_file.md),
[`mysterycall_estimate_resources()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_estimate_resources.md),
[`mysterycall_export_with_backup()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_with_backup.md),
[`mysterycall_normalize_file_format()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_file_format.md),
[`mysterycall_parse_redcap_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_redcap_labels.md),
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md),
[`mysterycall_quality_tier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_quality_tier.md),
[`mysterycall_read_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_table.md),
[`mysterycall_require_arrow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_require_arrow.md),
[`mysterycall_resolve_path()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_resolve_path.md),
[`mysterycall_save_quality_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_quality_table.md),
[`mysterycall_scan_for_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scan_for_limits.md),
[`mysterycall_standard_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_labels.md),
[`mysterycall_standard_palette()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_palette.md),
[`mysterycall_write_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table.md)

## Examples

``` r
df <- tibble::tibble(id = 1:3, value = c(1, NA, 3))
mysterycall_check_data_completeness(df, required = c("id", "value"))
#> $summary
#> # A tibble: 2 × 3
#>   column completeness missing
#>   <chr>         <dbl>   <dbl>
#> 1 id            1       0    
#> 2 value         0.667   0.333
#> 
#> $quality
#> [1] "medium"
#> 
#> $score
#> [1] 0.8333333
#> 
```
