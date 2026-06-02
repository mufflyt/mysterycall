# Run comprehensive preflight checks before workflow

Validates all requirements for a successful workflow run including API
keys, data quality, output directories, estimated resources, and
dependencies. Provides a go/no-go decision before starting long-running
operations.

## Usage

``` r
mysterycall_preflight_check(
  input_data,
  output_dir,
  google_maps_api_key = NULL,
  here_api_key = NULL,
  check_apis = TRUE,
  estimate_resources = TRUE,
  prompt_user = interactive(),
  interactive = NULL,
  required_columns = c("first", "last")
)
```

## Arguments

- input_data:

  Either a file path (character scalar) to a CSV/Parquet roster, or an
  already-loaded data frame. If a path, the file must exist and be
  readable; if a data frame it is validated in memory.

- output_dir:

  Character scalar. Destination directory for workflow outputs. Created
  if it does not exist.

- google_maps_api_key:

  Character scalar. Google Maps Platform API key. Required only when
  geocoding is part of the workflow; leave `NULL` to skip geocoding
  validation.

- here_api_key:

  Character scalar. HERE Routing API key. Required only when creating
  drive-time isochrones; leave `NULL` to skip.

- check_apis:

  Logical. If `TRUE` (default), validates each non-`NULL` API key by
  making a minimal test request. Set to `FALSE` to skip live validation
  (e.g., in tests or when offline).

- estimate_resources:

  Logical. If `TRUE` (default), estimates wall-clock time and peak
  memory consumption before the run starts.

- prompt_user:

  Logical. If `TRUE` (default in interactive sessions), prints a
  go/no-go summary and waits for user confirmation. Set to `FALSE` in
  non-interactive scripts.

- interactive:

  Alias for `prompt_user`; if non-`NULL` it takes precedence over
  `prompt_user`. Provided for back-compatibility with scripts that pass
  `interactive = FALSE`.

- required_columns:

  Character vector of column names that must be present in `input_data`.
  Defaults to `c("first", "last")`.

## Value

[`invisible()`](https://rdrr.io/r/base/invisible.html) list with
elements: `passed` (logical), `checks` (list of individual check
results), `errors` (character vector of blocking issues), `warnings`
(character vector of non-blocking issues), `data` (the validated input
data frame), `n_rows` (integer), and `estimates` (list from
[`mysterycall_estimate_resources()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_estimate_resources.md),
or `NULL` when `estimate_resources = FALSE`). Stops with an informative
error if any required check fails.

## Data quality thresholds

Input data is scored from 0-1 by
[`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md).
Scores below **0.70** cause this function to stop with an error; scores
between 0.70 and 0.80 emit a warning. A score below 0.70 typically means
a required name column has more than 50\\
[`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md)
for the full penalty schedule and worked examples.

The thresholds are **not configurable** via parameters. To investigate
quality issues without stopping, call
[`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md)
directly and inspect the returned `$issues` list:

    report <- mysterycall_assess_data_quality(my_data)
    report$score          # numeric 0-1
    report$issues         # list of issue records with $severity and $message

## See also

[`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md)
for the scoring formula and per-issue details;
[`mysterycall_estimate_resources()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_estimate_resources.md)
for runtime and memory projections.

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
# Basic preflight check
mysterycall_preflight_check(
  input_data = "physicians.csv",
  output_dir = "output/",
  google_maps_api_key = Sys.getenv("GOOGLE_API_KEY"),
  here_api_key = Sys.getenv("HERE_API_KEY")
)

# Non-interactive (for scripts)
mysterycall_preflight_check(
  input_data = data,
  output_dir = "output/",
  interactive = FALSE
)
}
```
