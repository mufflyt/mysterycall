# Complete multi-step tracker

Complete multi-step tracker

## Usage

``` r
mysterycall_multi_done(tracker)
```

## Arguments

- tracker:

  Multi-progress tracker object

## Value

`invisible(NULL)`.

## See also

Other progress:
[`mysterycall_multi_complete()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_complete.md),
[`mysterycall_multi_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_progress.md),
[`mysterycall_multi_step()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_step.md),
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
if (FALSE) { # interactive()
tracker <- mysterycall_multi_progress(c("Geocode", "Validate"))
mysterycall:::mysterycall_multi_done(tracker)
}
```
