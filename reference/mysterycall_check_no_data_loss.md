# Validate no data loss between pipeline steps

Ensures row counts don't unexpectedly decrease between operations. Use
at key checkpoints in data pipelines to catch silent filtering or joins
that lose data.

## Usage

``` r
mysterycall_check_no_data_loss(
  before,
  after,
  operation = "operation",
  expected_change = 0,
  tolerance = 0
)
```

## Arguments

- before:

  Row count before operation (or data frame)

- after:

  Row count after operation (or data frame)

- operation:

  Description of operation for error messages

- expected_change:

  Expected change in rows. Defaults to 0 (no change). Use positive for
  operations that add rows (e.g., joins), negative for operations that
  should remove rows (e.g., deduplication).

- tolerance:

  Maximum acceptable unexpected loss. Defaults to 0.

## Value

Invisible TRUE if within expected change +/- tolerance

## See also

[`mysterycall_check_no_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_limits.md),
[`mysterycall_check_api_response()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_api_response.md),
[`mysterycall_scan_for_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scan_for_limits.md)
for related sanity-check utilities.

Other utilities:
[`.title_case()`](https://mufflyt.github.io/mysterycall/reference/dot-title_case.md),
`%>%`,
[`format_phone_number()`](https://mufflyt.github.io/mysterycall/reference/format_phone_number.md),
[`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md),
[`mysterycall_check_api_response()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_api_response.md),
[`mysterycall_check_data_completeness()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_data_completeness.md),
[`mysterycall_check_dependencies()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_dependencies.md),
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
if (FALSE) { # interactive()
# Expect no data loss in cleaning
before <- nrow(raw_data)
clean_data <- mysterycall_clean_phase1(raw_data)
mysterycall_check_no_data_loss(before, clean_data, "Phase 1 cleaning")

# Expect deduplication to remove ~10 rows, allow +/-5
before <- nrow(data)
dedup_data <- deduplicate(data)
mysterycall_check_no_data_loss(before, dedup_data, "Deduplication",
                        expected_change = -10, tolerance = 5)
}
```
