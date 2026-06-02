# Update progress bar

Increments the progress bar by a specified amount and optionally updates
the status message.

## Usage

``` r
mysterycall_progress_update(pb, amount = 1, status = NULL, set = NULL)
```

## Arguments

- pb:

  Progress bar object from
  [`mysterycall_progress_bar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_bar.md).

- amount:

  Amount to increment (default: 1).

- status:

  Optional status message to display.

- set:

  Set to a specific absolute value instead of incrementing.

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
[`mysterycall_progress_done()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_done.md),
[`mysterycall_progress_fail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_fail.md),
[`mysterycall_progress_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_map.md),
[`mysterycall_spinner_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_spinner_start.md),
[`mysterycall_spinner_stop()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_spinner_stop.md)

## Examples

``` r
pb <- mysterycall:::mysterycall_progress_bar("Processing", total = 10)
#> Starting: Processing (10 items)
for (i in seq_len(10)) mysterycall:::mysterycall_progress_update(pb)
#>   Progress: 1/10 (10%) - ETA: 0.0s
#>   Progress: 2/10 (20%) - ETA: 0.0s
#>   Progress: 3/10 (30%) - ETA: 0.0s
#>   Progress: 4/10 (40%) - ETA: 0.0s
#>   Progress: 5/10 (50%) - ETA: 0.0s
#>   Progress: 6/10 (60%) - ETA: 0.0s
#>   Progress: 7/10 (70%) - ETA: 0.0s
#>   Progress: 8/10 (80%) - ETA: 0.0s
#>   Progress: 9/10 (90%) - ETA: 0.0s
#>   Progress: 10/10 (100%) - ETA: 0.0s
mysterycall:::mysterycall_progress_done(pb)
#>   ✓ Processing complete
```
