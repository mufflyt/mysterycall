# Estimate workflow resources

Projects the approximate runtime and memory requirements for a mystery
caller workflow based on the number of input rows.

## Usage

``` r
mysterycall_estimate_resources(n_rows)
```

## Arguments

- n_rows:

  Integer number of input rows.

## Value

A named `list` with elements:

- `runtime_seconds`:

  `numeric`. Total estimated wall time in seconds.

- `runtime_hours`:

  `numeric`. Total estimated wall time in hours.

- `runtime_str`:

  `character`. Human-readable runtime string (e.g., `"45 minutes"` or
  `"2h 15m"`).

- `memory_mb`:

  `numeric`. Estimated peak memory in megabytes.

- `memory_gb`:

  `numeric`. Estimated peak memory in gigabytes.

- `memory_str`:

  `character`. Human-readable memory string (e.g., `"1.5 GB"` or
  `"700 MB"`).

## Estimation method

Runtime is estimated as `n_rows x 4.5` seconds: 1.5 s/row for NPI
registry lookups, 0.5 s/row for geocoding (assumes a warm Google Maps
cache), and 2.5 s/row for HERE isochrone generation. Memory is
`(n_rows x 2) + 500` MB.

Reference values for the full workflow:

|          |                  |                 |
|----------|------------------|-----------------|
| **Rows** | **Est. runtime** | **Est. memory** |
| 100      | ~8 min           | ~700 MB         |
| 500      | ~38 min          | ~1.5 GB         |
| 1,000    | ~75 min          | ~2.5 GB         |
| 5,000    | ~6.3 h           | ~10.3 GB        |

These constants reflect typical US residential broadband with warm API
caches. Slow networks or cold caches can **triple** the runtime
estimate. Benchmark on 50-100 rows before committing to a large run.

If only a subset of the pipeline is used (e.g., NPI lookup only), the
relevant per-row constant is 1.5 s (NPI), 0.5 s (geocoding), or 2.5 s
(isochrones), not the combined 4.5 s.

## See also

[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md)
which calls this function;
[`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md)
for data completeness scoring.

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
[`mysterycall_export_with_backup()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_with_backup.md),
[`mysterycall_normalize_file_format()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_file_format.md),
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
mysterycall_estimate_resources(500)
#> $runtime_seconds
#> [1] 2250
#> 
#> $runtime_hours
#> [1] 0.625
#> 
#> $runtime_str
#> [1] "38 minutes"
#> 
#> $memory_mb
#> [1] 1500
#> 
#> $memory_gb
#> [1] 1.464844
#> 
#> $memory_str
#> [1] "1.5 GB"
#> 
```
