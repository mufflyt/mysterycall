# Print a mysterycall_snapshot object

Shows the output file path and the first 20 lines of the snapshot.

## Usage

``` r
# S3 method for class 'mysterycall_snapshot'
print(x, n = 20L, ...)
```

## Arguments

- x:

  A `mysterycall_snapshot` object returned by
  [`mysterycall_session_snapshot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_session_snapshot.md).

- n:

  Integer scalar. Number of lines to preview. Default `20L`.

- ...:

  Currently unused; present for S3 method compatibility.

## Value

`invisible(x)`.

## See also

Other reporting:
[`mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_abstract_numbers.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
[`mysterycall_geographic_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geographic_map.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
[`mysterycall_session_snapshot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_session_snapshot.md),
[`mysterycall_supplemental_tables()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_supplemental_tables.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`print.mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_abstract_numbers.md),
[`print.mysterycall_irr_days()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_irr_days.md)

## Examples

``` r
snap <- tempfile(fileext = ".txt")
out  <- mysterycall_session_snapshot(file = snap, quiet = TRUE)
print(out)
#> Session snapshot: /tmp/Rtmp1fWsfO/file22e05f1d87be.txt
#> ============================================================
#> === REPRODUCIBILITY SNAPSHOT ===
#> ============================================================
#> Date/Time: 2026-06-28 15:57:02 UTC
#> R Version: R version 4.6.1 (2026-06-24)
#> Platform:  x86_64-pc-linux-gnu
#> 
#> === SEEDS ===
#> (none supplied)
#> 
#> === LOADED PACKAGES ===
#> ggplot2                        4.0.3
#> mysterycall                    1.6.0
#> 
#> === FULL SESSION INFO ===
#> R version 4.6.1 (2026-06-24)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.4 LTS
#> 
#> Matrix products: default
#> ... (81 more lines not shown)
```
