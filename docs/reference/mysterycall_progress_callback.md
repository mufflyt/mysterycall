# Create a simple progress callback for batch operations

Create a simple progress callback for batch operations

## Usage

``` r
mysterycall_progress_callback(total, label = "Processing")
```

## Arguments

- total:

  Total number of items

- label:

  Label for progress messages

## Value

A function that updates progress

## See also

Other logging:
[`mysterycall_format_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_duration.md),
[`mysterycall_log_cache_hit()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_cache_hit.md),
[`mysterycall_log_error()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_error.md),
[`mysterycall_log_info()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_info.md),
[`mysterycall_log_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_progress.md),
[`mysterycall_log_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_save.md),
[`mysterycall_log_step()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_step.md),
[`mysterycall_log_step_complete()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_step_complete.md),
[`mysterycall_log_success()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_success.md),
[`mysterycall_log_to_file()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_to_file.md),
[`mysterycall_log_warning()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_warning.md),
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
# \donttest{
progress <- mysterycall:::mysterycall_progress_callback(100, "Processing")
for (i in 1:100) {
  # do work
  progress(i)
}
#>   ▸ Progress: 10/100 (10.0%) - Processing
#>   ▸ Progress: 20/100 (20.0%) - Processing
#>   ▸ Progress: 31/100 (31.0%) - Processing
#>   ▸ Progress: 42/100 (42.0%) - Processing
#>   ▸ Progress: 52/100 (52.0%) - Processing
#>   ▸ Progress: 63/100 (63.0%) - Processing
#>   ▸ Progress: 74/100 (74.0%) - Processing
#>   ▸ Progress: 85/100 (85.0%) - Processing
#>   ▸ Progress: 96/100 (96.0%) - Processing
#>   ▸ Progress: 100/100 (100.0%) - Processing
# }
```
