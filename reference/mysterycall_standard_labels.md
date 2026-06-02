# Retrieve the standard label dictionary used in `mysterycall`

Retrieve the standard label dictionary used in `mysterycall`

## Usage

``` r
mysterycall_standard_labels()
```

## Value

A named `list` with character scalar elements: `npi`
(`"National Provider Identifier"`), `state` (`"State"`), `city`
(`"City"`), `call_outcome` (`"Call Outcome"`), `quality`
(`"Quality Tier"`), `call_time` (`"Call Duration (minutes)"`),
`hold_time` (`"Hold Duration (minutes)"`), and `eta`
(`"Estimated Completion"`). Use these as axis or column labels in tables
and plots for display consistency across the package.

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
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md),
[`mysterycall_quality_tier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_quality_tier.md),
[`mysterycall_require_arrow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_require_arrow.md),
[`mysterycall_resolve_path()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_resolve_path.md),
[`mysterycall_save_quality_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_quality_table.md),
[`mysterycall_scan_for_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scan_for_limits.md),
[`mysterycall_standard_palette()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_palette.md)

## Examples

``` r
labels <- mysterycall_standard_labels()
labels[["npi"]]
#> [1] "National Provider Identifier"
```
