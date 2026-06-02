# Create a beautiful progress bar

Creates an animated progress bar with ETA, percentage, and custom
formatting. Uses the cli package for cross-platform compatibility and
beautiful output.

## Usage

``` r
mysterycall_progress_bar(
  name,
  total,
  format = NULL,
  clear = FALSE,
  show_after = 0,
  force = FALSE
)
```

## Arguments

- name:

  Name/description of the operation

- total:

  Total number of items to process

- format:

  Custom format string (uses cli::cli_progress_bar format)

- clear:

  Whether to clear the progress bar when done (default: FALSE)

- show_after:

  Show progress bar after this many seconds (default: 0)

- force:

  Whether to force progress bar even if not in terminal (default: FALSE)

## Value

Progress bar ID (invisible)

## See also

Other progress:
[`mysterycall_multi_complete()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_complete.md),
[`mysterycall_multi_done()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_done.md),
[`mysterycall_multi_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_progress.md),
[`mysterycall_multi_step()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_step.md),
[`mysterycall_multi_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_update.md),
[`mysterycall_progress_done()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_done.md),
[`mysterycall_progress_fail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_fail.md),
[`mysterycall_progress_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_map.md),
[`mysterycall_progress_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_update.md),
[`mysterycall_spinner_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_spinner_start.md),
[`mysterycall_spinner_stop()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_spinner_stop.md)

## Examples

``` r
if (FALSE) { # interactive()
pb_id <- mysterycall_progress_bar("Processing", total = 10)
for (i in 1:10) mysterycall_progress_update(pb_id)
mysterycall_progress_done(pb_id)
}
```
