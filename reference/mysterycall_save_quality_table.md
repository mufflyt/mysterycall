# Save Quality Check Table

This function takes a data frame containing 'npi' and 'name' columns and
creates a quality check table. The table includes the count of
observations for each 'npi' and 'name' combination where the count is
greater than 2. The resulting table is saved as a CSV file.

## Usage

``` r
mysterycall_save_quality_table(
  data,
  filepath,
  output_format = c("csv", "parquet")
)
```

## Arguments

- data:

  A data frame containing the columns 'npi' and 'name'.

- filepath:

  The path where the output file should be saved.

- output_format:

  Character scalar: `"csv"` (default) or `"parquet"`. CSV is written via
  [`readr::write_csv()`](https://readr.tidyverse.org/reference/write_delim.html);
  Parquet requires the `arrow` package and is more efficient for large
  tables. The file extension of `filepath` is ignored; this parameter
  controls what is actually written.

## Value

The filtered data frame (invisibly). A message is emitted indicating
where the file was saved.

## Details

The output table aggregates by `npi` and `name`, keeps combinations with
more than two records, sorts descending by frequency, and writes the
result to the specified format via `mysterycall_write_table()`. This
helper is useful for flagging repeated provider entries that may require
manual review.

## See also

[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md),
[`validate_dataframe()`](https://mufflyt.github.io/mysterycall/reference/validate_dataframe.md),
[`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md)

Other utilities: `%>%`,
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
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md),
[`mysterycall_quality_tier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_quality_tier.md),
[`mysterycall_require_arrow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_require_arrow.md),
[`mysterycall_resolve_path()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_resolve_path.md),
[`mysterycall_scan_for_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scan_for_limits.md),
[`mysterycall_standard_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_labels.md),
[`mysterycall_standard_palette()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_palette.md)

## Examples

``` r
if (FALSE) { # interactive()
mysterycall_save_quality_table(my_data, "qc.csv")
}
```
