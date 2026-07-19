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
[`mysterycall_direction_words`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
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
#> Session snapshot: /var/folders/39/5l91m_5d02l3kl5z8_1s9pmr0000gn/T//RtmpgR4QpJ/file124c1361b13ca.txt
#> ============================================================
#> === REPRODUCIBILITY SNAPSHOT ===
#> ============================================================
#> Date/Time: 2026-07-18 21:49:57 MDT
#> R Version: R version 4.4.2 (2024-10-31)
#> Platform:  x86_64-apple-darwin20
#> 
#> === SEEDS ===
#> (none supplied)
#> 
#> === LOADED PACKAGES ===
#> ggplot2                        4.0.3
#> mysterycall                    1.6.2
#> 
#> === FULL SESSION INFO ===
#> R version 4.4.2 (2024-10-31)
#> Platform: x86_64-apple-darwin20
#> Running under: macOS Ventura 13.7.8
#> 
#> Matrix products: default
#> ... (82 more lines not shown)
```
