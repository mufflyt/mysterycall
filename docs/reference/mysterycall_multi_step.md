# Start a step in multi-progress tracker

Advances the multi-progress tracker to the given step and creates an
inner progress bar for that step's items.

## Usage

``` r
mysterycall_multi_step(tracker, step_num, total, detail = NULL)
```

## Arguments

- tracker:

  Multi-progress tracker object from
  [`mysterycall_multi_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_progress.md).

- step_num:

  Step number (1-based).

- total:

  Total number of items to process in this step.

- detail:

  Optional detail message shown beneath the step header.

## Value

`invisible(NULL)`.

## See also

Other progress:
[`mysterycall_multi_complete()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_complete.md),
[`mysterycall_multi_done()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_done.md),
[`mysterycall_multi_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_progress.md),
[`mysterycall_multi_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_update.md),
[`mysterycall_progress_bar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_bar.md),
[`mysterycall_progress_done()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_done.md),
[`mysterycall_progress_fail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_fail.md),
[`mysterycall_progress_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_map.md),
[`mysterycall_progress_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_update.md),
[`mysterycall_spinner_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_spinner_start.md),
[`mysterycall_spinner_stop()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_spinner_stop.md)

## Examples

``` r
tr <- mysterycall:::mysterycall_multi_progress(c("Geocode", "Validate"))
mysterycall:::mysterycall_multi_step(tr, 1, total = 10)
#> 
#> ── Step 1/2: Geocode ──
#> 
#> Starting: Geocode (10 items)
```
