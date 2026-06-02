# Validate no artificial data limits in workflow

Checks for common anti-patterns that limit data processing. This
function helps enforce the package policy of processing ALL available
data without artificial limits.

## Usage

``` r
mysterycall_check_no_limits(
  data,
  context = "dataset",
  min_expected = NULL,
  max_expected = NULL
)
```

## Arguments

- data:

  Input dataframe to check

- context:

  Description of where data came from, used in warning messages

- min_expected:

  Minimum number of rows expected (optional). If provided and actual
  rows are less, generates a warning.

- max_expected:

  Maximum number of rows expected (optional). If provided and actual
  rows exceed this, generates a warning.

## Value

`invisible(TRUE)` when all checks pass. When a check fails, emits a
[`base::warning()`](https://rdrr.io/r/base/warning.html) describing the
issue and still returns `invisible(TRUE)` so the caller can continue
processing.

## See also

[`mysterycall_check_no_data_loss()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_data_loss.md),
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
[`mysterycall_check_no_data_loss()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_data_loss.md),
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
data <- read_csv("providers.csv")
mysterycall_check_no_limits(data, "provider input")

npi_results <- mysterycall_search_and_process_npi(data)
mysterycall_check_no_limits(npi_results, "NPI search results", min_expected = 100)
}
```
