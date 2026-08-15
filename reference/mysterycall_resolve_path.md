# Resolve project-relative paths from standard aliases

Resolve project-relative paths from standard aliases

## Usage

``` r
mysterycall_resolve_path(
  ...,
  type = NULL,
  base_dir = getOption("mysterycall.base_dir", getwd()),
  create = FALSE
)
```

## Arguments

- ...:

  Additional path components appended to the resolved base.

- type:

  Optional alias describing the base path. Supported values are
  `"data"`, `"raw-data"`, `"tables"`, `"figures"`, `"docs"`, and
  `"cache"`. When `NULL`, `...` are treated as relative to `base_dir`.

- base_dir:

  Base directory to resolve paths from. Defaults to the value stored in
  `getOption("mysterycall.base_dir")` or the current working directory.

- create:

  Logical. When `TRUE`, ensure the resolved parent directory exists.

## Value

A normalized path as a character string.

## See also

Other utilities:
[`.title_case()`](https://mufflyt.github.io/mysterycall/reference/dot-title_case.md),
`%>%`,
[`format_phone_number()`](https://mufflyt.github.io/mysterycall/reference/format_phone_number.md),
[`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md),
[`mysterycall_check_api_response()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_api_response.md),
[`mysterycall_check_data_completeness()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_data_completeness.md),
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
[`mysterycall_reached_declined_reasons()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reached_declined_reasons.md),
[`mysterycall_read_latest()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_latest.md),
[`mysterycall_read_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_table.md),
[`mysterycall_require_arrow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_require_arrow.md),
[`mysterycall_save_quality_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_quality_table.md),
[`mysterycall_scan_for_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scan_for_limits.md),
[`mysterycall_standard_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_labels.md),
[`mysterycall_standard_palette()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_palette.md),
[`mysterycall_write_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table.md)

## Examples

``` r
mysterycall:::mysterycall_resolve_path("output.csv", type = "tables", create = FALSE)
#> [1] "/home/runner/work/mysterycall/mysterycall/docs/reference/tables/output.csv"
```
