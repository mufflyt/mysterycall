# Log a step start

Log a step start

## Usage

``` r
mysterycall_log_step(step_name, detail = NULL, n_items = NULL)
```

## Arguments

- step_name:

  Name of the step

- detail:

  Optional additional details

- n_items:

  Number of items to process (for progress tracking)

## Value

`invisible(NULL)`; updates the internal step counter and emits a
formatted step header to the console.

## See also

Other logging:
[`mysterycall_format_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_duration.md),
[`mysterycall_log_cache_hit()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_cache_hit.md),
[`mysterycall_log_error()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_error.md),
[`mysterycall_log_info()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_info.md),
[`mysterycall_log_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_progress.md),
[`mysterycall_log_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_save.md),
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
mysterycall:::mysterycall_workflow_start("Demo", total_steps = 2)
#> ============================================================
#>   Demo
#>   Started: 2026-09-06 14:01:37
#>   Total Steps: 2
#> ============================================================
#> 
mysterycall:::mysterycall_log_step("Step 1: Geocode", n_items = 50)
#> ▶ Step 1/2: Step 1: Geocode
#>   Processing 50 item(s)...
```
