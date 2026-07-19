# Complete progress bar

Marks a progress bar as complete with an optional summary message.

## Usage

``` r
mysterycall_progress_done(pb, result = NULL, status = "done")
```

## Arguments

- pb:

  Progress bar object from
  [`mysterycall_progress_bar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_bar.md).

- result:

  Optional result message to display on completion.

- status:

  Final status label (default: `"done"`).

## Value

`invisible(NULL)`.

## See also

Other progress:
[`mysterycall_multi_complete()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_complete.md),
[`mysterycall_multi_done()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_done.md),
[`mysterycall_multi_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_progress.md),
[`mysterycall_multi_step()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_step.md),
[`mysterycall_multi_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_update.md),
[`mysterycall_progress_bar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_bar.md),
[`mysterycall_progress_fail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_fail.md),
[`mysterycall_progress_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_map.md),
[`mysterycall_progress_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_update.md),
[`mysterycall_spinner_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_spinner_start.md),
[`mysterycall_spinner_stop()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_spinner_stop.md)

## Examples

``` r
pb <- mysterycall:::mysterycall_progress_bar("Processing", total = 5)
#> Starting: Processing (5 items)
for (i in seq_len(5)) mysterycall:::mysterycall_progress_update(pb)
#>   Progress: 1/5 (20%) - ETA: 0.0s
#>   Progress: 2/5 (40%) - ETA: 0.0s
#>   Progress: 3/5 (60%) - ETA: 0.0s
#>   Progress: 4/5 (80%) - ETA: 0.0s
#>   Progress: 5/5 (100%) - ETA: 0.0s
mysterycall:::mysterycall_progress_done(pb, result = "5 items processed")
#>   ✓ 5 items processed
```
