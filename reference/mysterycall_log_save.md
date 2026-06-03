# Log file save

Log file save

## Usage

``` r
mysterycall_log_save(path, n_rows = NULL)
```

## Arguments

- path:

  File path

- n_rows:

  Number of rows (optional)

## Value

`invisible(NULL)`.

## See also

Other logging:
[`mysterycall_format_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_duration.md),
[`mysterycall_log_cache_hit()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_cache_hit.md),
[`mysterycall_log_error()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_error.md),
[`mysterycall_log_info()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_info.md),
[`mysterycall_log_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_progress.md),
[`mysterycall_log_step()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_step.md),
[`mysterycall_log_step_complete()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_step_complete.md),
[`mysterycall_log_success()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_success.md),
[`mysterycall_log_to_file()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_to_file.md),
[`mysterycall_log_warning()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_warning.md),
[`mysterycall_progress_callback()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_callback.md),
[`mysterycall_progress_finish()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_finish.md),
[`mysterycall_progress_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_start.md),
[`mysterycall_progress_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_summary.md),
[`mysterycall_progress_tracker()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_tracker.md),
[`mysterycall_tracker_fail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tracker_fail.md),
[`mysterycall_tracker_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tracker_update.md),
[`mysterycall_use_quiet_logging()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_use_quiet_logging.md),
[`mysterycall_workflow_end()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_workflow_end.md),
[`mysterycall_workflow_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_workflow_start.md)

## Examples

``` r
mysterycall:::mysterycall_log_save(tempfile(fileext = ".csv"), n_rows = 42)
#>   💾 Saved to: /tmp/Rtmpazbf8J/file23c43d555be.csv (42 rows)
```
