# Update current step in multi-progress tracker

Increments the inner progress bar for the current step.

## Usage

``` r
mysterycall_multi_update(tracker, amount = 1, status = NULL)
```

## Arguments

- tracker:

  Multi-progress tracker object from
  [`mysterycall_multi_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_progress.md).

- amount:

  Amount to increment (default: 1).

- status:

  Optional status message to display.

## Value

`invisible(NULL)`.

## See also

Other progress:
[`mysterycall_multi_complete()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_complete.md),
[`mysterycall_multi_done()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_done.md),
[`mysterycall_multi_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_progress.md),
[`mysterycall_multi_step()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_step.md),
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
mysterycall:::mysterycall_multi_step(tr, 1, total = 5)
#> 
#> ── Step 1/2: Geocode ──
#> 
#> Starting: Geocode (5 items)
for (i in seq_len(5)) mysterycall:::mysterycall_multi_update(tr)
#>   Progress: 1/5 (20%) - ETA: 0.0s
#>   Progress: 2/5 (40%) - ETA: 0.0s
#>   Progress: 3/5 (60%) - ETA: 0.0s
#>   Progress: 4/5 (80%) - ETA: 0.0s
#>   Progress: 5/5 (100%) - ETA: 0.0s
```
