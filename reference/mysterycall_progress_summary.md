# Return a tibble describing step-by-step progress

Return a tibble describing step-by-step progress

## Usage

``` r
mysterycall_progress_summary(tracker)
```

## Arguments

- tracker:

  Object created by
  [`mysterycall_progress_tracker()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_tracker.md).

## Value

Tibble with per-step status, timestamps, and quality tiers.

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
[`mysterycall_progress_callback()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_callback.md),
[`mysterycall_progress_finish()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_finish.md),
[`mysterycall_progress_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_start.md),
[`mysterycall_progress_tracker()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_tracker.md),
[`mysterycall_tracker_fail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tracker_fail.md),
[`mysterycall_tracker_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tracker_update.md),
[`mysterycall_use_quiet_logging()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_use_quiet_logging.md),
[`mysterycall_workflow_end()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_workflow_end.md),
[`mysterycall_workflow_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_workflow_start.md)

## Examples

``` r
tr <- mysterycall:::mysterycall_progress_tracker(c("Geocode", "Validate"), update_every = 1e9)
mysterycall:::mysterycall_progress_start(tr, "Geocode")
#> [05:36:57] Started Geocode
#> [05:36:57] Progress: 0/2 steps complete (0.0%)
mysterycall:::mysterycall_progress_finish(tr, "Geocode", score = 0.95)
#> [05:36:57] Completed Geocode (high)
#> [05:36:57] Progress: 1/2 steps complete (50.0%)
mysterycall:::mysterycall_progress_summary(tr)
#> # A tibble: 2 × 6
#>   step     status    started_at          finished_at         quality note 
#>   <chr>    <fct>     <dttm>              <dttm>              <chr>   <chr>
#> 1 Geocode  completed 2026-08-17 05:36:57 2026-08-17 05:36:57 high    NA   
#> 2 Validate pending   NA                  NA                  NA      NA   
```
