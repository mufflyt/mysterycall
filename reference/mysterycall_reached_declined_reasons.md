# Canonical "reached but declined" call-outcome labels

A mystery call is *reached* when the office was actually connected to,
even if no appointment was offered. Three outcomes are
reached-but-declined: the office is not accepting new patients, a
referral is required before scheduling, or the caller was left on hold
for more than five minutes. These are genuine connections that did not
yield an appointment, so they belong in an acceptance-rate
**denominator** (the office was reached and said no) even though they
are not in the numerator.

## Usage

``` r
mysterycall_reached_declined_reasons()
```

## Value

A character vector of the three reached-but-declined label strings.

## Details

This function returns that canonical vocabulary so
[`mysterycall_acceptance_rate_calc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate_calc.md)
and
[`mysterycall_insurance_acceptance_rates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_acceptance_rates.md)
keep reached-but-declined offices in the denominator, consistent with
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
which also classifies these three as reached. The strings match
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md)'s
default `exclusion_categories` for the `not_accepting`,
`referral_required`, and `on_hold` groups.

## See also

[`mysterycall_acceptance_rate_calc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate_calc.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md)

Other utilities:
[`.title_case()`](https://mufflyt.github.io/mysterycall/reference/dot-title_case.md),
`%>%()`,
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
[`mysterycall_read_latest()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_latest.md),
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
mysterycall_reached_declined_reasons()
#> [1] "Not accepting new patients"                               
#> [2] "Physician referral required before scheduling appointment"
#> [3] "Greater than 5 minutes on hold"                           
```
