# Track multi-stage workflow progress

Creates a progress tracker object for recording per-step status,
emitting periodic progress updates, and surfacing quality tiers for
long-running workflows.

## Usage

``` r
mysterycall_progress_tracker(steps, update_every = 300,
  quiet = getOption("mysterycall.quiet", FALSE))
```

## Arguments

- steps:

  Character vector naming each workflow stage.

- update_every:

  Number of seconds between automatic update messages.

- quiet:

  Logical flag that suppresses log output when `TRUE`.

## Value

An object of class `mysterycall_progress_tracker`. Pass it to
[`mysterycall_progress_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_start.md),
[`mysterycall_progress_finish()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_finish.md),
[`mysterycall_tracker_fail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tracker_fail.md),
[`mysterycall_tracker_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tracker_update.md),
and
[`mysterycall_progress_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_summary.md).

## Examples

``` r
tracker <- mysterycall:::mysterycall_progress_tracker(c("Geocode", "Validate"), update_every = 10)
mysterycall:::mysterycall_progress_start(tracker, "Geocode")
#> [22:31:04] Started Geocode
#> [22:31:04] Progress: 0/2 steps complete (0.0%)
mysterycall:::mysterycall_progress_finish(tracker, "Geocode", score = 0.92)
#> [22:31:04] Completed Geocode (high)
#> [22:31:04] Progress: 1/2 steps complete (50.0%)
mysterycall:::mysterycall_progress_summary(tracker)
#> # A tibble: 2 × 6
#>   step     status    started_at          finished_at         quality note 
#>   <chr>    <fct>     <dttm>              <dttm>              <chr>   <chr>
#> 1 Geocode  completed 2026-06-02 22:31:04 2026-06-02 22:31:04 high    NA   
#> 2 Validate pending   NA                  NA                  NA      NA   
```
