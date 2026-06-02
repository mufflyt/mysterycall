# Create a progress bar for batch processing

Convenience wrapper for processing items in batches with automatic
progress updates and ETA calculations.

## Usage

``` r
mysterycall_progress_map(
  items,
  fn,
  name = "Processing items",
  batch_size = NULL,
  parallel = FALSE
)
```

## Arguments

- items:

  Vector of items to process

- fn:

  Function to apply to each item

- name:

  Name of operation (default: "Processing items")

- batch_size:

  Show progress every N items (default: 1, or max(1, length(items) /
  100))

- parallel:

  Whether processing is parallel (affects ETA calculation)

## Value

List of results from fn

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
[`mysterycall_progress_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_update.md),
[`mysterycall_spinner_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_spinner_start.md),
[`mysterycall_spinner_stop()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_spinner_stop.md)

## Examples

``` r
if (FALSE) { # interactive()
results <- mysterycall_progress_map(
  items = 1:10,
  fn    = function(x) x^2,
  name  = "Computing squares"
)
}
```
