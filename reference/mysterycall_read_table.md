# Read a tabular data file (CSV or Parquet)

Transparently reads a dataset from disk using either
[`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html)
or
[`arrow::read_parquet()`](https://arrow.apache.org/docs/r/reference/read_parquet.html)
based on the file extension or the `format` argument. If an `npi` column
is present and numeric, it is automatically coerced to character to
prevent loss of leading zeros or precision.

## Usage

``` r
mysterycall_read_table(path, format = NULL, ...)
```

## Arguments

- path:

  Character scalar. Path to the file.

- format:

  Optional character scalar: `"csv"` or `"parquet"`. If `NULL`, the
  format is inferred from the `path` extension.

- ...:

  Additional arguments passed to the underlying reader.

## Value

A data frame (tibble).

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
[`mysterycall_require_arrow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_require_arrow.md),
[`mysterycall_resolve_path()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_resolve_path.md),
[`mysterycall_save_quality_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_quality_table.md),
[`mysterycall_scan_for_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scan_for_limits.md),
[`mysterycall_standard_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_labels.md),
[`mysterycall_standard_palette()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_palette.md),
[`mysterycall_write_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table.md)

## Examples

``` r
# \donttest{
tmp <- tempfile(fileext = ".csv")
write.csv(mtcars, tmp, row.names = FALSE)
df <- mysterycall_read_table(tmp)
# }
```
